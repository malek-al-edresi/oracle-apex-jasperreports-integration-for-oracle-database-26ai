#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Sync JasperReports Grants — Shell Wrapper
# Runs sync_jasper_grants.sql via SQLcl inside Docker.
#
# Usage:
#   ./sync_jasper_grants.sh
#
# Environment Variables:
#   DB_HOST              - Oracle DB hostname (default: oracle-db)
#   DB_PORT              - Oracle DB port (default: 1521)
#   DB_SERVICE           - PDB service name (default: FREEPDB1)
#   ORACLE_SYS_PASSWORD  - SYS password (required)
#   DOCKER_NETWORK       - Docker network name (default: jasper-network)
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
    exit 1
fi

echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] Starting JasperReports Grant Synchronization..."

docker run --rm --network "${DOCKER_NETWORK}" \
    -v "${SCRIPT_DIR}:/scripts:ro" \
    --entrypoint /opt/oracle/sqlcl/bin/sql \
    container-registry.oracle.com/database/ords:latest \
    -s "sys/\"${SYS_PASSWORD}\"@//${DB_HOST}:${DB_PORT}/${DB_SERVICE} as sysdba" \
    @/scripts/sync_jasper_grants.sql

echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] Grant synchronization completed."
