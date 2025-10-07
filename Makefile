.PHONY: build clean fix-target production help

help:
	@echo "Available targets:"
	@echo "  fix-target  - Fix the macOS deployment target"
	@echo "  build       - Build debug version"
	@echo "  production  - Build production version"
	@echo "  clean       - Clean build artifacts"

fix-target:
	@./fix-deployment-target.sh

build:
	@echo "🏗️  Building debug version..."
	@xcodebuild -project Uptime.xcodeproj -scheme Uptime -configuration Debug

production: fix-target
	@echo "🚀 Building production version..."
	@mkdir -p build
	@./build-production.sh

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build
	@xcodebuild clean -project Uptime.xcodeproj -scheme Uptime

.DEFAULT_GOAL := help