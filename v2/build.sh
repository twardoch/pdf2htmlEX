#!/usr/bin/env bash
# this_file: v2/build.sh

# ----------------------------------------------------------------------------
# pdf2htmlEX v2 Build Wrapper
# ----------------------------------------------------------------------------
# This is a thin wrapper around scripts/build.sh that handles logging.
# All build logic is in scripts/build.sh - this just provides:
#   • stdout → build.log.txt
#   • stderr → build.err.txt
#   • Exit code propagation
# ----------------------------------------------------------------------------

set -euo pipefail

# Get the directory where this script is located
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define log files
readonly LOG_FILE="${SCRIPT_DIR}/build.log.txt"
readonly ERR_FILE="${SCRIPT_DIR}/build.err.txt"

# Ensure scripts/build.sh exists
if [[ ! -f "${SCRIPT_DIR}/scripts/build.sh" ]]; then
    echo "Error: scripts/build.sh not found" >&2
    exit 1
fi

# Print what we're doing
echo "Starting pdf2htmlEX v2 build..."
echo "Logs:"
echo "  stdout → ${LOG_FILE}"
echo "  stderr → ${ERR_FILE}"
echo ""

# Run the actual build script with logging
exec "${SCRIPT_DIR}/scripts/build.sh" \
    > "${LOG_FILE}" \
    2> "${ERR_FILE}"
