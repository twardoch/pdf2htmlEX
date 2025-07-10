# pdf2htmlEX v2 Test Suite

This directory contains comprehensive tests for the pdf2htmlEX v2 Homebrew formula.

## Test Scripts

### test_basic.sh
Basic functionality tests including:
- Version and help output
- Simple PDF conversion
- Multipage PDF handling
- Binary architecture verification
- Static linking validation
- Error handling

### test_fonts.sh
Font handling tests including:
- Type1 font support
- TrueType font support
- Unicode text handling
- Font embedding options
- Font fallback behavior

### test_integration.sh
Full integration tests including:
- Formula syntax validation
- Complete build and installation
- Installed binary verification
- Universal binary support
- Static dependency checking
- Performance benchmarking
- Memory usage monitoring

## Running Tests

### Quick Test (After Local Build)
```bash
# Test locally built binary
./test_basic.sh
./test_fonts.sh
```

### Full Integration Test
```bash
# Test complete Homebrew installation
./test_integration.sh all

# Run specific test suites
./test_integration.sh syntax    # Formula syntax only
./test_integration.sh install   # Installation process
./test_integration.sh binary    # Installed binary tests
./test_integration.sh performance # Performance tests
```

### Environment Variables
- `FORCE_REINSTALL=yes` - Force reinstall if pdf2htmlex is already installed
- `UNINSTALL_AFTER=yes` - Automatically uninstall after integration tests

## Test PDF Files

The test scripts create minimal PDF files on-the-fly for testing. These include:
- Simple single-page PDFs
- Multipage PDFs
- PDFs with different font types
- Invalid PDFs for error handling

## Expected Results

All tests should pass with green checkmarks (✓). Warnings (yellow) indicate non-critical issues that don't affect functionality.

## Troubleshooting

If tests fail:
1. Check that all dependencies are installed: `brew list`
2. Ensure you're using the latest formula: `git pull`
3. Check build logs: `brew gist-logs pdf2htmlex`
4. Run with verbose output: `brew install --verbose --debug Formula/pdf2htmlex.rb`

## Adding New Tests

To add a new test:
1. Create a new test script following the existing pattern
2. Use the color-coded output functions (log, warn, error)
3. Clean up temporary files in the cleanup trap
4. Make the script executable: `chmod +x test_new.sh`
5. Document the test in this README