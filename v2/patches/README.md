# pdf2htmlEX Patches

This directory contains patches required for pdf2htmlEX to work with modern versions of its dependencies.

## Available Patches

### pdf2htmlEX-poppler24.patch

**Purpose**: Compatibility patch for Poppler 24.x API changes

**Changes**:
- Updates raw pointer usage to smart pointer API (`font.get()`)
- Replaces deprecated `toStr()` calls with `getCString()`
- Updates `copy()` method calls to `clone()`
- Adjusts `createPDFDoc()` calls for new optional parameter API
- Removes deprecated `item->close()` calls in outline processing
- Updates FormPageWidgets pointer handling

**Apply with**:
```bash
patch -p1 < pdf2htmlEX-poppler24.patch
```

**Note**: This patch is automatically applied by the Homebrew formula during the build process. Manual application is only needed for development/testing outside of the formula.

## Development Notes

When updating dependency versions, check if additional patches are needed:

1. **Poppler Updates**: Check API changes in Poppler release notes
2. **FontForge Updates**: Monitor FontForge scripting API changes
3. **Compiler Updates**: Watch for new C++ standard requirements

## Creating New Patches

1. Make changes to the source code
2. Generate patch with git:
   ```bash
   git diff > new-patch.patch
   ```
3. Test the patch on a clean checkout
4. Update the formula to apply the patch during build