
# pdf2htmlEX for macOS - Universal Binary Build

This project provides a working build system for pdf2htmlEX on macOS, creating universal binaries (x86_64 + arm64) with all dependencies statically linked.

## 🎯 Status: Build Fixes Complete

All critical build issues have been resolved. The v2 build system is ready for use.

## 🚀 Quick Start

```bash
# Build pdf2htmlEX
cd v2
./build.sh

# Test the build (~15 minutes on Apple Silicon)
./scripts/test-build.sh

# Use pdf2htmlEX
./dist/bin/pdf2htmlEX your-document.pdf
```

## 📚 Documentation

### Build Documentation
- **[v2/BUILD_INSTRUCTIONS.md](v2/BUILD_INSTRUCTIONS.md)** - Complete build guide
- **[v2/TROUBLESHOOTING.md](v2/TROUBLESHOOTING.md)** - Common issues and solutions
- **[v2/FIXES.md](v2/FIXES.md)** - Technical details of fixes applied

### Project Documentation
- **[PLAN.md](PLAN.md)** - Project roadmap and architecture
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[TODO.md](TODO.md)** - Task tracking

## 🔧 Key Features

- **Universal Binary**: Supports both Intel and Apple Silicon Macs
- **Self-Contained**: All dependencies statically linked
- **No Homebrew Required**: Standalone binary with no runtime dependencies
- **Automated Build**: Single script builds everything from source

## 📦 Directory Structure

- `v2/` - Current working build system with all fixes applied
- `legacy/v1/` - Previous Homebrew formula attempt (archived)
- `issues/` - Build failure analysis and solutions

## 🤝 Contributing

Contributions welcome! Please:
1. Test the build on your Mac
2. Report any issues with system details
3. Submit fixes via pull requests

## 📝 License

This build system maintains the original pdf2htmlEX license. See individual component licenses in source directories. 