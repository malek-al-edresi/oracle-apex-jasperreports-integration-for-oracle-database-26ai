-- ══════════════════════════════════════════════════════════════
-- Sync JasperReports Grants — Multi-Tenant Schema Access
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Automatically grants SELECT on tenant schema views to the
--   JasperReports database role. This enables JasperReports to
--   query data from any active tenant schema.
--
-- Usage:
--   Run as SYSDBA or a DBA user.
--
--   Before running, set substitution variables:
--     DEFINE JASPER_ROLE   = 'JASPER_READ_ROLE'
--     DEFINE MASTER_SCHEMA = 'YOUR_MASTER_SCHEMA'
--
-- How it works:
--   1. Reads active tenants from MASTER_SCHEMA.TENANT_METADATA
--   2. Grants SELECT on all views in each active tenant schema
--   3. Revokes SELECT from inactive tenant schemas
-- ══════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED

DEFINE JASPER_ROLE   = 'JASPER_READ_ROLE'
DEFINE MASTER_SCHEMA = 'YOUR_MASTER_SCHEMA'

DECLARE
    v_role_name     VARCHAR2(50)  := '&JASPER_ROLE';
    v_master_schema VARCHAR2(128) := '&MASTER_SCHEMA';
    v_grant_stmt    VARCHAR2(500);
    v_count         NUMBER := 0;
    v_tbl_exist     NUMBER := 0;
    v_username      VARCHAR2(128);
    TYPE t_cursor IS REF CURSOR;
    c_tenants       t_cursor;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting JasperReports Grant Synchronization...');
    DBMS_OUTPUT.PUT_LINE('  Role:   ' || v_role_name);
    DBMS_OUTPUT.PUT_LINE('  Master: ' || v_master_schema);
    DBMS_OUTPUT.PUT_LINE('');

    -- Check if tenant_metadata table exists
    SELECT COUNT(*) INTO v_tbl_exist
      FROM all_tables
     WHERE owner = v_master_schema
       AND table_name = 'TENANT_METADATA';

    IF v_tbl_exist = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ⊘ TENANT_METADATA table not found in ' || v_master_schema);
        DBMS_OUTPUT.PUT_LINE('  Skipping tenant grant synchronization.');
        DBMS_OUTPUT.PUT_LINE('  (Run this script again after tenant onboarding.)');
        RETURN;
    END IF;

    -- Revoke access from inactive tenants
    DBMS_OUTPUT.PUT_LINE('  Revoking grants from inactive tenants...');
    FOR inactive_rec IN (
        SELECT schema_name AS username
        FROM MEDICAL_CENTER_SYSTEM.tenant_metadata
        WHERE status != 'active'
    ) LOOP
        FOR view_rec IN (
            SELECT view_name FROM dba_views
            WHERE owner = inactive_rec.username
        ) LOOP
            SELECT COUNT(*) INTO v_count
              FROM dba_tab_privs
             WHERE owner     = inactive_rec.username
               AND table_name = view_rec.view_name
               AND grantee   = v_role_name
               AND privilege  = 'SELECT';

            IF v_count > 0 THEN
                v_grant_stmt := 'REVOKE SELECT ON ' || inactive_rec.username 
                    || '.' || view_rec.view_name || ' FROM ' || v_role_name;
                BEGIN
                    EXECUTE IMMEDIATE v_grant_stmt;
                    DBMS_OUTPUT.PUT_LINE('    Revoked: ' || inactive_rec.username || '.' || view_rec.view_name);
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('    Error revoking ' || inactive_rec.username 
                            || '.' || view_rec.view_name || ': ' || SQLERRM);
                END;
            END IF;
        END LOOP;
    END LOOP;

    -- Grant access to active tenants
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Granting SELECT to active tenants...');
    v_count := 0;

    OPEN c_tenants FOR
        'SELECT schema_name FROM ' || v_master_schema || '.tenant_metadata WHERE status = ''active''';
    LOOP
        FETCH c_tenants INTO v_username;
        EXIT WHEN c_tenants%NOTFOUND;

        FOR view_rec IN (
            SELECT view_name FROM dba_views
            WHERE owner = v_username
        ) LOOP
            DECLARE
                v_exists NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_exists
                  FROM dba_tab_privs
                 WHERE owner     = v_username
                   AND table_name = view_rec.view_name
                   AND grantee   = v_role_name
                   AND privilege  = 'SELECT';

                IF v_exists = 0 THEN
                    v_grant_stmt := 'GRANT SELECT ON ' || v_username 
                        || '.' || view_rec.view_name || ' TO ' || v_role_name;
                    EXECUTE IMMEDIATE v_grant_stmt;
                    v_count := v_count + 1;
                    DBMS_OUTPUT.PUT_LINE('    Granted: ' || v_username || '.' || view_rec.view_name);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('    Error granting ' || v_username 
                        || '.' || view_rec.view_name || ': ' || SQLERRM);
            END;
        END LOOP;
    END LOOP;
    CLOSE c_tenants;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Total new grants: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('  Synchronization complete.');
END;
/
