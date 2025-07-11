# WORK.md

## 2025-07-10 – Iteration 1

Context: `/work` command invoked.

### Completed in this iteration

* Implemented automatic source-archive download logic in `v2/scripts/build.sh` so the script is now fully self-contained.  Versions are declared once at the top and kept in sync with `update-version.sh`.
* Marked all Phase 1 build tasks as complete in `TODO.md`.

### Next immediate targets

1. Phase 1 – Validation
   * Run `v2/scripts/build.sh` on a macOS host to confirm the build finishes and produces a universal, statically-linked binary.
   * Capture the `file` and `otool -L` output and add automated checks (where feasible) to the script.
2. Phase 2 – Formula polishing
   * Double-check the SHA256 of the vendored resources in `v2/Formula/pdf2htmlex.rb` now that we switched jpeg-turbo URL to GitHub.
   * Finish the `brew audit --strict` compliance (style, license, livecheck etc.).
3. CI/CD groundwork
   * Copy and adapt `.github/workflows` from `v1` → `v2` to get basic test coverage running.

### Carry-over

* Remaining Phase 1 validation tasks and all subsequent phases stay open in `TODO.md`.

