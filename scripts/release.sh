#!/usr/bin/env bash
# Builds the release app without a certificate (ad-hoc signature) and packages it:
#   dist/SKey-<version>.zip and dist/SKey-<version>.zip.sha256
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Cần cài XcodeGen: brew install xcodegen" >&2; exit 1; }

echo "==> Chạy test engine"
(cd Packages/SKeyEngine && swift test --quiet)

echo "==> Build Release (universal, ký ad-hoc)"
xcodegen generate --quiet
rm -rf build/DerivedData/Build/Products/Release dist
xcodebuild -project SKey.xcodeproj -scheme SKey -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData build -quiet

APP="build/DerivedData/Build/Products/Release/SKey.app"
codesign --verify --strict "$APP"
VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")

mkdir -p dist
ditto -c -k --keepParent "$APP" "dist/SKey-$VERSION.zip"
(cd dist && shasum -a 256 "SKey-$VERSION.zip" > "SKey-$VERSION.zip.sha256")

echo "==> Xong"
echo "Kiến trúc: $(lipo -archs "$APP/Contents/MacOS/SKey")"
codesign -dv "$APP" 2>&1 | grep -E '^(Identifier|Signature)='
cat "dist/SKey-$VERSION.zip.sha256"
