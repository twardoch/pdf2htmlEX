#!/usr/bin/env bash
cd $(dirname "$0")
DIR=$(pwd)

# Loop through each subdirectory containing formula variants
for subdir in pdf2htmlex*/; do
    if [ -d "$subdir" ]; then
        formula_path="$subdir/pdf2htmlex.rb"
        if [ -f "$formula_path" ]; then
            # Extract subdirectory name without trailing slash
            variant_name=$(basename "$subdir")
            output_file="${variant_name}.txt"

            echo "Trying formula variant: $variant_name"
            echo "Formula path: $formula_path"

            # Uninstall any existing version first
            brew uninstall pdf2htmlex pdf2htmlEX 2>/dev/null || true

            # Build and install the formula
            brew install --formula --build-from-source --verbose "./$formula_path" >"$output_file" 2>&1

            echo "--------------------------------" >>"$output_file"
            echo "Build completed for $variant_name at $(date)" >>"$output_file"
            echo "--------------------------------" >>"$output_file"

            # Check which binaries were installed
            which pdf2htmlEX >>"$output_file" 2>&1
            which pdf2htmlex >>"$output_file" 2>&1

            echo "--------------------------------" >>"$output_file"
            echo "Finished processing $variant_name"
            echo
        else
            echo "Warning: No pdf2htmlex.rb found in $subdir"
        fi
    fi
done

echo "All formula variants have been processed."
