# TODO.md

## Phase 1: Complete Builds
- [ ] Complete v2 build - finish lcms2 build
- [ ] Build Poppler in v2 with all required dependencies
- [ ] Build FontForge in v2
- [ ] Build pdf2htmlEX in v2
- [ ] Verify v2 build produces working binaries

## Phase 2: Testing and Validation
- [ ] Test pdf2htmlEX binary on x86_64 architecture
- [ ] Test pdf2htmlEX binary on arm64 architecture
- [ ] Test PDF conversion with sample files
- [ ] Verify universal binary support with `lipo -info`
- [ ] Add automated build verification tests to v2 system

## Phase 3: Quality Assurance
- [ ] Create sample PDF test suite for validation
- [ ] Add test PDFs with various features (images, fonts, forms)
- [ ] Benchmark conversion speed on both architectures
- [ ] Test memory usage during conversion
- [ ] Verify graceful error handling with malformed PDFs
- [ ] Track build time for v2 approach
- [ ] Measure and document final binary size

## Phase 4: Documentation and Distribution
- [ ] Document v2 build process and requirements
- [ ] Create usage instructions for pdf2htmlEX
- [ ] Create distributable package from v2 build
- [ ] Set up CI/CD for automated builds
- [ ] Establish version management and release process

## Technical Improvements
- [ ] Implement proper error handling in build scripts
- [ ] Add detailed logging to build processes
- [ ] Create build status indicators
- [ ] Add progress reporting for long builds
- [ ] Implement build artifact caching
- [ ] Add build dependency verification
- [ ] Create troubleshooting guide for common issues