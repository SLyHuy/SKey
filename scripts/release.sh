#!/usr/bin/env bash
# Builds the release app without a certificate (ad-hoc signature) and packages it:
#   dist/SKey-<version>.dmg     (app + Applications shortcut + install notes)
#   dist/SKey-<version>.zip
#   dist/SKey-<version>.sha256  (checksums of both)
#
# The version is VERSION=1.2.3 when set (the release workflow sets it from the tag it is
# about to create); otherwise the latest v* tag plus "-dev", for local test builds. The
# build number is the commit count, so it always grows.
set -euo pipefail
cd "$(dirname "$0")/.."

LATEST_TAG=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo v0.0.0)
VERSION="${VERSION:-${LATEST_TAG#v}-dev}"
BUILD=$(git rev-list --count HEAD)

command -v xcodegen >/dev/null || { echo "Cần cài XcodeGen: brew install xcodegen" >&2; exit 1; }

echo "==> Chạy test engine"
(cd Packages/SKeyEngine && swift test --quiet)

echo "==> Build Release $VERSION (build $BUILD, universal, ký ad-hoc)"
xcodegen generate --quiet
rm -rf build/DerivedData/Build/Products/Release dist
xcodebuild -project SKey.xcodeproj -scheme SKey -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" build -quiet

APP="build/DerivedData/Build/Products/Release/SKey.app"
codesign --verify --strict "$APP"
BUILT=$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")
[ "$BUILT" = "$VERSION" ] || { echo "App reports version $BUILT, expected $VERSION" >&2; exit 1; }

mkdir -p dist
ditto -c -k --keepParent "$APP" "dist/SKey-$VERSION.zip"

echo "==> Tạo DMG"
STAGE="build/dmg"
rm -rf "$STAGE" && mkdir -p "$STAGE"
ditto "$APP" "$STAGE/SKey.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/Đọc trước khi cài.txt" <<'NOTES'
CÀI ĐẶT SKEY

1. Kéo SKey.app vào thư mục Applications (biểu tượng bên cạnh).
2. Mở SKey từ Applications. macOS sẽ báo "SKey" Not Opened: Apple could
   not verify "SKey" is free of malware... Đây là thông báo bình thường cho
   mọi app chưa được Apple notarize, không có nghĩa Apple tìm thấy mã độc.
   - Bấm "Done" (đừng bấm "Move to Trash").
   - Vào System Settings → Privacy & Security, kéo xuống phần Security,
     bấm "Open Anyway", xác nhận bằng mật khẩu hoặc Touch ID.
   - Hoặc chạy trong Terminal:
       xattr -dr com.apple.quarantine /Applications/SKey.app
   Muốn chắc chắn file tải về là bản gốc, kiểm tra trước bằng:
       gh attestation verify SKey-x.y.z.dmg -R SLyHuy/SKey
3. Làm theo màn hình "Cài đặt SKey": cấp quyền Accessibility, chỉ giữ
   input source ABC, tắt tự sửa chính tả và gợi ý chữ của macOS.

Khi cập nhật bản mới: bấm "Làm mới quyền" trong màn hình cài đặt rồi bật
lại SKey trong Accessibility.

Mã nguồn và bản mới nhất: https://github.com/SLyHuy/SKey
Giấy phép GPL-3.0 © 2026 Huy Ly
NOTES

# Volume icon: build read-write, give the mounted volume SKey's icon, then compress.
RW="build/SKey-rw.dmg"
rm -f "$RW" "dist/SKey-$VERSION.dmg"
hdiutil create -quiet -volname "SKey $VERSION" -srcfolder "$STAGE" -fs HFS+ -format UDRW -ov "$RW"
MOUNT=$(hdiutil attach -nobrowse -noautoopen -readwrite "$RW" 2>/dev/null | awk -F'\t' '/\/Volumes\// {print $NF}')
if [ -n "$MOUNT" ]; then
  if SETFILE=$(xcrun -f SetFile 2>/dev/null); then
    cp "$APP/Contents/Resources/AppIcon.icns" "$MOUNT/.VolumeIcon.icns"
    "$SETFILE" -a C "$MOUNT"
  fi
  hdiutil detach -quiet "$MOUNT"
fi
hdiutil convert -quiet "$RW" -format UDZO -imagekey zlib-level=9 -o "dist/SKey-$VERSION.dmg"
rm -f "$RW"

(cd dist && shasum -a 256 "SKey-$VERSION.dmg" "SKey-$VERSION.zip" > "SKey-$VERSION.sha256")

echo "==> Xong"
echo "Kiến trúc: $(lipo -archs "$APP/Contents/MacOS/SKey")"
codesign -dv "$APP" 2>&1 | grep -E '^(Identifier|Signature)='
cat "dist/SKey-$VERSION.sha256"
