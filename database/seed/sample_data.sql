-- ══════════════════════════════════════════════════════════════
-- Sample Data — REPORT_SETTINGS & REPORT_CONFIG
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Provides sample configuration data so users can test the
--   integration immediately after installation.
--
-- Usage:
--   Run as the application schema owner after creating all tables.
--
-- Important:
--   Replace placeholder values with your actual JasperReports
--   Server connection details before use.
-- ══════════════════════════════════════════════════════════════

-- ── Sample Report Server Settings ───────────────────────────

-- Development server (Docker)
INSERT INTO report_settings (
    setting_name, hostname, port, protocol,
    username, password, base_report_path,
    content_disposition, is_active
) VALUES (
    'Development Server',
    'jasper-server',            -- Docker service name
    '8080',                     -- Default Tomcat port
    'http',                     -- HTTP for internal Docker network
    'jasperadmin',              -- Default JasperReports admin user
    'jasperadmin',              -- ** CHANGE THIS IN PRODUCTION **
    '/reports/',                -- Base path for your reports
    'inline',                   -- Display PDF in browser
    'Y'
);

-- Production server (example)
INSERT INTO report_settings (
    setting_name, hostname, port, protocol,
    username, password, base_report_path,
    content_disposition, is_active
) VALUES (
    'Production Server',
    'jasper.example.com',       -- Your production hostname
    '443',                      -- HTTPS port
    'https',                    -- HTTPS for production
    'report_user',              -- Dedicated reporting user
    'CHANGE_ME_SECURE_PASS',    -- ** CHANGE THIS **
    '/reports/',
    'attachment',               -- Force download in production
    'N'                         -- Inactive until configured
);

-- ── Sample Report Configurations ────────────────────────────

-- Patient Profile Report
INSERT INTO report_config (
    settings_id, report_name, file_name,
    parameter_name, parameter_value,
    description, is_active
) VALUES (
    1,                                          -- Development Server
    'Patient Profile Report',
    'patient_profile',                          -- Maps to patient_profile.pdf
    'P_PATIENT_ID',                             -- Single parameter
    NULL,                                       -- Value provided at runtime
    'Generates a detailed patient profile with personal information, medical history, and contact details.',
    'Y'
);

-- Patient Booking History Report
INSERT INTO report_config (
    settings_id, report_name, file_name,
    parameter_name, parameter_value,
    description, is_active
) VALUES (
    1,
    'Patient Booking History',
    'patient_bookings',
    'P_PATIENT_ID;P_DATE_FROM;P_DATE_TO',      -- Multiple parameters
    NULL,                                       -- Values provided at runtime
    'Lists all bookings for a patient within a date range.',
    'Y'
);

-- Invoice Report
INSERT INTO report_config (
    settings_id, report_name, file_name,
    parameter_name, parameter_value,
    description, is_active
) VALUES (
    1,
    'Invoice Report',
    'invoice_report',
    'P_INVOICE_ID',
    NULL,
    'Generates an invoice with line items, totals, and payment details.',
    'Y'
);

-- Employee Directory Report
INSERT INTO report_config (
    settings_id, report_name, file_name,
    parameter_name, parameter_value,
    description, is_active
) VALUES (
    1,
    'Employee Directory',
    'employee_directory',
    'P_DEPARTMENT_ID',
    NULL,
    'Lists all employees in a department with contact information.',
    'Y'
);

-- Monthly Summary Report (with default parameter values)
INSERT INTO report_config (
    settings_id, report_name, file_name,
    parameter_name, parameter_value,
    description, is_active
) VALUES (
    1,
    'Monthly Summary Report',
    'monthly_summary',
    'P_YEAR;P_MONTH',
    '2026;06',                                  -- Default values
    'Generates a monthly activity summary report.',
    'Y'
);

COMMIT;

PROMPT
PROMPT ✓ Sample data inserted successfully.
PROMPT   - 2 server settings (Development, Production)
PROMPT   - 5 report configurations
PROMPT
