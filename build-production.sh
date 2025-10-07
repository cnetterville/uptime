#!/bin/bash

# Production Build Script for Uptime
set -e

echo "🏗️  Building Uptime for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project Uptime.xcodeproj -scheme Uptime -configuration Release

# Build for release
echo "📦 Building Release version..."
xcodebuild archive \
  -project Uptime.xcodeproj \
  -scheme Uptime \
  -configuration Release \
  -archivePath "build/Uptime.xcarchive" \
  MACOSX_DEPLOYMENT_TARGET=13.0

# Export app
echo "📤 Exporting app..."
xcodebuild -exportArchive \
  -archivePath "build/Uptime.xcarchive" \
  -exportPath "build/Release" \
  -exportOptionsPlist "ExportOptions.plist"

echo "✅ Build complete! Check the build/Release folder."
echo "🚀 Ready for distribution!"