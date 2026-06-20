-- ══════════════════════════════════════════════════════════════
-- Master Installation Script
-- Oracle APEX + JasperReports Integration
-- ══════════════════════════════════════════════════════════════
--
-- This script installs all database objects in the correct order.
--
-- Prerequisites:
--   1. Oracle Database 23ai/26ai with PDB configured
--   2. Oracle APEX installed
--   3. An application schema created and APEX workspace configured
--
-- Usage:
--   Step 1 — Run as SYSDBA (security setup):
--     sqlplus sys/password@//host:1521/FREEPDB1 as sysdba
--     @scripts/acl/grant_acl.sql
--
--   Step 2 — Run as Application Schema Owner:
--     sqlplus your_schema/password@//host:1521/FREEPDB1
--     @install/install_all.sql
--
--   Or run this master script (adjust connection as needed):
--     @install/install_all.sql
-- ══════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET FEEDBACK ON
WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT ════════════════════════════════════════════════════════
PROMPT  Oracle APEX + JasperReports Integration — Installation
PROMPT ════════════════════════════════════════════════════════
PROMPT

-- ── Step 1: Tables ──────────────────────────────────────────
PROMPT [1/4] Creating tables...
@../database/types/error_info_type.sql
@../database/tables/report_settings.sql
@../database/tables/report_config.sql
@../database/tables/report_log.sql
@../database/tables/file_type_lookup.sql

-- ── Step 2: Packages ────────────────────────────────────────
PROMPT [2/4] Creating packages...
@../packages/report_error_log_pkg.pks
@../packages/report_error_log_pkg.pkb
@../packages/jasper_report_pkg.pks
@../packages/jasper_report_pkg.pkb

-- ── Step 3: Sample Data ─────────────────────────────────────
PROMPT [3/4] Inserting sample data...
@../database/seed/sample_data.sql

-- ── Step 4: Verify ──────────────────────────────────────────
PROMPT [4/4] Verifying installation...

SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN (
     'REPORT_SETTINGS', 'REPORT_CONFIG', 'REPORT_LOG',
     'FILE_TYPE_LOOKUP', 'ERROR_INFO_TYPE',
     'JASPER_REPORT_PKG', 'REPORT_ERROR_LOG_PKG'
 )
 ORDER BY object_type, object_name;

PROMPT
PROMPT ════════════════════════════════════════════════════════
PROMPT  ✓ Installation Complete
PROMPT
PROMPT  Next Steps:
PROMPT    1. Run ACL grants as SYSDBA:
PROMPT       @scripts/acl/grant_acl.sql
PROMPT    2. Update REPORT_SETTINGS with your JasperReports
PROMPT       server connection details
PROMPT    3. Test connectivity:
PROMPT       EXEC jasper_report_pkg.test_connection(1);
PROMPT ════════════════════════════════════════════════════════
PROMPT
