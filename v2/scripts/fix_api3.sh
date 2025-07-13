#!/bin/bash
# Fix GfxFontLoc copy constructor issue

cd ../build/src/v0.18.8.rc1/src/HTMLRenderer

echo "Fixing GfxFontLoc reference issues..."

# Fix the optional handling to use references instead of copying
sed -i '' 's/auto localfontloc = localfontloc_opt\.value();/auto\& localfontloc = localfontloc_opt.value();/g' font.cc

# Also fix the similar issue in the font_loc handling
sed -i '' 's/auto font_loc = \&font_loc_opt\.value();/auto\& font_loc = font_loc_opt.value();/g' font.cc

echo "GfxFontLoc reference fixes applied"
