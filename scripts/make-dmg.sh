#!/bin/zsh
# Builds a universal (Apple Silicon + Intel) Release Visage.app with Xcode and packages it as
# dist/Visage-<version>.dmg: the app, an Applications shortcut, a read-me and the licence.
#
# Signing: run with VISAGE_TEAM=<your Team ID> (Xcode → Settings → Accounts) for a team-signed build.
# Without it the app is signed ad-hoc, and macOS refuses to store the Touch ID–protected session key
# (Keychain error -34018), so the Mac password can't be saved and Face Unlock can't be set up.
set -euo pipefail
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

PROJECT=Visage.xcodeproj/project.pbxproj
VERSION=$(sed -nE 's/.*MARKETING_VERSION = ([^;]+);.*/\1/p' $PROJECT | head -1)
BUILD=build
APP=$BUILD/DerivedData/Build/Products/Release/Visage.app
rm -rf $BUILD/DerivedData/Build/Products/Release
mkdir -p $BUILD dist

if [[ -n "${VISAGE_TEAM:-}" ]]; then
  # With this Mac as the destination, a free Personal Team registers it and creates the development profile
  # that the keychain-access-groups entitlement needs (without a profile macOS kills the app at launch).
  SIGNING=(DEVELOPMENT_TEAM="$VISAGE_TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration)
else
  echo "warning: VISAGE_TEAM is not set — building ad-hoc; saving the Mac password will not work." >&2
  # keychain-access-groups needs a team, so the ad-hoc build keeps only the camera entitlement.
  cat > $BUILD/adhoc.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.device.camera</key><true/>
</dict>
</plist>
EOF
  SIGNING=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_ENTITLEMENTS="$PWD/$BUILD/adhoc.entitlements")
fi

echo "==> Building Visage $VERSION"
xcodebuild -project Visage.xcodeproj -scheme Visage -configuration Release -destination 'platform=macOS' \
  -derivedDataPath $BUILD/DerivedData ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  "${SIGNING[@]}" build > $BUILD/xcodebuild.log || { tail -30 $BUILD/xcodebuild.log; exit 1; }
codesign --verify --strict --verbose=2 $APP

echo "==> Packaging"
STAGE="$(mktemp -d)/Visage"
mkdir -p "$STAGE"
ditto $APP "$STAGE/Visage.app"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/License.txt"
cat > "$STAGE/Read Me First.txt" <<EOF
Visage $VERSION — face unlock for Mac
Made by cdwburhan. Free.

INSTALL
1. Drag Visage onto the Applications folder in this window.
2. Open Applications, right-click Visage, choose Open, then Open again.
   Visage is not notarized by Apple, so macOS asks once. If there is no Open
   button, go to System Settings → Privacy & Security and click "Open Anyway".
3. Follow the setup in your Mac's notch: allow Accessibility and Camera,
   enroll your face, and enter your Mac password once.
4. Visage lives in the menu bar. Open Settings from there.

REQUIREMENTS
macOS 15 or later, Apple Silicon or Intel, with a camera.

PLEASE READ
A regular Mac camera cannot see depth. A photo or video of you may be enough
to unlock your Mac. Touch ID and your password keep working.
Face data and your password stay on this Mac, encrypted. Visage makes no network requests.
EOF

DMG=dist/Visage-$VERSION.dmg
rm -f $DMG
hdiutil create -volname "Visage $VERSION" -srcfolder "$STAGE" -ov -format UDZO -fs HFS+ $DMG > /dev/null
shasum -a 256 $DMG | tee $DMG.sha256
ls -lh $DMG
