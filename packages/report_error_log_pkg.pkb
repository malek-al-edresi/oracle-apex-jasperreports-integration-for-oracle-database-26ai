-- ══════════════════════════════════════════════════════════════
-- REPORT_ERROR_LOG_PKG — Package Body
-- Error and Activity Logging for Report Generation
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE BODY report_error_log_pkg
AS

    -- ════════════════════════════════════════════════════════
    -- Private helper: resolve current user
    -- ════════════════════════════════════════════════════════
    FUNCTION get_user (p_user_name IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(p_user_name, NVL(v('APP_USER'), USER));
    END get_user;

    -- ════════════════════════════════════════════════════════
    -- Generic log procedure (autonomous transaction)
    -- ════════════════════════════════════════════════════════
    PROCEDURE log_event (
        p_log_level         IN VARCHAR2,
        p_error_message     IN VARCHAR2,
        p_error_source      IN VARCHAR2,
        p_processing_status IN VARCHAR2 DEFAULT 'ERROR',
        p_user_name         IN VARCHAR2 DEFAULT NULL,
        p_error_code        IN VARCHAR2 DEFAULT NULL,
        p_report_url        IN VARCHAR2 DEFAULT NULL,
        p_http_status_code  IN NUMBER   DEFAULT NULL,
        p_report_config_id  IN NUMBER   DEFAULT NULL,
        p_settings_id       IN NUMBER   DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_app_user    VARCHAR2(256);
        v_session_id  VARCHAR2(100);
    BEGIN
        -- Capture APEX context if available
        BEGIN
            v_app_user   := v('APP_USER');
            v_session_id := v('APP_SESSION');
        EXCEPTION
            WHEN OTHERS THEN
                v_app_user   := NULL;
                v_session_id := NULL;
        END;

        INSERT INTO report_log (
            log_level,
            error_message,
            error_source,
            error_code,
            processing_status,
            report_url,
            http_status_code,
            report_config_id,
            settings_id,
            user_name,
            app_user,
            session_id
        ) VALUES (
            p_log_level,
            SUBSTR(p_error_message, 1, 4000),
            SUBSTR(p_error_source, 1, 500),
            SUBSTR(p_error_code, 1, 20),
            p_processing_status,
            SUBSTR(p_report_url, 1, 2000),
            p_http_status_code,
            p_report_config_id,
            p_settings_id,
            get_user(p_user_name),
            v_app_user,
            v_session_id
        );

        COMMIT;  -- Autonomous transaction commit
    EXCEPTION
        WHEN OTHERS THEN
            -- Last-resort: if logging itself fails, silently discard.
            -- Never let logging errors propagate to the caller.
            ROLLBACK;
    END log_event;

    -- ════════════════════════════════════════════════════════
    -- Log ERROR
    -- ════════════════════════════════════════════════════════
    PROCEDURE log_error (
        p_error_message    IN VARCHAR2,
        p_error_source     IN VARCHAR2,
        p_user_name        IN VARCHAR2 DEFAULT NULL,
        p_error_code       IN VARCHAR2 DEFAULT NULL,
        p_report_url       IN VARCHAR2 DEFAULT NULL,
        p_http_status_code IN NUMBER   DEFAULT NULL,
        p_report_config_id IN NUMBER   DEFAULT NULL,
        p_settings_id      IN NUMBER   DEFAULT NULL
    )
    IS
    BEGIN
        log_event(
            p_log_level         => 'ERROR',
            p_error_message     => p_error_message,
            p_error_source      => p_error_source,
            p_processing_status => 'ERROR',
            p_user_name         => p_user_name,
            p_error_code        => p_error_code,
            p_report_url        => p_report_url,
            p_http_status_code  => p_http_status_code,
            p_report_config_id  => p_report_config_id,
            p_settings_id       => p_settings_id
        );
    END log_error;

    -- ════════════════════════════════════════════════════════
    -- Log WARNING
    -- ════════════════════════════════════════════════════════
    PROCEDURE log_warning (
        p_message          IN VARCHAR2,
        p_source           IN VARCHAR2,
        p_user_name        IN VARCHAR2 DEFAULT NULL,
        p_report_url       IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN
        log_event(
            p_log_level         => 'WARNING',
            p_error_message     => p_message,
            p_error_source      => p_source,
            p_processing_status => 'WARNING',
            p_user_name         => p_user_name,
            p_report_url        => p_report_url
        );
    END log_warning;

    -- ════════════════════════════════════════════════════════
    -- Log INFO
    -- ════════════════════════════════════════════════════════
    PROCEDURE log_info (
        p_message          IN VARCHAR2,
        p_source           IN VARCHAR2,
        p_user_name        IN VARCHAR2 DEFAULT NULL,
        p_report_url       IN VARCHAR2 DEFAULT NULL,
        p_report_config_id IN NUMBER   DEFAULT NULL
    )
    IS
    BEGIN
        log_event(
            p_log_level         => 'INFO',
            p_error_message     => p_message,
            p_error_source      => p_source,
            p_processing_status => 'SUCCESS',
            p_user_name         => p_user_name,
            p_report_url        => p_report_url,
            p_report_config_id  => p_report_config_id
        );
    END log_info;

    -- ════════════════════════════════════════════════════════
    -- Purge old log records
    -- ════════════════════════════════════════════════════════
    PROCEDURE purge_logs (
        p_days_to_keep IN NUMBER DEFAULT 90
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_count NUMBER;
    BEGIN
        DELETE FROM report_log
         WHERE created_at < SYSTIMESTAMP - p_days_to_keep;

        v_count := SQL%ROWCOUNT;
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Purged ' || v_count || ' log records older than ' || p_days_to_keep || ' days.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END purge_logs;

END report_error_log_pkg;
/
