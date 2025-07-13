#!/usr/bin/env bash
# this_file: build.sh

# ----------------------------------------------------------------------------
# Top-level build wrapper for the pdf2htmlEX repo.
# ----------------------------------------------------------------------------
# This is a thin wrapper that calls scripts/build.sh and redirects:
#   • stdout to build.log.txt
#   • stderr to build.err.txt
#
# The actual build logic is in scripts/build.sh
# ----------------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/build.sh"
LOG_FILE="${ROOT_DIR}/build.log.txt"
ERR_FILE="${ROOT_DIR}/build.err.txt"

echo "==> Starting build (logs -> ${LOG_FILE}, ${ERR_FILE})"

# Execute the main build script with output redirection
bash "${SCRIPT_PATH}" 1>"${LOG_FILE}" 2>"${ERR_FILE}"
build_exit_code=$?

echo ""
echo "-------------------------------------------------------------"
echo "Build complete. Log files written to:"
echo "  stdout:   ${LOG_FILE}"
echo "  stderr:   ${ERR_FILE}"
echo "-------------------------------------------------------------"
ding
exit ${build_exit_code}
