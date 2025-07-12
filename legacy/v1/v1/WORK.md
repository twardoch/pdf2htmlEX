# Current Work Status

## Overall Goal
Create a robust and maintainable Homebrew formula for pdf2htmlEX on macOS, resolving v1 build failures.

## Key Knowledge
- pdf2htmlEX requires specific, older versions of Poppler (24.01.0) and FontForge (20230101) with static linking.
- v1 failed due to DCTStream compilation errors in Poppler (when JPEG was disabled) and linker errors with various libraries (NSS, GpgME, FreeType, Fontconfig, Little CMS, OpenJPEG, bzip2).
- v2 strategy: Vendor and statically build libjpeg-turbo, explicitly link all necessary libraries to Poppler, disable NSS and GpgME in Poppler, and use an in-source build pattern for pdf2htmlEX.
- The local build script (`v2/scripts/build.sh`) is being used for validation.
- `jpeg-turbo` requires separate builds for x86_64 and arm64, then `lipo` to create a universal binary.

## Recent Actions
- Corrected `libjpeg-turbo` download URL in formula and build script.
- Implemented separate `jpeg-turbo` builds for x86_64 and arm64, followed by `lipo` to create a universal library.
- Disabled `NSS` and `GpgME` in Poppler build.
- Explicitly linked FreeType, Fontconfig, libpng, Little CMS, OpenJPEG, zlib, and bzip2 to the Poppler build.
- Encountered and debugging a shell syntax error in `v2/scripts/build.sh` on line 84.

## Current Plan
1. [IN PROGRESS] Debug and fix the shell syntax error in `v2/scripts/build.sh` on line 84.
2. [TODO] Re-run `./v2/scripts/build.sh` to validate the local build.
3. [TODO] Proceed with Phase 2: Homebrew Formula Integration, once local build is successful.
4. [TODO] Proceed with Phase 3: CI/CD and Bottling, once Homebrew integration is successful.
