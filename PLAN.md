# MVP v1.0 Streamlining Plan for pdf2htmlEX Homebrew Formula

## 1. Project Setup and Pre-flight Checks

*   **1.1. Update Local Repository:** Ensure the local environment has the latest version of the repository. (Assumed done by the platform)
*   **1.2. Review Existing `AGENTS.md`:** Re-familiarize with guidelines, especially regarding build processes and testing. (Agent action)
*   **1.3. Initial `ls` and File Check:** List all files to ensure no unexpected items interfere with the plan. (Agent action, already partially done)

## 2. Core Formula (`Formula/pdf2htmlex.rb`) Refinement

*   **2.1. Fetch and Verify Dependency URLs and Tarball Structures:**
    *   `pdf2htmlEX`: `https://github.com/pdf2htmlEX/pdf2htmlEX/archive/refs/tags/v0.18.8.rc1.tar.gz`
    *   `Poppler`: `https://poppler.freedesktop.org/poppler-24.01.0.tar.xz`
    *   `FontForge`: `https://github.com/fontforge/fontforge/archive/refs/tags/20230101.tar.gz`
    *   Confirm the top-level directory name inside each archive after extraction.
*   **2.2. Calculate and Update SHA256 Checksums:**
    *   Compute SHA256 for `pdf2htmlEX-v0.18.8.rc1.tar.gz`.
    *   Compute SHA256 for `poppler-24.01.0.tar.xz`.
    *   Compute SHA256 for `fontforge-20230101.tar.gz`.
    *   Replace placeholder SHA256 values in `Formula/pdf2htmlex.rb` with the correct ones.
*   **2.3. Correct Directory Navigation in Formula:**
    *   Verify and correct the `cd` command for the main `pdf2htmlEX` source. Change `cd buildpath/name do` to `cd "pdf2htmlEX-#{version}" do` (or equivalent, based on actual extraction name confirmed in 2.1). The subsequent `cd "pdf2htmlEX" do` should then correctly point to the sources.
*   **2.4. Review CMake Flags:**
    *   Cross-check CMake flags in the formula against `AGENTS.md` and `build_prototype.sh` (once it's decided upon) for consistency in disabling GUI, tests, and enabling static builds for Poppler and FontForge. Ensure necessary features like Splash for Poppler are enabled.
*   **2.5. Verify `JAVA_HOME` setup:** Ensure `ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix` is correctly setting up Java for the build scripts within `pdf2htmlEX`.

## 3. Build Script (`build_prototype.sh`) Management

*   **3.1. Decision and Relocation:**
    *   Confirm its utility as a local development/debug script.
    *   Rename to `test-build.sh` and move to a new `scripts/` directory.
*   **3.2. Align with Formula:**
    *   Ensure dependency versions (Poppler, FontForge) match the formula.
    *   Update `%%HOMEBREW_PREFIX%%` placeholder with `$(brew --prefix)` or add a clear comment that it needs to be set by the user.
    *   Add comments about the manual requirement of Poppler/FontForge source directories or script fetching them.
*   **3.3. Create `scripts/` directory:** If it doesn't exist.

## 4. Documentation Streamlining

*   **4.1. `README.md` Overhaul:**
    *   Focus on MVP: Project goal, clear installation (local clone method), basic usage.
    *   Move "Repository Reorganization Plan" to `ROADMAP.md`.
    *   Move "Improvement Notes" to `ROADMAP.md`.
    *   Move detailed "Contribution Guidelines" to `CONTRIBUTING.md` (overwriting existing content). Link to `CONTRIBUTING.md` from `README.md`.
*   **4.2. Create `ROADMAP.md`:**
    *   Populate with content removed from `README.md` (Repository Reorganization Plan, Improvement Notes). Add a brief intro stating these are future plans.
*   **4.3. Update `CONTRIBUTING.md`:**
    *   Replace existing generic content with the detailed "Contribution Guidelines" from `README.md`. Streamline slightly if parts are overly verbose for an initial contribution guide.
*   **4.4. `AGENTS.md`:** No changes, use as a guide.
*   **4.5. `reference/reference.md`:** Mark for deletion.
*   **4.6. `CLAUDE.md`:** Review briefly. If it's purely alternative agent instructions and `AGENTS.md` is primary, consider removing `CLAUDE.md` or archiving it to avoid confusion. For MVP, prioritize one set of agent instructions. (Decision: remove if redundant after review).

## 5. Auxiliary Files and Cleanup

*   **5.1. `patches/formula-enhancements.patch`:**
    *   Read the patch file.
    *   If applied or obsolete, delete it.
    *   If relevant and unapplied, assess for MVP and apply to `Formula/pdf2htmlex.rb`.
*   **5.2. `.github/workflows/test.yml`:**
    *   Ensure it uses `Formula/pdf2htmlex.rb` (adjust path if repo structure changes, though formula path itself shouldn't).
    *   Verify it runs `brew install --build-from-source`, `brew test`, and `brew audit --strict`.
*   **5.3. Other `.github/workflows/` (`release.yml`, `security.yml`):**
    *   Review. If complex or not functional for MVP (e.g., bottling), simplify, temporarily disable, or remove.
*   **5.4. Other Files:**
    *   `docs/progress-report.md`, `docs/refactoring-summary.md`: Move to `archive/docs_archive/` or delete.
    *   `issues/issue103.txt`: Review; if resolved or irrelevant, move to `archive/issues_archive/` or delete.
    *   `Makefile` (if one exists at project root and is not upstream): Evaluate, likely remove if not for this project's direct build.
*   **5.5. Create `.gitignore` entries if needed:** For `archive/` or other generated files not meant for commit (though archives are usually committed if they are for historical reasons).

## 6. `CHANGELOG.md` and `TODO.md` Management

*   **6.1. `CHANGELOG.md`:**
    *   Add a new section for "MVP v1.0 Streamlining".
    *   Log all significant changes made during this process (e.g., "Updated formula with correct SHA256s", "Streamlined README.md", "Moved future plans to ROADMAP.md").
*   **6.2. `TODO.md`:**
    *   Overwrite the existing `TODO.md` with the new checklist generated from this plan.

## 7. Build and Test

*   **7.1. Local Formula Build:**
    *   Run `brew install --build-from-source Formula/pdf2htmlex.rb`. Debug any issues.
*   **7.2. Run Homebrew Test Suite:**
    *   Run `brew test pdf2htmlex`. Debug any issues.
*   **7.3. (If `scripts/test-build.sh` is kept) Run Prototype Script:**
    *   Execute `scripts/test-build.sh`. Debug any issues.
*   **7.4. Universal Binary Verification (Manual):**
    *   If on appropriate hardware, use `lipo -info $(brew --prefix pdf2htmlex)/bin/pdf2htmlEX` to check architectures.
*   **7.5. Basic Conversion Test (Manual):**
    *   Convert a simple PDF using the installed `pdf2htmlEX` and verify the output HTML.

## 8. Final Review and Commit

*   **8.1. Review Changes:** Diff all modified files.
*   **8.2. Validate `PLAN.md` and `TODO.md`:** Ensure all items are addressed and marked complete.
*   **8.3. Validate `CHANGELOG.md`:** Ensure it's comprehensive for the work done.
*   **8.4. Submit:** Commit changes with a clear message.

This constitutes `PLAN.md`.
Now, `TODO.md`:
