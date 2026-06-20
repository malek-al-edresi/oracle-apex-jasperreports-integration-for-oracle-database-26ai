-- ══════════════════════════════════════════════════════════════
-- Example: Generate Patient Profile Report
-- ══════════════════════════════════════════════════════════════
--
-- This example shows how to call JASPER_REPORT_PKG.GET_REPORT
-- from an Oracle APEX page process to generate a Patient Profile
-- PDF report from JasperReports Server.
--
-- APEX Setup:
--   1. Create a Button on your page (e.g., "Print Profile")
--   2. Create a Page Process (type: PL/SQL Code)
--   3. Set the process to fire "On Submit" when the button is pressed
--   4. Paste the code below into the PL/SQL Code section
--   5. Ensure the process point is "Before Header" for direct download
-- ══════════════════════════════════════════════════════════════

-- ── Option 1: Simple call with a single parameter ───────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,                          -- Development Server
        p_file_base_name  => 'patient_profile',          -- JRXML file name (without .pdf)
        p_file_type       => 'pdf',                      -- Output format
        p_param_name      => 'P_PATIENT_ID',             -- Parameter name
        p_param_value     => :P1_PATIENT_ID,             -- APEX page item value
        p_output_filename => 'Patient_Profile_' || :P1_PATIENT_ID
    );
END;
/

-- ── Option 2: Multiple parameters (semicolon-separated) ─────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'patient_bookings',
        p_file_type       => 'pdf',
        p_param_name      => 'P_PATIENT_ID;P_DATE_FROM;P_DATE_TO',
        p_param_value     => :P1_PATIENT_ID || ';' || :P1_DATE_FROM || ';' || :P1_DATE_TO,
        p_output_filename => 'Patient_Bookings_' || :P1_PATIENT_ID
    );
END;
/

-- ── Option 3: Export as Excel instead of PDF ────────────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'patient_profile',
        p_file_type       => 'xlsx',                     -- Excel output
        p_param_name      => 'P_PATIENT_ID',
        p_param_value     => :P1_PATIENT_ID,
        p_output_filename => 'Patient_Profile_' || :P1_PATIENT_ID
    );
END;
/

-- ── Option 4: Debug — just get the URL without fetching ─────
DECLARE
    v_url VARCHAR2(2000);
BEGIN
    v_url := jasper_report_pkg.get_report_url(
        p_settings_id    => 1,
        p_file_base_name => 'patient_profile',
        p_file_type      => 'pdf'
    );
    DBMS_OUTPUT.PUT_LINE('Report URL: ' || v_url);
END;
/
