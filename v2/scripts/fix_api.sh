#!/bin/bash
# Fix Poppler 24.x API compatibility issues

cd ../build/src/v0.18.8.rc1/src/HTMLRenderer

# Fix toStr() calls - getName() now returns std::string directly
sed -i '' 's/font->getName()->toStr()/font->getName()/g' font.cc

# Fix FoFiTrueType smart pointer usage  
sed -i '' 's/FoFiTrueType \* fftt = FoFiTrueType::load/auto fftt = FoFiTrueType::load/g' font.cc
sed -i '' 's/getCodeToGIDMap(fftt)/getCodeToGIDMap(fftt.get())/g' font.cc
sed -i '' '/delete fftt;/d' font.cc

# Fix locateFont std::optional return type
sed -i '' 's/auto \* font_loc = font->locateFont/auto font_loc_opt = font->locateFont/g' font.cc
sed -i '' 's/if(auto \* font_loc = font->locateFont/if(auto font_loc_opt = font->locateFont/g' font.cc

# Fix GfxFontLoc pointer to optional
sed -i '' 's/GfxFontLoc \* localfontloc = font->locateFont/auto localfontloc_opt = font->locateFont/g' font.cc

# Fix path->toStr() calls - path is now std::string  
sed -i '' 's/localfontloc->path->toStr()/localfontloc.path/g' font.cc

echo "API compatibility fixes applied" 