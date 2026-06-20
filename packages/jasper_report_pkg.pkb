-- ══════════════════════════════════════════════════════════════
-- JASPER_REPORT_PKG — Package Body
-- Oracle APEX + JasperReports Integration
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE BODY jasper_report_pkg
AS

    -- ════════════════════════════════════════════════════════
    -- Private: Clean up APEX web service request state
    -- ════════════════════════════════════════════════════════
    PROCEDURE cleanup_request
    IS
    BEGIN
        APEX_WEB_SERVICE.CLEAR_REQUEST_COOKIES;
        APEX_WEB_SERVICE.CLEAR_REQUEST_HEADERS;
    END cleanup_request;

    -- ════════════════════════════════════════════════════════
    -- Private: Normalize report path (ensure leading/trailing slashes)
    -- ════════════════════════════════════════════════════════
    FUNCTION normalize_path (p_path IN VARCHAR2) RETURN VARCHAR2
    IS
        v_path VARCHAR2(500) := p_path;
    BEGIN
        -- Default to root if NULL
        IF v_path IS NULL THEN
            RETURN '/';
        END IF;

        -- Ensure leading slash
        IF SUBSTR(v_path, 1, 1) != '/' THEN
            v_path := '/' || v_path;
        END IF;

        -- Ensure trailing slash
        IF SUBSTR(v_path, -1) != '/' THEN
            v_path := v_path || '/';
        END IF;

        RETURN v_path;
    END normalize_path;

    -- ════════════════════════════════════════════════════════
    -- Private: Resolve MIME type from file extension
    -- ════════════════════════════════════════════════════════
    FUNCTION get_mime_type (p_file_type IN VARCHAR2) RETURN VARCHAR2
    IS
        v_mime VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT mime_type
              INTO v_mime
              FROM file_type_lookup
             WHERE LOWER(file_type) = LOWER(p_file_type)
               AND is_active = 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_mime := gc_default_mime_type;
        END;

        RETURN v_mime;
    END get_mime_type;

    -- ════════════════════════════════════════════════════════
    -- GET_REPORT_URL (Public)
    -- ════════════════════════════════════════════════════════
    FUNCTION get_report_url (
        p_settings_id    IN NUMBER   DEFAULT 1,
        p_file_base_name IN VARCHAR2,
        p_file_type      IN VARCHAR2 DEFAULT 'pdf'
    ) RETURN VARCHAR2
    IS
        v_hostname       VARCHAR2(200);
        v_port           VARCHAR2(10);
        v_protocol       VARCHAR2(10);
        v_base_path      VARCHAR2(500);
        v_url            VARCHAR2(2000);
        v_file_name      VARCHAR2(200);
    BEGIN
        -- Fetch server settings
        SELECT hostname, port, protocol, base_report_path
          INTO v_hostname, v_port, v_protocol, v_base_path
          FROM report_settings
         WHERE id = p_settings_id
           AND is_active = 'Y';

        -- Normalize path
        v_base_path := normalize_path(v_base_path);

        -- Build file name with extension
        v_file_name := p_file_base_name || '.' || LOWER(p_file_type);

        -- Construct URL
        IF v_port IS NULL 
           OR (LOWER(v_protocol) = 'https' AND v_port = '443')
           OR (LOWER(v_protocol) = 'http'  AND v_port = '80')
        THEN
            -- Omit default ports
            v_url := LOWER(v_protocol) || '://' || v_hostname 
                  || gc_jasper_rest_path || v_base_path || v_file_name;
        ELSE
            v_url := LOWER(v_protocol) || '://' || v_hostname || ':' || v_port 
                  || gc_jasper_rest_path || v_base_path || v_file_name;
        END IF;

        RETURN v_url;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_report_url;

    -- ════════════════════════════════════════════════════════
    -- GET_REPORT (Public)
    -- ════════════════════════════════════════════════════════
    PROCEDURE get_report (
        p_report_id         IN NUMBER    DEFAULT 1,
        p_settings_id       IN NUMBER    DEFAULT 1,
        p_file_base_name    IN VARCHAR2  DEFAULT NULL,
        p_file_type         IN VARCHAR2  DEFAULT 'pdf',
        p_param_name        IN VARCHAR2  DEFAULT NULL,
        p_param_value       IN VARCHAR2  DEFAULT NULL,
        p_output_filename   IN VARCHAR2  DEFAULT NULL,
        p_add_tenant_schema IN BOOLEAN   DEFAULT TRUE
    )
    IS
        -- Server settings
        v_hostname            VARCHAR2(200);
        v_port                VARCHAR2(10);
        v_protocol            VARCHAR2(10);
        v_username            VARCHAR2(100);
        v_password            VARCHAR2(100);
        v_base_report_path    VARCHAR2(500);
        v_content_disposition VARCHAR2(50);

        -- Report variables
        v_blob                BLOB;
        v_file_name           VARCHAR2(200);
        v_report_url          VARCHAR2(2000);
        v_output_filename     VARCHAR2(200);
        v_mime_type           VARCHAR2(100);
        v_current_schema      VARCHAR2(128);

        -- Parameter arrays
        v_param_names_tab     apex_application_global.vc_arr2;
        v_param_values_tab    apex_application_global.vc_arr2;

        -- HTTP response tracking
        v_http_status         NUMBER;

        -- Error context
        v_error_source        VARCHAR2(500);
        v_user_name           VARCHAR2(128) := NVL(v('APP_USER'), USER);
    BEGIN
        -- ── Step 1: Clear previous request state ────────────
        cleanup_request;

        -- ── Step 2: Fetch server settings ───────────────────
        v_error_source := 'GET_REPORT - Fetch Server Settings';
        BEGIN
            SELECT hostname, port, protocol, username, password,
                   base_report_path, content_disposition
              INTO v_hostname, v_port, v_protocol, v_username, v_password,
                   v_base_report_path, v_content_disposition
              FROM report_settings
             WHERE id = p_settings_id
               AND is_active = 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                report_error_log_pkg.log_error(
                    p_error_message => 'No active server settings found for ID: ' || p_settings_id,
                    p_error_source  => v_error_source,
                    p_user_name     => v_user_name,
                    p_settings_id   => p_settings_id
                );
                HTP.p('<h3>Configuration Error</h3>');
                HTP.p('<p>No active report server settings found for Settings ID: ' || p_settings_id || '</p>');
                cleanup_request;
                RETURN;
        END;

        -- ── Step 3: Normalize base report path ──────────────
        v_base_report_path := normalize_path(v_base_report_path);

        -- ── Step 4: Prepare parameter arrays ────────────────
        v_error_source := 'GET_REPORT - Prepare Parameters';
        BEGIN
            IF p_param_name IS NOT NULL THEN
                v_param_names_tab := apex_util.string_to_table(p_param_name, gc_param_separator);
            END IF;

            IF p_param_value IS NOT NULL THEN
                v_param_values_tab := apex_util.string_to_table(p_param_value, gc_param_separator);
            END IF;

            -- Append tenant schema parameter for multi-tenant support
            IF p_add_tenant_schema THEN
                SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
                  INTO v_current_schema
                  FROM DUAL;

                v_param_names_tab(v_param_names_tab.COUNT + 1)  := 'P_TENANT_SCHEMA';
                v_param_values_tab(v_param_values_tab.COUNT + 1) := v_current_schema;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                report_error_log_pkg.log_error(
                    p_error_message => 'Error preparing parameters: ' || SQLERRM,
                    p_error_source  => v_error_source,
                    p_user_name     => v_user_name,
                    p_error_code    => SQLCODE,
                    p_settings_id   => p_settings_id
                );
                HTP.p('<h3>Parameter Error</h3>');
                HTP.p('<p>Error preparing report parameters. Check that parameter names and values match.</p>');
                cleanup_request;
                RETURN;
        END;

        -- ── Step 5: Construct report URL ────────────────────
        v_error_source := 'GET_REPORT - Construct URL';
        v_file_name := p_file_base_name || '.' || LOWER(p_file_type);

        IF v_port IS NULL
           OR (LOWER(v_protocol) = 'https' AND v_port = '443')
           OR (LOWER(v_protocol) = 'http'  AND v_port = '80')
        THEN
            v_report_url := LOWER(v_protocol) || '://' || v_hostname
                         || gc_jasper_rest_path || v_base_report_path || v_file_name;
        ELSE
            v_report_url := LOWER(v_protocol) || '://' || v_hostname || ':' || v_port
                         || gc_jasper_rest_path || v_base_report_path || v_file_name;
        END IF;

        -- ── Step 6: Make REST request ───────────────────────
        v_error_source := 'GET_REPORT - REST Request';
        BEGIN
            v_blob := apex_web_service.make_rest_request_b(
                p_url         => v_report_url,
                p_http_method => 'GET',
                p_username    => v_username,
                p_password    => v_password,
                p_parm_name   => v_param_names_tab,
                p_parm_value  => v_param_values_tab
            );

            -- Capture HTTP status code from response headers
            BEGIN
                v_http_status := apex_web_service.g_status_code;
            EXCEPTION
                WHEN OTHERS THEN
                    v_http_status := NULL;
            END;

        EXCEPTION
            WHEN OTHERS THEN
                report_error_log_pkg.log_error(
                    p_error_message    => 'REST request failed: ' || SQLERRM,
                    p_error_source     => v_error_source,
                    p_user_name        => v_user_name,
                    p_error_code       => SQLCODE,
                    p_report_url       => v_report_url,
                    p_report_config_id => p_report_id,
                    p_settings_id      => p_settings_id
                );
                HTP.p('<h3>Connection Error</h3>');
                HTP.p('<p>Failed to connect to JasperReports Server.</p>');
                HTP.p('<p>Error: ' || SQLERRM || '</p>');
                HTP.p('<p><strong>Troubleshooting:</strong></p>');
                HTP.p('<ul>');
                HTP.p('<li>Verify ACL grants are configured (ORA-24247)</li>');
                HTP.p('<li>Verify JasperReports Server is running</li>');
                HTP.p('<li>Verify hostname and port: ' || v_hostname || ':' || v_port || '</li>');
                HTP.p('<li>Check network connectivity from Oracle DB</li>');
                HTP.p('</ul>');
                cleanup_request;
                RETURN;
        END;

        -- ── Step 7: Validate response ───────────────────────
        v_error_source := 'GET_REPORT - Validate Response';

        -- Check HTTP status
        IF v_http_status IS NOT NULL AND v_http_status != 200 THEN
            report_error_log_pkg.log_error(
                p_error_message    => 'JasperReports returned HTTP ' || v_http_status,
                p_error_source     => v_error_source,
                p_user_name        => v_user_name,
                p_error_code       => 'HTTP_' || v_http_status,
                p_report_url       => v_report_url,
                p_http_status_code => v_http_status,
                p_report_config_id => p_report_id,
                p_settings_id      => p_settings_id
            );
            HTP.p('<h3>Report Server Error (HTTP ' || v_http_status || ')</h3>');
            CASE v_http_status
                WHEN 401 THEN
                    HTP.p('<p>Authentication failed. Check username/password in REPORT_SETTINGS.</p>');
                WHEN 404 THEN
                    HTP.p('<p>Report not found. Check report path: ' || v_base_report_path || v_file_name || '</p>');
                WHEN 500 THEN
                    HTP.p('<p>JasperReports Server internal error. Check server logs.</p>');
                ELSE
                    HTP.p('<p>Unexpected HTTP status code.</p>');
            END CASE;
            cleanup_request;
            RETURN;
        END IF;

        -- Check BLOB content
        IF v_blob IS NULL OR DBMS_LOB.GETLENGTH(v_blob) < gc_min_blob_size THEN
            report_error_log_pkg.log_warning(
                p_message    => 'Empty or too-small PDF response (' 
                             || NVL(DBMS_LOB.GETLENGTH(v_blob), 0) || ' bytes)',
                p_source     => v_error_source,
                p_user_name  => v_user_name,
                p_report_url => v_report_url
            );
            HTP.p('<h3>Error: Empty Report</h3>');
            HTP.p('<p>The report server returned an empty or invalid response.</p>');
            HTP.p('<p><strong>Possible causes:</strong></p>');
            HTP.p('<ul>');
            HTP.p('<li>Wrong report path: <code>' || v_base_report_path || '</code></li>');
            HTP.p('<li>Wrong file name: <code>' || v_file_name || '</code></li>');
            HTP.p('<li>Missing or invalid parameters</li>');
            HTP.p('<li>Report query returned no data</li>');
            HTP.p('<li>JasperReports Server configuration error</li>');
            HTP.p('</ul>');
            cleanup_request;
            RETURN;
        END IF;

        -- ── Step 8: Deliver report to browser ───────────────
        v_error_source := 'GET_REPORT - Deliver Report';
        BEGIN
            -- Resolve MIME type
            v_mime_type := get_mime_type(p_file_type);

            -- Determine output filename
            v_output_filename := NVL(p_output_filename, p_file_base_name)
                              || '.' || LOWER(p_file_type);

            -- Set HTTP response headers
            OWA_UTIL.MIME_HEADER(v_mime_type, FALSE);
            HTP.p('Content-Length: ' || DBMS_LOB.GETLENGTH(v_blob));
            HTP.p('Content-Disposition: ' || v_content_disposition 
                || '; filename="' || v_output_filename || '"');
            OWA_UTIL.HTTP_HEADER_CLOSE;

            -- Stream the file to the client
            WPG_DOCLOAD.DOWNLOAD_FILE(v_blob);

            -- Log success
            report_error_log_pkg.log_info(
                p_message          => 'Report delivered successfully (' 
                                   || DBMS_LOB.GETLENGTH(v_blob) || ' bytes)',
                p_source           => v_error_source,
                p_user_name        => v_user_name,
                p_report_url       => v_report_url,
                p_report_config_id => p_report_id
            );

            -- Stop APEX engine to prevent further page rendering
            APEX_APPLICATION.STOP_APEX_ENGINE;

        EXCEPTION
            WHEN OTHERS THEN
                report_error_log_pkg.log_error(
                    p_error_message    => 'Error delivering report: ' || SQLERRM,
                    p_error_source     => v_error_source,
                    p_user_name        => v_user_name,
                    p_error_code       => SQLCODE,
                    p_report_url       => v_report_url,
                    p_report_config_id => p_report_id,
                    p_settings_id      => p_settings_id
                );
                RAISE;
        END;

        -- ── Final Cleanup ───────────────────────────────────
        cleanup_request;
        IF v_blob IS NOT NULL THEN
            v_blob := EMPTY_BLOB();
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Global exception handler
            report_error_log_pkg.log_error(
                p_error_message    => 'Unexpected error in GET_REPORT: ' || SQLERRM,
                p_error_source     => 'GET_REPORT - Global Exception',
                p_user_name        => v_user_name,
                p_error_code       => SQLCODE,
                p_report_url       => v_report_url,
                p_report_config_id => p_report_id,
                p_settings_id      => p_settings_id
            );
            HTP.p('<h3>Unexpected Error</h3>');
            HTP.p('<p>' || SQLERRM || '</p>');
            cleanup_request;
    END get_report;

    -- ════════════════════════════════════════════════════════
    -- TEST_CONNECTION (Public)
    -- ════════════════════════════════════════════════════════
    PROCEDURE test_connection (
        p_settings_id IN NUMBER DEFAULT 1
    )
    IS
        v_hostname VARCHAR2(200);
        v_port     VARCHAR2(10);
        v_protocol VARCHAR2(10);
        v_url      VARCHAR2(2000);
        v_blob     BLOB;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('═══ JasperReports Connection Test ═══');
        DBMS_OUTPUT.PUT_LINE('');

        -- Fetch settings
        SELECT hostname, port, protocol
          INTO v_hostname, v_port, v_protocol
          FROM report_settings
         WHERE id = p_settings_id
           AND is_active = 'Y';

        -- Construct login page URL
        IF v_port IS NULL
           OR (LOWER(v_protocol) = 'https' AND v_port = '443')
           OR (LOWER(v_protocol) = 'http'  AND v_port = '80')
        THEN
            v_url := LOWER(v_protocol) || '://' || v_hostname || '/jasperserver/login.html';
        ELSE
            v_url := LOWER(v_protocol) || '://' || v_hostname || ':' || v_port || '/jasperserver/login.html';
        END IF;

        DBMS_OUTPUT.PUT_LINE('  Target: ' || v_url);
        DBMS_OUTPUT.PUT_LINE('');

        -- Attempt connection
        cleanup_request;
        v_blob := apex_web_service.make_rest_request_b(
            p_url         => v_url,
            p_http_method => 'GET'
        );

        IF apex_web_service.g_status_code IN (200, 302) THEN
            DBMS_OUTPUT.PUT_LINE('  ✓ PASS: JasperReports Server is reachable.');
            DBMS_OUTPUT.PUT_LINE('  HTTP Status: ' || apex_web_service.g_status_code);
        ELSE
            DBMS_OUTPUT.PUT_LINE('  ⚠ WARNING: Unexpected HTTP status: ' || apex_web_service.g_status_code);
        END IF;

        cleanup_request;
        DBMS_OUTPUT.PUT_LINE('');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('  ✗ FAIL: No active settings found for ID: ' || p_settings_id);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  ✗ FAIL: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  Troubleshooting:');
            DBMS_OUTPUT.PUT_LINE('    - Check ACL grants (DBMS_NETWORK_ACL_ADMIN)');
            DBMS_OUTPUT.PUT_LINE('    - Verify hostname/port in REPORT_SETTINGS');
            DBMS_OUTPUT.PUT_LINE('    - Verify JasperReports container is running');
            DBMS_OUTPUT.PUT_LINE('    - Check Docker network connectivity');
            cleanup_request;
    END test_connection;

END jasper_report_pkg;
/
