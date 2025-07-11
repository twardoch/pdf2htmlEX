#!/usr/bin/env bash
# this_file: v2/scripts/verify-shas.sh

# Simple helper that downloads a URL (or reads from stdin) and prints its
# SHA256 hash – used when bumping dependency versions.

set -euo pipefail

usage() {
  echo "Usage: $0 <url>" >&2
  echo "       $0 - < file.tgz" >&2
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

if [[ "$1" == "-" ]]; then
  # Read from stdin
  shasum -a 256 - | awk '{print $1}'
  exit 0
fi

url="$1"
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT

echo "Downloading $url …" >&2
curl -LsS "$url" -o "$temp"

echo -n "SHA256: "
shasum -a 256 "$temp" | awk '{print $1}'

