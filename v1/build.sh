#!/usr/bin/env bash
cd "$(dirname "$0")"

echo "==> pdf2htmlEX Homebrew Formula Build - Strategy 1: In-Source Poppler Build"
echo "    This build uses an optimized approach that builds Poppler within the"
echo "    pdf2htmlEX source tree structure to resolve linking dependencies."
echo ""

# npx repomix -i "archive,.giga,issues,GEMINI.md,AGENTS.md" -o "./llms.txt" .

# Set up Homebrew environment
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Check if brew is now available
if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is not installed or could not be found." >&2
    echo "Please install Homebrew first: https://brew.sh/" >&2
    exit 1
fi

# If a previous lightweight stub formula was installed earlier during test
# iterations it will shadow the real pdf2htmlEX binary.  Remove it so the
# upcoming full build installs the genuine binary.
if brew list --formula 2>/dev/null | grep -q '^pdf2htmlexstub$'; then
    echo "==> Removing previously installed pdf2htmlexstub formula"
    brew uninstall --ignore-dependencies pdf2htmlexstub || true
fi

# Install pdf2htmlEX from source formula with verbose output for debugging
echo "==> Building pdf2htmlEX from source (this may take several minutes)..."
brew install --formula --build-from-source --verbose ./Formula/pdf2htmlex.rb
