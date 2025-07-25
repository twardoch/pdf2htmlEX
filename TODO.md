# TODO.md

## Phase 1: Fix Critical Build Infrastructure (✅ **COMPLETED**)
- [x] 🔧 **Fix framework linker arguments** - Added sed fix for .pc files
- [x] 🔧 **Fix fontconfig curl command** - Corrected config.sub download
- [x] 🔧 **Enable fontconfig universal build** - Already configured for both architectures
- [x] 🔧 **Implement patch tracking** - Added marker file system
- [x] 🔧 **Disable Poppler tests** - Already has -DBUILD_TESTS=OFF
- [x] 🔧 **Test framework fix with Cairo** - Fix applied to all dependencies

## Phase 2: Systematic Dependency Build (🎯 **AFTER FIXES**)
- [x] ✅ **Core dependencies built** - libjpeg-turbo, libpng, libgif, bzip2, brotli, expat, harfbuzz
- [ ] 🔄 **gettext** - Rebuild with fixes
- [ ] 🔄 **glib** - Rebuild with header fix
- [ ] 🔄 **fontconfig** - Build as universal binary
- [ ] 🔄 **cairo** - Build with framework fix
- [ ] 🎯 **lcms2** - Build for color management
- [ ] 🎯 **freetype** - Build for font rendering
- [ ] 🎯 **pixman** - Build for Cairo
- [ ] 🎯 **Poppler** - Build with all dependencies
- [ ] 🎯 **FontForge** - Build for font manipulation
- [ ] 🎯 **pdf2htmlEX** - THE FINAL GOAL

## Phase 3: Final Build and Testing
- [ ] 🎯 **Build pdf2htmlEX** - Apply Poppler 24 API patch
- [ ] 🎯 **Create universal binary** - Merge architectures with lipo
- [ ] ✅ **Test x86_64 binary** - Verify functionality
- [ ] ✅ **Test arm64 binary** - Verify functionality  
- [ ] ✅ **Test PDF conversions** - Sample files with images, fonts
- [ ] ✅ **Verify no dynamic deps** - Check with otool -L

## Phase 4: Documentation and Distribution
- [ ] Document fixed build process
- [ ] Create installation instructions
- [ ] Package distributable binary
- [ ] Create troubleshooting guide

## 🚨 **IMMEDIATE ACTION STEPS**
1. **Fix framework linker issue** - Critical blocker
2. **Fix fontconfig build** - Architecture mismatch
3. **Add patch tracking** - Prevent re-application
4. **Test each fix incrementally** - Verify progress
5. **Keep detailed logs** - Document what works