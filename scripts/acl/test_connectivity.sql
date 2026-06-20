-- ══════════════════════════════════════════════════════════════
-- Connectivity Test — UTL_HTTP to JasperReports Server
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Quick test to verify that Oracle Database can make outbound
--   HTTP calls to the JasperReports Server after ACL grants.
--
-- Usage:
--   Run as the APEX schema owner or SYSDBA.
--
--   Before running, optionally set:
--     DEFINE JASPER_HOST = 'jasper-server'
--     DEFINE JASPER_PORT = '8080'
-- ══════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
WHENEVER SQLERROR CONTINUE

DEFINE JASPER_HOST = 'jasper-server'
DEFINE JASPER_PORT = '8080'

PROMPT
PROMPT === UTL_HTTP Connectivity Test -> &JASPER_HOST.:&JASPER_PORT ===
PROMPT

DECLARE
    v_req   UTL_HTTP.REQ;
    v_resp  UTL_HTTP.RESP;
    v_url   VARCHAR2(200) := 'http://&JASPER_HOST.:&JASPER_PORT./jasperserver/login.html';
BEGIN
    DBMS_OUTPUT.PUT_LINE('  Target: ' || v_url);
    DBMS_OUTPUT.PUT_LINE('');

    UTL_HTTP.SET_TRANSFER_TIMEOUT(10);
    v_req  := UTL_HTTP.BEGIN_REQUEST(v_url, 'GET');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);

    DBMS_OUTPUT.PUT_LINE('  HTTP Status : ' || v_resp.status_code || ' ' || v_resp.reason_phrase);
    UTL_HTTP.END_RESPONSE(v_resp);

    IF v_resp.status_code IN (200, 302) THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  ✓ PASS: JasperReports Server is reachable from Oracle DB.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  ⚠ WARNING: Unexpected status code: ' || v_resp.status_code);
    END IF;

EXCEPTION
    WHEN UTL_HTTP.REQUEST_FAILED THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ FAIL: UTL_HTTP.REQUEST_FAILED');
        DBMS_OUTPUT.PUT_LINE('    ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  Troubleshooting:');
        DBMS_OUTPUT.PUT_LINE('    1. Check Docker network — is JasperReports container running?');
        DBMS_OUTPUT.PUT_LINE('    2. Check ACL grants — run grant_acl.sql as SYSDBA');
        DBMS_OUTPUT.PUT_LINE('    3. Check hostname/port — verify &JASPER_HOST.:&JASPER_PORT');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ FAIL: ' || SQLCODE || ': ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  Troubleshooting:');
        DBMS_OUTPUT.PUT_LINE('    1. EXECUTE on UTL_HTTP may not be granted');
        DBMS_OUTPUT.PUT_LINE('    2. ACL host entry may not exist');
        DBMS_OUTPUT.PUT_LINE('    3. Run: SELECT * FROM dba_host_aces WHERE host = ''&JASPER_HOST'';');
END;
/

PROMPT
EXIT;
