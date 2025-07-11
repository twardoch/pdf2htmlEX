# WORK.md

## 2025-07-11 – Iteration 2

Objective: Continue /work cycle – review TODO & PLAN, reflect, refine.

### Actions performed in this iteration

1. Updated `TODO.md` – phased out completed items under Formula Creation and GitHub Actions setup.
2. Adjusted `.github/workflows/*` files to reference the **v2** formula path:
   * `test.yml` – audit/install/test steps now point to `v2/Formula/pdf2htmlex.rb` and cache key updated.
   * `release.yml` – release instructions and build-bottle job updated.
   * `security.yml` – formula audit checks updated.
3. Re-created `release.yml` after an accidental overwrite.

### Next immediate targets (queued for next iteration)

1. Add explicit **dependency caching** step to the `test.yml` workflow (Homebrew downloads already cached; consider ccache for C/C++).
2. Compose `v2/README.md` detailing the v2 build strategy.
3. Enhance formula test block if `brew audit --strict` indicates missing checks.

---

## 2025-07-11 – Iteration 4

Objective: Implement the immediate targets from Iteration 2 and keep refining docs & CI.

### Actions performed in this iteration

1. **Dependency caching**
   * Added a dedicated *ccache* installation / configuration step to `.github/workflows/test.yml`.
   * Added a second `actions/cache@v3` block targeting `~/.cache/ccache` keyed by architecture and formula hash.
2. **Workflow enhancements**
   * Extended formula test step to run an additional `pdf2htmlEX --version` runtime check.
3. **Documentation & tracking**
   * Marked `Add dependency caching to speed up CI builds`, `Create v2/README.md`, and `Create v2/scripts/update-version.sh` as complete in `TODO.md`.
   * Updated `WORK.md` with current iteration details.

### Next immediate targets (queued for next iteration)

Immediate focus for next iteration (Iteration 5):

1. Add small JPEG-containing `sample.pdf` to `testdata/` and hook it into build script functional test.
2. Begin porting build logic into `v2/Formula/pdf2htmlex.rb` (Phase 2).
3. Expand README/docs to cover local builder usage & troubleshooting.
