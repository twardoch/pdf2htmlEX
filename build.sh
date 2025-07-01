#!/usr/bin/env bash
cd "$(dirname "$0")"

echo "==> pdf2htmlEX Homebrew Formula Build - Strategy 1: In-Source Poppler Build"
echo "    This build uses an optimized approach that builds Poppler within the"
echo "    pdf2htmlEX source tree structure to resolve linking dependencies."
echo ""

npx repomix -i "archive,.giga,issues,GEMINI.md,AGENTS.md" -o "./llms.txt" .

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install pdf2htmlEX from source formula with verbose output for debugging
echo "==> Building pdf2htmlEX from source (this may take several minutes)..."
brew install --formula --build-from-source --verbose ./Formula/pdf2htmlex.rb
