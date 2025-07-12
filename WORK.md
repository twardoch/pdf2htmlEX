# WORK.md

## 2025-07-12 – Build Issues Resolution

Objective: Fix build issues in both v1 and v2 approaches

### Actions performed in this iteration

1. **v2 Build Fixes**
   * Fixed CMake boolean case sensitivity issue - changed `PNG_INTEL_SSE=OFF` to `PNG_INTEL_SSE=off` 
   * Disabled WebP support in libtiff (`-Dwebp=OFF`) to avoid libsharpyuv linking issues
   * Disabled OpenJPEG tools (`-DBUILD_CODEC=OFF`) to prevent libtiff linking errors
   * Removed dynamic libraries (.dylib) to force static linking
   * Successfully built: libjpeg-turbo, libpng, libgif, libdeflate, libwebp, libtiff, openjpeg

2. **v1 Formula Fixes**
   * Updated regex patterns in formula to match actual source code
   * Fixed font->getName() pattern to handle ternary operator without parentheses
   * Removed unused patterns for localfontloc conditionals
   * Added pattern to handle `delete localfontloc` statements

### Issues Found

1. **v2 build**: lcms2 configure fails for arm64 with "cannot run C compiled programs"
2. **v1 formula**: Some inreplace regex patterns still don't match source code exactly
3. **Dynamic linking**: CMake was preferring .dylib files over .a files

### Next immediate targets

1. Fix lcms2 arm64 cross-compilation (add --host=arm64-apple-darwin flag)
2. Complete v2 build after lcms2 fix
3. Create proper patch files for v1 instead of complex regex patterns
4. Test final binaries on both x86_64 and arm64 architectures
5. Update documentation with successful build instructions

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

---

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