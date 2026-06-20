-- ══════════════════════════════════════════════════════════════
-- JASPER_REPORT_PKG — Package Specification
-- Oracle APEX + JasperReports Integration
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Provides a clean PL/SQL API for generating reports from
--   JasperReports Server via APEX_WEB_SERVICE REST calls.
--
-- Features:
--   - Fetches reports as BLOB (PDF, Excel, CSV, etc.)
--   - Supports dynamic parameters (semicolon-separated)
--   - Multi-tenant schema support (P_TENANT_SCHEMA parameter)
--   - Configurable protocol (HTTP/HTTPS)
--   - Structured error logging via REPORT_ERROR_LOG_PKG
--   - Automatic HTTP header management
--
-- Dependencies:
--   - REPORT_SETTINGS table
--   - REPORT_CONFIG table
--   - FILE_TYPE_LOOKUP table
--   - REPORT_ERROR_LOG_PKG package
--   - ERROR_INFO_TYPE object type
--   - APEX_WEB_SERVICE (Oracle APEX)
--   - APEX_UTIL (Oracle APEX)
--
-- Usage:
--   Run as the application schema owner.
--
--   -- From an APEX page process (Before Header or On Submit):
--   JASPER_REPORT_PKG.GET_REPORT(
--       p_settings_id    => 1,
--       p_file_base_name => 'patient_profile',
--       p_file_type      => 'pdf',
--       p_param_name     => 'P_PATIENT_ID',
--       p_param_value    => :P1_PATIENT_ID,
--       p_output_filename => 'Patient_Profile_' || :P1_PATIENT_ID
--   );
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE jasper_report_pkg
AUTHID CURRENT_USER
AS
    -- ── Package Constants ───────────────────────────────────
    gc_version           CONSTANT VARCHAR2(10)  := '1.0.0';
    gc_default_file_type CONSTANT VARCHAR2(10)  := 'pdf';
    gc_default_mime_type CONSTANT VARCHAR2(100) := 'application/pdf';
    gc_min_blob_size     CONSTANT NUMBER        := 100;
    gc_jasper_rest_path  CONSTANT VARCHAR2(200) := '/jasperserver/rest_v2/reports';
    gc_param_separator   CONSTANT VARCHAR2(1)   := ';';

    -- ────────────────────────────────────────────────────────
    -- GET_REPORT
    -- ────────────────────────────────────────────────────────
    -- Main procedure: fetches a report from JasperReports Server
    -- and delivers it to the browser as a downloadable file.
    --
    -- Parameters:
    --   p_report_id       - Report Configuration ID (FK to REPORT_CONFIG)
    --   p_settings_id     - Server Settings ID (FK to REPORT_SETTINGS)
    --   p_file_base_name  - Report file name on JasperReports Server
    --                       (without extension, e.g., 'patient_profile')
    --   p_file_type       - Output format: pdf, xlsx, csv, html, xml, docx
    --   p_param_name      - Semicolon-separated parameter names
    --                       (e.g., 'P_PATIENT_ID;P_DATE_FROM')
    --   p_param_value     - Semicolon-separated parameter values
    --                       (e.g., '101;2026-01-01')
    --   p_output_filename - File name for the downloaded file
    --                       (without extension, e.g., 'Patient_Report_101')
    --   p_add_tenant_schema - If TRUE, automatically appends P_TENANT_SCHEMA
    --                         parameter with the current schema name
    -- ────────────────────────────────────────────────────────
    PROCEDURE get_report (
        p_report_id         IN NUMBER    DEFAULT 1,
        p_settings_id       IN NUMBER    DEFAULT 1,
        p_file_base_name    IN VARCHAR2  DEFAULT NULL,
        p_file_type         IN VARCHAR2  DEFAULT 'pdf',
        p_param_name        IN VARCHAR2  DEFAULT NULL,
        p_param_value       IN VARCHAR2  DEFAULT NULL,
        p_output_filename   IN VARCHAR2  DEFAULT NULL,
        p_add_tenant_schema IN BOOLEAN   DEFAULT TRUE
    );

    -- ────────────────────────────────────────────────────────
    -- GET_REPORT_URL
    -- ────────────────────────────────────────────────────────
    -- Utility function: constructs the full JasperReports REST
    -- URL without making the HTTP call. Useful for debugging.
    --
    -- Returns:
    --   The fully constructed URL string.
    -- ────────────────────────────────────────────────────────
    FUNCTION get_report_url (
        p_settings_id    IN NUMBER   DEFAULT 1,
        p_file_base_name IN VARCHAR2,
        p_file_type      IN VARCHAR2 DEFAULT 'pdf'
    ) RETURN VARCHAR2;

    -- ────────────────────────────────────────────────────────
    -- TEST_CONNECTION
    -- ────────────────────────────────────────────────────────
    -- Tests HTTP connectivity to the JasperReports Server.
    -- Outputs results via DBMS_OUTPUT.
    --
    -- Parameters:
    --   p_settings_id - Server Settings ID to test
    -- ────────────────────────────────────────────────────────
    PROCEDURE test_connection (
        p_settings_id IN NUMBER DEFAULT 1
    );

END jasper_report_pkg;
/
