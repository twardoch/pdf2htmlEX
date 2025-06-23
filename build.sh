#!/usr/bin/env bash

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install pdf2htmlEX from source formula
brew install --build-from-source Formula/pdf2htmlex.rb
