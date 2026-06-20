-- ══════════════════════════════════════════════════════════════
-- FILE_TYPE_LOOKUP — Supported Report Output Formats
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Lookup table for supported report output file types.
--   Used by GET_REPORT to validate the requested output format
--   and determine the correct MIME type for HTTP response headers.
--
-- Usage:
--   Run as the application schema owner.
-- ══════════════════════════════════════════════════════════════

CREATE TABLE file_type_lookup (
    id            NUMBER GENERATED ALWAYS AS IDENTITY
                  CONSTRAINT file_type_lookup_pk PRIMARY KEY,
    file_type     VARCHAR2(20)    NOT NULL,
    mime_type     VARCHAR2(100)   NOT NULL,
    description   VARCHAR2(200),
    is_active     VARCHAR2(1)     DEFAULT 'Y'
                  CONSTRAINT file_type_active_chk 
                  CHECK (is_active IN ('Y', 'N'))
);

-- ── Unique Index ────────────────────────────────────────────
CREATE UNIQUE INDEX file_type_lookup_type_uk 
    ON file_type_lookup (file_type);

-- ── Seed Data ───────────────────────────────────────────────
INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('pdf',  'application/pdf',                          'PDF Document');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'Excel Spreadsheet');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('xls',  'application/vnd.ms-excel',                 'Excel Spreadsheet (Legacy)');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('csv',  'text/csv',                                 'Comma-Separated Values');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'Word Document');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('html', 'text/html',                                'HTML Document');

INSERT INTO file_type_lookup (file_type, mime_type, description) 
VALUES ('xml',  'application/xml',                          'XML Document');

COMMIT;

-- ── Comments ────────────────────────────────────────────────
COMMENT ON TABLE file_type_lookup IS 
    'Supported JasperReports output formats and their MIME types';

COMMENT ON COLUMN file_type_lookup.file_type IS 
    'File extension without dot (e.g., pdf, xlsx, csv)';
COMMENT ON COLUMN file_type_lookup.mime_type IS 
    'HTTP Content-Type MIME string for this format';
COMMENT ON COLUMN file_type_lookup.description IS 
    'Human-readable format description';
