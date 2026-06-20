-- ══════════════════════════════════════════════════════════════
-- Example: Generate Employee Directory Report
-- ══════════════════════════════════════════════════════════════

-- ── All employees ───────────────────────────────────────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'employee_directory',
        p_file_type       => 'pdf',
        p_param_name      => NULL,                       -- No filter = all employees
        p_param_value     => NULL,
        p_output_filename => 'Employee_Directory_All'
    );
END;
/

-- ── Filtered by department ──────────────────────────────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'employee_directory',
        p_file_type       => 'pdf',
        p_param_name      => 'P_DEPARTMENT_ID',
        p_param_value     => :P3_DEPARTMENT_ID,
        p_output_filename => 'Employee_Directory_Dept_' || :P3_DEPARTMENT_ID
    );
END;
/

-- ── Export to Excel for HR analysis ─────────────────────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'employee_directory',
        p_file_type       => 'xlsx',
        p_param_name      => 'P_DEPARTMENT_ID',
        p_param_value     => :P3_DEPARTMENT_ID,
        p_output_filename => 'Employee_Export_' || TO_CHAR(SYSDATE, 'YYYYMMDD')
    );
END;
/
