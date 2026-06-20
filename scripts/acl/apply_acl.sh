#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Apply JasperReports ACL Grants
# Runs grant_acl.sql via SQLcl inside the Docker network,
# then runs a quick connectivity test.
#
# Usage:
#   ./apply_acl.sh
#
# Environment Variables (set in .env or export before running):
#   DB_HOST           - Oracle DB hostname (default: oracle-db)
#   DB_PORT           - Oracle DB port (default: 1521)
#   DB_SERVICE        - PDB service name (default: FREEPDB1)
#   ORACLE_SYS_PASSWORD - SYS password (required)
#   DOCKER_NETWORK    - Docker network name (default: app-network)
# ══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load environment variables
if [[ -f "${ROOT_DIR}/docker/.env" ]]; then
    export $(grep -v '^#' "${ROOT_DIR}/docker/.env" | xargs)
fi

DB_HOST="${DB_HOST:-oracle-db}"
DB_PORT="${DB_PORT:-1521}"
DB_SERVICE="${DB_SERVICE:-FREEPDB1}"
DOCKER_NETWORK="${DOCKER_NETWORK:-jasper-network}"

SYS_PASSWORD="${ORACLE_SYS_PASSWORD:-}"

if [[ -z "${SYS_PASSWORD}" ]]; then
    echo "ERROR: ORACLE_SYS_PASSWORD is not set."
    echo "Set it in ${ROOT_DIR}/docker/.env or export it before running."
    exit 1
fi

TIMESTAMP="$(date +'%Y-%m-%dT%H:%M:%S%z')"

echo ""
echo "═══════════════════════════════════════════════════════"
echo " JasperReports ACL Grant"
echo " ${TIMESTAMP}"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Step 1: Apply ACL Grants ────────────────────────────────
echo "[1/2] Applying ACL grants..."

docker run --rm --network "${DOCKER_NETWORK}" \
    -v "${SCRIPT_DIR}:/scripts:ro" \
    --entrypoint /opt/oracle/sqlcl/bin/sql \
    container-registry.oracle.com/database/ords:latest \
    -s "sys/\"${SYS_PASSWORD}\"@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba" \
    @/scripts/grant_acl.sql

echo ""
echo "✓ ACL grants applied."

# ── Step 2: Connectivity Test ───────────────────────────────
echo ""
echo "[2/2] Testing HTTP connectivity to JasperReports from Oracle DB..."
echo ""

docker run --rm --network "${DOCKER_NETWORK}" \
    -v "${SCRIPT_DIR}:/scripts:ro" \
    --entrypoint /opt/oracle/sqlcl/bin/sql \
    container-registry.oracle.com/database/ords:latest \
    -s "sys/\"${SYS_PASSWORD}\"@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba" \
    @/scripts/test_connectivity.sql

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Complete — $(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "═══════════════════════════════════════════════════════"
echo ""
