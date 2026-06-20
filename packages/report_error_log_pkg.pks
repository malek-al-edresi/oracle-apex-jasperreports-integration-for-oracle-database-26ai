-- ══════════════════════════════════════════════════════════════
-- REPORT_ERROR_LOG_PKG — Package Specification
-- Error and Activity Logging for Report Generation
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Provides autonomous-transaction logging procedures for the
--   JasperReports integration. All inserts use PRAGMA
--   AUTONOMOUS_TRANSACTION so log records persist even when
--   the calling transaction rolls back.
--
-- Usage:
--   Run as the application schema owner.
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE report_error_log_pkg
AUTHID CURRENT_USER
AS
    -- ────────────────────────────────────────────────────────
    -- Log an ERROR event
    -- ────────────────────────────────────────────────────────
    PROCEDURE log_error (
        p_error_message    IN VARCHAR2,
        p_error_source     IN VARCHAR2,
        p_user_name        IN VARCHAR2  DEFAULT NULL,
        p_error_code       IN VARCHAR2  DEFAULT NULL,
        p_report_url       IN VARCHAR2  DEFAULT NULL,
        p_http_status_code IN NUMBER    DEFAULT NULL,
        p_report_config_id IN NUMBER    DEFAULT NULL,
        p_settings_id      IN NUMBER    DEFAULT NULL
    );

    -- ────────────────────────────────────────────────────────
    -- Log a WARNING event
    -- ────────────────────────────────────────────────────────
    PROCEDURE log_warning (
        p_message          IN VARCHAR2,
        p_source           IN VARCHAR2,
        p_user_name        IN VARCHAR2  DEFAULT NULL,
        p_report_url       IN VARCHAR2  DEFAULT NULL
    );

    -- ────────────────────────────────────────────────────────
    -- Log an INFO event (success, metrics, etc.)
    -- ────────────────────────────────────────────────────────
    PROCEDURE log_info (
        p_message          IN VARCHAR2,
        p_source           IN VARCHAR2,
        p_user_name        IN VARCHAR2  DEFAULT NULL,
        p_report_url       IN VARCHAR2  DEFAULT NULL,
        p_report_config_id IN NUMBER    DEFAULT NULL
    );

    -- ────────────────────────────────────────────────────────
    -- Generic log procedure (used internally)
    -- ────────────────────────────────────────────────────────
    PROCEDURE log_event (
        p_log_level        IN VARCHAR2,
        p_error_message    IN VARCHAR2,
        p_error_source     IN VARCHAR2,
        p_processing_status IN VARCHAR2 DEFAULT 'ERROR',
        p_user_name        IN VARCHAR2  DEFAULT NULL,
        p_error_code       IN VARCHAR2  DEFAULT NULL,
        p_report_url       IN VARCHAR2  DEFAULT NULL,
        p_http_status_code IN NUMBER    DEFAULT NULL,
        p_report_config_id IN NUMBER    DEFAULT NULL,
        p_settings_id      IN NUMBER    DEFAULT NULL
    );

    -- ────────────────────────────────────────────────────────
    -- Purge old log records
    -- ────────────────────────────────────────────────────────
    PROCEDURE purge_logs (
        p_days_to_keep     IN NUMBER DEFAULT 90
    );

END report_error_log_pkg;
/
