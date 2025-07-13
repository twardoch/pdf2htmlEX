#!/bin/bash
# Comprehensive Poppler 24.x API compatibility fix for pdf2htmlEX

cd ../build/src/v0.18.8.rc1/src

echo "Applying comprehensive Poppler 24.x API compatibility fixes..."

# Fix 1: shared_ptr<GfxFont> to raw pointer issues
find . -name "*.cc" -exec sed -i '' 's/GfxFont \* font = state->getFont()/auto font = state->getFont()/g' {} \;
find . -name "*.cc" -exec sed -i '' 's/install_font(state->getFont())/install_font(state->getFont().get())/g' {} \;
find . -name "*.cc" -exec sed -i '' 's/getFont(font,/getFont(font,/g' {} \;

# Fix 2: Font casting issues with shared_ptr
sed -i '' 's/((GfxCIDFont \*)font)/((GfxCIDFont *)font.get())/g' HTMLRenderer/text.cc
sed -i '' 's/((Gfx8BitFont \*)font)/((Gfx8BitFont *)font.get())/g' HTMLRenderer/text.cc

# Fix 3: Function calls expecting GfxFont* but getting shared_ptr
sed -i '' 's/check_unicode(u, uLen, code, font)/check_unicode(u, uLen, code, font.get())/g' HTMLRenderer/text.cc
sed -i '' 's/unicode_from_font(code, font)/unicode_from_font(code, font.get())/g' HTMLRenderer/text.cc

# Fix 4: Optional string issues - getName() now returns optional<string>
sed -i '' 's/font->getName()/font->getName().value_or("")/g' HTMLRenderer/font.cc

# Fix 5: FoFiTrueType unique_ptr issues  
sed -i '' 's/getCodeToGIDMap(fftt,/getCodeToGIDMap(fftt.get(),/g' HTMLRenderer/font.cc

# Fix 6: FormPageWidgets unique_ptr issue
sed -i '' 's/FormPageWidgets \* widgets = /auto widgets = /g' HTMLRenderer/form.cc

# Fix 7: Remove OutlineItem close() calls - method removed in new API
sed -i '' '/item->close();/d' HTMLRenderer/outline.cc

# Fix 8: Optional GfxFontLoc handling
sed -i '' 's/font_loc -> locType/font_loc.locType/g' HTMLRenderer/font.cc
sed -i '' '/delete font_loc;/d' HTMLRenderer/font.cc

# Fix 9: Remove string() wrapper for std::string  
sed -i '' 's/string(localfontloc\.path)/localfontloc.path/g' HTMLRenderer/font.cc

# Fix 10: Optional handling improvements
sed -i '' 's/if(localfontloc_opt)/if(localfontloc_opt.has_value())/g' HTMLRenderer/font.cc

# Fix 11: PDFDocFactory API changes - returns unique_ptr
sed -i '' 's/doc = PDFDocFactory().createPDFDoc/auto doc_ptr = PDFDocFactory().createPDFDoc/g' pdf2htmlEX.cc
sed -i '' 's/fileName, ownerPW, userPW/fileName, ownerPW ? std::optional<GooString>(*ownerPW) : std::nullopt, userPW ? std::optional<GooString>(*userPW) : std::nullopt/g' pdf2htmlEX.cc

# Fix 12: LinkDest copy() method removed
sed -i '' 's/_->copy()/_->copy()/g' HTMLRenderer/link.cc || sed -i '' 's/copy()/clone()/g' HTMLRenderer/link.cc

echo "Comprehensive API fixes applied!"
