-- ══════════════════════════════════════════════════════════════
-- Test Report Generation — Verify End-to-End Integration
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Quick test script to verify the JasperReports integration
--   is working correctly. Tests URL construction and connection.
--
-- Usage:
--   Run as the APEX application schema owner.
-- ══════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT
PROMPT === JasperReports Integration Test ===
PROMPT

-- Test 1: Verify tables exist
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[Test 1] Verifying database objects...');

    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'REPORT_SETTINGS';
    DBMS_OUTPUT.PUT_LINE('  REPORT_SETTINGS table: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);

    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'REPORT_CONFIG';
    DBMS_OUTPUT.PUT_LINE('  REPORT_CONFIG table: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);

    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'REPORT_LOG';
    DBMS_OUTPUT.PUT_LINE('  REPORT_LOG table: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);

    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'FILE_TYPE_LOOKUP';
    DBMS_OUTPUT.PUT_LINE('  FILE_TYPE_LOOKUP table: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);

    SELECT COUNT(*) INTO v_count FROM user_objects WHERE object_name = 'JASPER_REPORT_PKG' AND object_type = 'PACKAGE';
    DBMS_OUTPUT.PUT_LINE('  JASPER_REPORT_PKG package: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);

    SELECT COUNT(*) INTO v_count FROM user_objects WHERE object_name = 'REPORT_ERROR_LOG_PKG' AND object_type = 'PACKAGE';
    DBMS_OUTPUT.PUT_LINE('  REPORT_ERROR_LOG_PKG package: ' || CASE WHEN v_count > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END);
END;
/

-- Test 2: Verify sample data
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[Test 2] Verifying sample data...');

    SELECT COUNT(*) INTO v_count FROM report_settings;
    DBMS_OUTPUT.PUT_LINE('  REPORT_SETTINGS rows: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM report_config;
    DBMS_OUTPUT.PUT_LINE('  REPORT_CONFIG rows: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM file_type_lookup;
    DBMS_OUTPUT.PUT_LINE('  FILE_TYPE_LOOKUP rows: ' || v_count);
END;
/

-- Test 3: Test URL construction
DECLARE
    v_url VARCHAR2(2000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[Test 3] Testing URL construction...');

    v_url := jasper_report_pkg.get_report_url(
        p_settings_id    => 1,
        p_file_base_name => 'test_report',
        p_file_type      => 'pdf'
    );

    IF v_url IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('  ✓ URL: ' || v_url);
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ✗ URL construction returned NULL');
        DBMS_OUTPUT.PUT_LINE('    Check REPORT_SETTINGS has an active row with ID=1');
    END IF;
END;
/

-- Test 4: Test connection to JasperReports
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[Test 4] Testing connection to JasperReports Server...');
    jasper_report_pkg.test_connection(p_settings_id => 1);
END;
/

PROMPT
PROMPT === Test Complete ===
PROMPT
