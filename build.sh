#!/usr/bin/env bash
# this_file: build.sh

# ----------------------------------------------------------------------------
# Top-level build orchestrator for the pdf2htmlEX repo.
# ----------------------------------------------------------------------------
# The script sequentially runs the existing per-version build helpers:
#   • v1/build.sh              – Homebrew based “Strategy 1” builder
#   • v2/scripts/build.sh      – Stand-alone universal binary builder
#
# For each sub-build we capture stdout and stderr **separately** under the
#   build_logs/  directory at repo root so CI or developers can inspect them
# afterwards.
#
# At the very end the script prints the absolute paths of the four log files so
# callers know where to look.
# ----------------------------------------------------------------------------

set -euo pipefail

llms . "Unicode*.h,NameTo*.h,*.,*.html,Changelog*,ChangeLog*,*.c,*.cc,*.cpp,*.devhelp2,*.gperf,NEWS*,*.1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${ROOT_DIR}/build_logs"
mkdir -p "${LOG_DIR}"

# Helper to run a build script with separate stdout/stderr capture.
run_build() {
  local label="$1" script_path="$2"
  local out_log="${LOG_DIR}/${label}_out.txt"
  local err_log="${LOG_DIR}/${label}_err.txt"

  echo "==> Starting build: ${label} (logs -> ${out_log}, ${err_log})"

  # -------------------------------------------------------------------------
  # We deliberately guard the sub-build execution with an `if …; then` block
  # rather than executing it as a bare command.  With `set -e` enabled the
  # script would terminate immediately when the sub-build returns a non-zero
  # exit code, preventing subsequent builds from running and obscuring the
  # location of the captured log files.  The `if` conditional counts as a
  # tested command so the `-e` safety check is suppressed, allowing us to
  # continue, record the failure and report it at the very end.
  # -------------------------------------------------------------------------
  if bash "${script_path}" 1>"${out_log}" 2>"${err_log}"; then
    return 0
  else
    local exit_code=$?
    echo "[error] Build '${label}' failed with status ${exit_code}. See logs above." >&2
    return ${exit_code}
  fi
}

build_failure=0

# -----------------------------------------------------------------------------
# Build V1 (Homebrew Formula approach)
# -----------------------------------------------------------------------------
if [[ -f "${ROOT_DIR}/v1/build.sh" ]]; then
  run_build "v1" "${ROOT_DIR}/v1/build.sh" || build_failure=1
else
  echo "[skip] v1/build.sh not found – skipping v1 build" >&2
fi

# -----------------------------------------------------------------------------
# Build V2 (stand-alone universal binary script)
# -----------------------------------------------------------------------------
if [[ -f "${ROOT_DIR}/v2/scripts/build.sh" ]]; then
  run_build "v2" "${ROOT_DIR}/v2/scripts/build.sh" || build_failure=1
else
  echo "[skip] v2/scripts/build.sh not found – skipping v2 build" >&2
fi

# -----------------------------------------------------------------------------
# Finish
# -----------------------------------------------------------------------------

echo ""
echo "-------------------------------------------------------------"
echo "Build complete. Log files written to:"
echo "  V1 stdout:   ${LOG_DIR}/v1_out.txt"
echo "  V1 stderr:   ${LOG_DIR}/v1_err.txt"
echo "  V2 stdout:   ${LOG_DIR}/v2_out.txt"
echo "  V2 stderr:   ${LOG_DIR}/v2_err.txt"
echo "-------------------------------------------------------------"

exit ${build_failure}
