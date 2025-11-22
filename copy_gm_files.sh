#!/bin/bash

# Script to move files from npm packages based on their package.json configurations

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_MODULES_DIR="./node_modules"

# Check if node_modules exists
if [ ! -d "$NODE_MODULES_DIR" ]; then
    echo "Error: $NODE_MODULES_DIR directory not found"
    exit 1
fi

# Find all package.json files in node_modules
find "$NODE_MODULES_DIR" -name "package.json" -type f | while read -r package_json; do
    package_dir=$(dirname "$package_json")
    
    # Extract the "gm.destination" field
    destination=$(node -p "
        try {
            const pkg = require('$package_json');
            pkg.gm && pkg.gm.destination ? pkg.gm.destination : '';
        } catch(e) {
            '';
        }
    " 2>/dev/null)
    
    # Skip if no destination is defined
    if [ -z "$destination" ]; then
        continue
    fi
    
    package_name=$(node -p "require('$package_json').name" 2>/dev/null)
    echo "Processing: $package_name"
    
    # Build full destination path relative to script directory
    full_destination="$SCRIPT_DIR/$destination"
    echo "  Destination: $full_destination"
    
    # Create destination directory
    mkdir -p "$full_destination"
    
    # Move all files except package.json from package directory to destination
    echo "  Moving all files except package.json"
    (
        cd "$package_dir"
        
        # Move everything except package.json
        find . -maxdepth 1 ! -name "." ! -name "package.json" -exec mv {} "$full_destination/" \;
    )
    
    echo "  ✓ Completed: $package_name"
    echo ""
done

echo "All packages processed successfully!"
