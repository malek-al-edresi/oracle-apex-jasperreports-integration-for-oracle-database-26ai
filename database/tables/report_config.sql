-- ══════════════════════════════════════════════════════════════
-- REPORT_CONFIG — Individual Report Definitions
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Defines individual report configurations, including the JRXML
--   file name, default parameters, and associated server settings.
--   Each row represents one report that can be generated via the
--   GET_REPORT procedure.
--
-- Usage:
--   Run as the application schema owner after creating REPORT_SETTINGS.
--
-- Parameters:
--   Parameter names and values are stored as semicolon-separated
--   strings for flexibility. Example:
--     PARAMETER_NAME:  'P_PATIENT_ID;P_DATE_FROM;P_DATE_TO'
--     PARAMETER_VALUE: '101;2026-01-01;2026-12-31'
-- ══════════════════════════════════════════════════════════════

CREATE TABLE report_config (
    id                NUMBER GENERATED ALWAYS AS IDENTITY
                      CONSTRAINT report_config_pk PRIMARY KEY,
    settings_id       NUMBER          NOT NULL
                      CONSTRAINT report_config_settings_fk 
                      REFERENCES report_settings (id),
    report_name       VARCHAR2(200)   NOT NULL,
    file_name         VARCHAR2(200)   NOT NULL,
    parameter_name    VARCHAR2(2000),
    parameter_value   VARCHAR2(2000),
    description       VARCHAR2(1000),
    is_active         VARCHAR2(1)     DEFAULT 'Y'
                      CONSTRAINT report_config_active_chk 
                      CHECK (is_active IN ('Y', 'N')),
    created_by        VARCHAR2(128)   DEFAULT USER,
    created_at        TIMESTAMP       DEFAULT SYSTIMESTAMP,
    updated_by        VARCHAR2(128),
    updated_at        TIMESTAMP
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX report_config_settings_idx 
    ON report_config (settings_id);

CREATE UNIQUE INDEX report_config_name_uk 
    ON report_config (report_name);

-- ── Comments ────────────────────────────────────────────────
COMMENT ON TABLE report_config IS 
    'Individual JasperReport definitions with default parameters';

COMMENT ON COLUMN report_config.id IS 
    'Auto-generated primary key';
COMMENT ON COLUMN report_config.settings_id IS 
    'FK to REPORT_SETTINGS — which server hosts this report';
COMMENT ON COLUMN report_config.report_name IS 
    'Human-readable report name (e.g., Patient Profile Report)';
COMMENT ON COLUMN report_config.file_name IS 
    'JRXML file name on the server without extension (e.g., patient_profile)';
COMMENT ON COLUMN report_config.parameter_name IS 
    'Semicolon-separated parameter names (e.g., P_PATIENT_ID;P_DATE_FROM)';
COMMENT ON COLUMN report_config.parameter_value IS 
    'Semicolon-separated default parameter values (e.g., 101;2026-01-01)';
COMMENT ON COLUMN report_config.description IS 
    'Optional description of the report purpose';
COMMENT ON COLUMN report_config.is_active IS 
    'Whether this report is active (Y/N)';
