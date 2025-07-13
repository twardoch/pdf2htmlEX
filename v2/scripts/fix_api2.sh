#!/bin/bash
# Fix remaining Poppler 24.x API compatibility issues

cd ../build/src/v0.18.8.rc1/src/HTMLRenderer

echo "Applying additional API fixes..."

# Fix string constructor issues - remove redundant string() wrapper
sed -i '' 's/string(localfontloc\.path)/localfontloc.path/g' font.cc

# Remove delete statements for value types (not pointers anymore)
sed -i '' '/delete localfontloc;/d' font.cc
sed -i '' '/delete localfontloc_opt.value();/d' font.cc

# Fix the optional handling more thoroughly
sed -i '' 's/if(localfontloc_opt\.has_value())/if(localfontloc_opt)/g' font.cc
sed -i '' 's/auto& localfontloc = localfontloc_opt\.value();/auto localfontloc = localfontloc_opt.value();/g' font.cc

echo "Additional API fixes applied"
