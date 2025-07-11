# pdf2htmlEX ‑ macOS Build & Porting SPEC

this_file: v2/SPEC.md

## 0. Goals

1. Produce a **self-contained, repeatable macOS build** of `pdf2htmlEX` that
   works on both Intel and Apple-Silicon Macs (macOS 11+).
2. **Stick to the canonical upstream dependency matrix** confirmed to build by
   the original `buildScripts` (Poppler 24.01.0, FontForge 20230101, jpeg-turbo 3.0.2).
3. Keep the build 100 % offline-reproducible: all third-party tarballs live in
   `v2/vendor/` and are **never** downloaded during CI.
4. Provide a crystal-clear patch / build story so a future Homebrew formula can
   just `cp` the patches, run the script and ship.

## 1. High-Level Strategy

```
┌────────────────────┐  stage 1   ┌───────────────┐
│ jpeg-turbo 3.0.2   │──────────►│  libjpeg.a    │
└────────────────────┘            └───────────────┘
┌────────────────────┐  stage 2   ┌───────────────┐
│  Poppler 24.01.0   │──────────►│ libpoppler*.a │
└────────────────────┘            └───────────────┘
┌────────────────────┐  stage 3   ┌───────────────┐
│FontForge 20230101  │──────────►│ libfontforge.a│
└────────────────────┘            └───────────────┘
┌────────────────────┐  stage 4   ┌───────────────┐
│  pdf2htmlEX rc2    │──────────►│  pdf2htmlEX   │
└────────────────────┘            └───────────────┘
```

Everything installs **statically** into `$STAGING_DIR` and is copied into the
expected in-source layout that the original pdf2htmlEX `CMakeLists.txt` uses.


## 2. Problems to Solve & Patches Needed

### 2.1 Build-system / Environment

| Area | Problem | Fix |
|------|---------|-----|
| Vendor cache | Script currently downloads tarballs on every run (bad for CI/offline) | Introduce `VENDOR_DIR` (done) and wire all `download_sources`+`extract` calls to it. |
| Universal binary | Need `-DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"` but some libs (jpeg-turbo) can’t cross-build in one go | Build for host arch only; rely on CI matrix to merge later. |
| `libintl.h` missing | macOS doesn’t ship gettext headers and we disable NLS | Provide tiny **stub header** in staging/include (done). |
| C++ standard | Poppler ≥23 uses `std::optional`, `shared_ptr` | Pass `-DCMAKE_CXX_STANDARD=17` when configuring pdf2htmlEX (done). |

### 2.2 FontForge Headers

FontForge installs **two** distinct header trees:

1. `fontforge/` — auto-generated from sources
2. `inc/` — hand-written public API (`basics.h`, etc.)

pdf2htmlEX requires both *and* expects a duplicate copy under
`fontforge/build/inc`.  Our script now copies:

* `$STAGING/include/fontforge/**`  → `../fontforge/fontforge/`
* `$STAGING/include/fontforge/fontforge-config.h` → same dir
* `inc/*.h` from source tree → `../fontforge/inc` and `../fontforge/build/inc`


### 2.3 Poppler API Breakage (24 → 0.89-era code)

Even in rc2 there are still a few compilation errors:

* `OutlineItem::close()` → now `OutlineItem::open` boolean; need to
  wrap with `#if POPPLER_VERSION…` or remove entirely.
* `LinkDest::copy()` removed – use copy-ctor or manual `std::make_unique`.
* Many `GfxFont*` raw pointers replaced by `std::shared_ptr<GfxFont>`.
* `Form::getCheckedSignature` returns `std::optional`.

**Plan**: Upstream master already fixed all of these (confirmed 2024-04-18
commit).  Instead of back-porting patches, we’ll vendor the **current master
snapshot** (call it 0.18.9-dev) into `v2/vendor/pdf2htmlEX-master.tar.gz`.


### 2.4 macOS-specific linker flags

* Need `-framework CoreFoundation` transitively via cairo/freetype – but static
  linking pulls them automatically.  Verify with `otool -L`.
* Ensure `-headerpad_max_install_names` when building static libs (harmless).


## 3. Implementation Plan (Iteration Checklist)

1. **Vendor tarballs**
   * jpeg-turbo-3.0.2.tar.gz  ✅
   * poppler-24.01.0.tar.xz   ✅
   * fontforge-20230101.tar.gz ✅
   * pdf2htmlEX-master.tar.gz ☐  (create from v1/archive/pdf2htmlEX head)

2. **Script fixes**  (most done)
   * Vendor dir logic  ✅
   * Header stubs / copies ✅
   * Auto-detect pdf2htmlEX source dir ✅

3. **Source-level patches** (WIP)
   * Replace Poppler API uses or switch to master tarball.
   * Add `#include <optional>` where needed.

4. **Compile loop**
   * `./v2/scripts/build.sh` → iterate until `dist/bin/pdf2htmlEX` exists.

5. **Runtime verification**
   * `dist/bin/pdf2htmlEX --version`
   * Convert sample PDF & open output in Safari / Chrome.

6. **Homebrew Formula draft** (out-of-scope for now – record steps).


## 4. Reproducing on CI / Homebrew Later

1. `git clone pdf2htmlEX-mac && cd pdf2htmlEX-mac`
2. `brew install cmake ninja pkg-config cairo freetype fontconfig libpng libtiff libxml2 pango harfbuzz little-cms2 openjpeg`
3. `./v2/scripts/build.sh`
4. Profit – binary at `v2/dist/bin/pdf2htmlEX`.


## 5. Open Items / Risks

* Verifying that FontForge static build really doesn’t access gettext at
  runtime; our stub is compile-time only.
* Universal binary merging (lipo) deferred.
* Poppler’s static link size (~40 MB) – may need `-Os -g0`.

