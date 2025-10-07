#!/bin/bash

# Fix deployment target to macOS 13.0
echo "🔧 Fixing macOS deployment target..."

# Use sed to replace the incorrect deployment target
sed -i '' 's/MACOSX_DEPLOYMENT_TARGET = 26.0;/MACOSX_DEPLOYMENT_TARGET = 13.0;/g' Uptime.xcodeproj/project.pbxproj

echo "✅ Deployment target fixed to macOS 13.0"