#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Oracle Database Health Check Script
# Used by Docker Compose healthcheck to verify DB readiness.
# ══════════════════════════════════════════════════════════════

ORACLE_SID="${ORACLE_SID:-FREE}"
ORACLE_HOME="${ORACLE_HOME:-/opt/oracle/product/23ai/dbhomeFree}"
PATH="${ORACLE_HOME}/bin:${PATH}"

# Check if the PDB is open in READ WRITE mode
sqlplus -s / as sysdba <<'EOF' | grep -q "READ WRITE"
SET HEADING OFF FEEDBACK OFF PAGES 0
SELECT open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
EXIT;
EOF
