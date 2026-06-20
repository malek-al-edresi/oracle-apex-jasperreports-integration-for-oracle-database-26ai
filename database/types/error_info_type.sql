-- ══════════════════════════════════════════════════════════════
-- Error Info Type — Object Type for Structured Error Logging
-- ══════════════════════════════════════════════════════════════
--
-- Purpose:
--   Provides a reusable PL/SQL object type for capturing structured
--   error information during report generation and file processing.
--
-- Usage:
--   Run as the application schema owner.
--
--   DECLARE
--       l_error  error_info_type := error_info_type(NULL, NULL, 'PROCESSING', USER);
--   BEGIN
--       ...
--   EXCEPTION
--       WHEN OTHERS THEN
--           l_error.error_message := SQLERRM;
--           l_error.error_source  := 'MY_PROCEDURE';
--           l_error.processing_status := 'ERROR';
--   END;
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE TYPE error_info_type AS OBJECT (
    error_message       VARCHAR2(4000),    -- Error message text (SQLERRM)
    error_source        VARCHAR2(500),     -- Source procedure/location
    processing_status   VARCHAR2(50),      -- PROCESSING | ERROR | SUCCESS
    user_name           VARCHAR2(128)      -- Database or APEX user
);
/

COMMENT ON TYPE error_info_type IS 
    'Structured error information object for report generation logging';
