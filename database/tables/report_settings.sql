-- ══════════════════════════════════════════════════════════════
-- REPORT_SETTINGS — JasperReports Server Connection Settings
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Stores connection details for one or more JasperReports Server
--   instances. Each row represents a server configuration that the
--   GET_REPORT procedure uses to construct REST API URLs and
--   authenticate against JasperReports.
--
-- Usage:
--   Run as the application schema owner.
--
-- Security:
--   Passwords are stored in this table for simplicity in this example.
--   In production, consider using Oracle Wallet, APEX Web Credentials,
--   or DBMS_CREDENTIAL for secure credential storage.
-- ══════════════════════════════════════════════════════════════

CREATE TABLE report_settings (
    id                   NUMBER GENERATED ALWAYS AS IDENTITY
                         CONSTRAINT report_settings_pk PRIMARY KEY,
    setting_name         VARCHAR2(100)   NOT NULL,
    hostname             VARCHAR2(200)   NOT NULL,
    port                 VARCHAR2(10)    DEFAULT '8080',
    protocol             VARCHAR2(10)    DEFAULT 'http'
                         CONSTRAINT report_settings_protocol_chk 
                         CHECK (protocol IN ('http', 'https')),
    username             VARCHAR2(100)   NOT NULL,
    password             VARCHAR2(100)   NOT NULL,
    base_report_path     VARCHAR2(500)   DEFAULT '/',
    content_disposition  VARCHAR2(50)    DEFAULT 'attachment'
                         CONSTRAINT report_settings_disp_chk 
                         CHECK (content_disposition IN ('attachment', 'inline')),
    is_active            VARCHAR2(1)     DEFAULT 'Y'
                         CONSTRAINT report_settings_active_chk 
                         CHECK (is_active IN ('Y', 'N')),
    created_by           VARCHAR2(128)   DEFAULT USER,
    created_at           TIMESTAMP       DEFAULT SYSTIMESTAMP,
    updated_by           VARCHAR2(128),
    updated_at           TIMESTAMP
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE UNIQUE INDEX report_settings_name_uk 
    ON report_settings (setting_name);

-- ── Comments ────────────────────────────────────────────────
COMMENT ON TABLE report_settings IS 
    'JasperReports Server connection configuration';

COMMENT ON COLUMN report_settings.id IS 
    'Auto-generated primary key';
COMMENT ON COLUMN report_settings.setting_name IS 
    'Human-readable name for this server configuration (e.g., Production, Development)';
COMMENT ON COLUMN report_settings.hostname IS 
    'JasperReports Server hostname or IP address (e.g., jasper-server, 192.168.1.100)';
COMMENT ON COLUMN report_settings.port IS 
    'Server port number (default: 8080). Set to NULL or 443 for default HTTPS';
COMMENT ON COLUMN report_settings.protocol IS 
    'Connection protocol: http or https';
COMMENT ON COLUMN report_settings.username IS 
    'JasperReports Server authentication username';
COMMENT ON COLUMN report_settings.password IS 
    'JasperReports Server authentication password';
COMMENT ON COLUMN report_settings.base_report_path IS 
    'Base folder path for reports on the server (e.g., /reports/medical/)';
COMMENT ON COLUMN report_settings.content_disposition IS 
    'HTTP Content-Disposition: attachment (download) or inline (view in browser)';
COMMENT ON COLUMN report_settings.is_active IS 
    'Whether this configuration is active (Y/N)';
