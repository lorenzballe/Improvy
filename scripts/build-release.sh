#!/bin/bash

# Improvy Release Build Script
# Builds iOS (IPA) and Android (AAB) for store submission

set -e

echo "🚀 Improvy Release Build"
echo "========================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build number (today's date)
BUILD_NUMBER=$(date +%Y%m%d)

# Version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | cut -d: -f2 | xargs)

echo -e "${YELLOW}Version: $VERSION${NC}"
echo -e "${YELLOW}Build: $BUILD_NUMBER${NC}"
echo ""

# Step 1: Clean
echo -e "${GREEN}[1/5] Cleaning build directories...${NC}"
flutter clean
rm -rf build/ ios/build/ android/.gradle

# Step 2: Get dependencies
echo -e "${GREEN}[2/5] Getting dependencies...${NC}"
flutter pub get

# Step 3: Build iOS
echo -e "${GREEN}[3/5] Building iOS (release)...${NC}"
flutter build ios --release --no-codesign

echo ""
echo -e "${YELLOW}iOS build complete!${NC}"
echo "Location: build/ios/iphoneos/Runner.app"
echo "Next: Archive in Xcode and upload to TestFlight"
echo "Command:"
echo "  cd ios"
echo "  xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -derivedDataPath ../build/ios"
echo ""

# Step 4: Build Android
echo -e "${GREEN}[4/5] Building Android App Bundle (release)...${NC}"
flutter build appbundle --release

echo ""
echo -e "${YELLOW}Android App Bundle complete!${NC}"
echo "Location: build/app/outputs/bundle/release/app-release.aab"
echo "Next: Upload to Play Console"
echo ""

# Step 5: Summary
echo -e "${GREEN}[5/5] Build Summary${NC}"
echo "===================="
echo ""

if [ -f build/app/outputs/bundle/release/app-release.aab ]; then
    AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo -e "${GREEN}✓${NC} Android AAB: $AAB_SIZE"
    echo "  → Upload to: play.google.com/console"
else
    echo -e "${RED}✗${NC} Android AAB not found"
fi

echo ""
echo -e "${GREEN}✓${NC} Build completed successfully!"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo ""
echo "iOS (TestFlight):"
echo "  1. Open ios/Runner.xcworkspace in Xcode"
echo "  2. Product → Archive"
echo "  3. Distribute to TestFlight"
echo "  4. Internal testing (verify no crashes, RevenueCat works)"
echo ""
echo "Android (Play Console):"
echo "  1. Go to play.google.com/console"
echo "  2. Select Improvy app"
echo "  3. Release → Internal testing"
echo "  4. Upload AAB: build/app/outputs/bundle/release/app-release.aab"
echo "  5. Review and submit"
echo ""
echo "Documentation: See COMPLETION_PLAN.md"
echo ""
