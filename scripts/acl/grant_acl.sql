-- ══════════════════════════════════════════════════════════════
-- ACL Grants — Network Access Control for JasperReports
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Grants network ACL privileges so that Oracle Database schemas
--   can make outbound HTTP/HTTPS calls to the JasperReports Server.
--
-- Usage:
--   Run as SYSDBA on the target PDB.
--
--   Before running, set substitution variables:
--     DEFINE JASPER_HOST    = 'jasper-server'
--     DEFINE APEX_SCHEMA    = 'YOUR_APEX_SCHEMA'
--     DEFINE JASPER_DB_USER = 'JASPER_REPORT_USER'
--
--   Or run with defaults (Docker setup):
--     @grant_acl.sql
-- ══════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 50
WHENEVER SQLERROR CONTINUE

-- ── Default Values (override before running) ────────────────
-- The JasperReports Server hostname (Docker service name or IP)
DEFINE JASPER_HOST    = 'jasper-server'
-- Your APEX application schema
DEFINE APEX_SCHEMA    = 'YOUR_APEX_SCHEMA'
-- Optional: dedicated JasperReports database user
DEFINE JASPER_DB_USER = 'JASPER_REPORT_USER'

PROMPT
PROMPT ========================================================
PROMPT  JasperReports — Network ACL Grants
PROMPT ========================================================
PROMPT  Target Host  : &JASPER_HOST
PROMPT  APEX Schema  : &APEX_SCHEMA
PROMPT  Jasper User  : &JASPER_DB_USER
PROMPT ========================================================
PROMPT

-- ──────────────────────────────────────────────────────────
-- 1. Grant EXECUTE on Network Packages
-- ──────────────────────────────────────────────────────────
PROMPT [1/3] Granting EXECUTE on network packages ...

DECLARE
    PROCEDURE safe_grant(p_obj VARCHAR2, p_grantee VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || p_obj || ' TO ' || p_grantee;
        DBMS_OUTPUT.PUT_LINE('    ✓ EXECUTE ON ' || p_obj || ' TO ' || p_grantee);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('    ⊘ Skipped: ' || p_obj || ' TO ' || p_grantee 
                || ' (' || SQLERRM || ')');
    END safe_grant;
BEGIN
    -- Grant to APEX schema
    safe_grant('SYS.UTL_HTTP',  '&APEX_SCHEMA');
    safe_grant('SYS.UTL_TCP',   '&APEX_SCHEMA');
    safe_grant('SYS.UTL_URL',   '&APEX_SCHEMA');
    safe_grant('SYS.DBMS_LOB',  '&APEX_SCHEMA');

    -- Grant to dedicated Jasper user (if used)
    safe_grant('SYS.UTL_HTTP',  '&JASPER_DB_USER');
    safe_grant('SYS.UTL_TCP',   '&JASPER_DB_USER');
    safe_grant('SYS.UTL_URL',   '&JASPER_DB_USER');
    safe_grant('SYS.DBMS_LOB',  '&JASPER_DB_USER');
END;
/

-- ──────────────────────────────────────────────────────────
-- 2. ACL: Allow APEX Schema to connect to JasperReports
-- ──────────────────────────────────────────────────────────
PROMPT [2/3] Granting ACL for &APEX_SCHEMA -> &JASPER_HOST ...

BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => '&JASPER_HOST',
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => '&APEX_SCHEMA',
            principal_type => xs_acl.ptype_db
        )
    );
    DBMS_OUTPUT.PUT_LINE('    ✓ ACL granted: &APEX_SCHEMA -> &JASPER_HOST');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('    ⊘ ACL note: ' || SQLERRM);
END;
/

-- ──────────────────────────────────────────────────────────
-- 3. ACL: Allow Jasper DB User to connect to JasperReports
-- ──────────────────────────────────────────────────────────
PROMPT [3/3] Granting ACL for &JASPER_DB_USER -> &JASPER_HOST ...

BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => '&JASPER_HOST',
        ace        => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => '&JASPER_DB_USER',
            principal_type => xs_acl.ptype_db
        )
    );
    DBMS_OUTPUT.PUT_LINE('    ✓ ACL granted: &JASPER_DB_USER -> &JASPER_HOST');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('    ⊘ ACL note: ' || SQLERRM);
END;
/

COMMIT;

PROMPT
PROMPT ========================================================
PROMPT  ✓ ACL Grants Complete
PROMPT ========================================================
PROMPT

-- ══════════════════════════════════════════════════════════
-- VERIFICATION: Show current ACL entries
-- ══════════════════════════════════════════════════════════
PROMPT  -- Verification: ACL entries for &JASPER_HOST --

SELECT host,
       lower_port,
       upper_port,
       principal,
       principal_type,
       privilege
  FROM dba_host_aces
 WHERE host = '&JASPER_HOST'
 ORDER BY principal;

PROMPT
