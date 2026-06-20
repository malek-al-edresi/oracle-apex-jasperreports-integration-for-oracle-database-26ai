-- ══════════════════════════════════════════════════════════════
-- REPORT_LOG — Report Generation Audit & Error Log
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Records every report generation attempt, including successes,
--   failures, and error details. Used for auditing, debugging,
--   and monitoring report usage patterns.
--
-- Usage:
--   Run as the application schema owner.
--   Inserts are performed via REPORT_ERROR_LOG_PKG using
--   autonomous transactions so logs persist even on rollback.
--
-- Maintenance:
--   Consider partitioning by CREATED_AT for large-scale deployments.
--   Archive or purge records older than your retention policy.
-- ══════════════════════════════════════════════════════════════

CREATE TABLE report_log (
    id                 NUMBER GENERATED ALWAYS AS IDENTITY
                       CONSTRAINT report_log_pk PRIMARY KEY,
    log_level          VARCHAR2(20)    DEFAULT 'ERROR'
                       CONSTRAINT report_log_level_chk 
                       CHECK (log_level IN ('INFO', 'WARNING', 'ERROR', 'DEBUG')),
    error_message      VARCHAR2(4000),
    error_source       VARCHAR2(500),
    error_code         VARCHAR2(20),
    processing_status  VARCHAR2(50)    DEFAULT 'ERROR'
                       CONSTRAINT report_log_status_chk 
                       CHECK (processing_status IN ('PROCESSING', 'SUCCESS', 'ERROR', 'WARNING')),
    report_url         VARCHAR2(2000),
    http_status_code   NUMBER,
    report_config_id   NUMBER,
    settings_id        NUMBER,
    user_name          VARCHAR2(128)   DEFAULT USER,
    app_user           VARCHAR2(256),
    session_id         VARCHAR2(100),
    created_at         TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX report_log_created_idx 
    ON report_log (created_at DESC);

CREATE INDEX report_log_level_idx 
    ON report_log (log_level);

CREATE INDEX report_log_status_idx 
    ON report_log (processing_status);

CREATE INDEX report_log_user_idx 
    ON report_log (user_name);

-- ── Comments ────────────────────────────────────────────────
COMMENT ON TABLE report_log IS 
    'Audit trail and error log for all report generation attempts';

COMMENT ON COLUMN report_log.id IS 
    'Auto-generated primary key';
COMMENT ON COLUMN report_log.log_level IS 
    'Severity level: INFO, WARNING, ERROR, DEBUG';
COMMENT ON COLUMN report_log.error_message IS 
    'Error message text or success description';
COMMENT ON COLUMN report_log.error_source IS 
    'Source procedure and location where the event occurred';
COMMENT ON COLUMN report_log.error_code IS 
    'Oracle error code (e.g., ORA-29273) or HTTP status code';
COMMENT ON COLUMN report_log.processing_status IS 
    'Current processing state: PROCESSING, SUCCESS, ERROR, WARNING';
COMMENT ON COLUMN report_log.report_url IS 
    'Full URL used for the JasperReports REST call';
COMMENT ON COLUMN report_log.http_status_code IS 
    'HTTP response status code from JasperReports Server';
COMMENT ON COLUMN report_log.report_config_id IS 
    'Optional FK reference to REPORT_CONFIG.ID';
COMMENT ON COLUMN report_log.settings_id IS 
    'Optional FK reference to REPORT_SETTINGS.ID';
COMMENT ON COLUMN report_log.user_name IS 
    'Database user who generated the report';
COMMENT ON COLUMN report_log.app_user IS 
    'APEX application user (v(APP_USER))';
COMMENT ON COLUMN report_log.session_id IS 
    'APEX session ID for traceability';
