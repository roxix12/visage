#!/bin/zsh
# Builds a universal (Apple Silicon + Intel) Release Visage.app with Xcode and packages it as
# dist/Visage-<version>.dmg: the app, an Applications shortcut, a read-me and the licence.
#
# Signing, from strongest to weakest (see SIGNING.md):
#   VISAGE_TEAM=<Team ID> VISAGE_NOTARY_PROFILE=<notarytool profile>
#       Developer ID + notarized. Opens on any Mac without warnings. Needs a paid Apple Developer account.
#   VISAGE_TEAM=<Team ID>
#       Development signing. Face Unlock works only on Macs registered to the team; the profile expires.
#   (neither)
#       Ad-hoc. The app runs, but macOS refuses the Touch ID-protected session key
#       (Keychain error -34018), so the Mac password can't be saved.
# Optional: VISAGE_BUNDLE_ID overrides com.cdwburhan.visage if that ID isn't available to the team.
set -euo pipefail
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

PROJECT=Visage.xcodeproj/project.pbxproj
VERSION=$(sed -nE 's/.*MARKETING_VERSION = ([^;]+);.*/\1/p' $PROJECT | head -1)
BUILD=build
LOG=$BUILD/xcodebuild.log
mkdir -p $BUILD dist
: > $LOG

BUNDLE_ARGS=()
[[ -n "${VISAGE_BUNDLE_ID:-}" ]] && BUNDLE_ARGS=(PRODUCT_BUNDLE_IDENTIFIER="$VISAGE_BUNDLE_ID")
# Registering this Mac lets the team create the development profile that archiving signs with first.
COMMON=(-project Visage.xcodeproj -scheme Visage -configuration Release -destination 'platform=macOS'
        ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO "${BUNDLE_ARGS[@]}")
TEAM_SIGNING=(DEVELOPMENT_TEAM="${VISAGE_TEAM:-}" CODE_SIGN_STYLE=Automatic
              -allowProvisioningUpdates -allowProvisioningDeviceRegistration)
fail() { tail -30 $LOG; exit 1; }

EXPORT_METHOD="${VISAGE_EXPORT_METHOD:-}"
if [[ -n "${VISAGE_NOTARY_PROFILE:-}" ]]; then
  [[ -n "${VISAGE_TEAM:-}" ]] || { echo "error: VISAGE_NOTARY_PROFILE needs VISAGE_TEAM" >&2; exit 1; }
  EXPORT_METHOD="${EXPORT_METHOD:-developer-id}"
fi

if [[ -n "$EXPORT_METHOD" ]]; then
  [[ -n "${VISAGE_TEAM:-}" ]] || { echo "error: exporting needs VISAGE_TEAM" >&2; exit 1; }
  echo "==> Archiving Visage $VERSION"
  ARCHIVE=$BUILD/Visage.xcarchive
  rm -rf $ARCHIVE $BUILD/export
  xcodebuild "${COMMON[@]}" "${TEAM_SIGNING[@]}" -archivePath $ARCHIVE archive >> $LOG || fail

  echo "==> Exporting ($EXPORT_METHOD)"
  cat > $BUILD/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>$EXPORT_METHOD</string>
	<key>teamID</key><string>$VISAGE_TEAM</string>
	<key>signingStyle</key><string>automatic</string>
	<key>destination</key><string>export</string>
</dict>
</plist>
EOF
  xcodebuild -exportArchive -archivePath $ARCHIVE -exportPath $BUILD/export \
    -exportOptionsPlist $BUILD/ExportOptions.plist -allowProvisioningUpdates >> $LOG || fail
  APP=$BUILD/export/Visage.app
else
  APP=$BUILD/DerivedData/Build/Products/Release/Visage.app
  rm -rf $BUILD/DerivedData/Build/Products/Release
  if [[ -n "${VISAGE_TEAM:-}" ]]; then
    SIGNING=("${TEAM_SIGNING[@]}")
  else
    echo "warning: VISAGE_TEAM is not set. Building ad-hoc, so saving the Mac password will not work." >&2
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
  xcodebuild "${COMMON[@]}" -derivedDataPath $BUILD/DerivedData "${SIGNING[@]}" build >> $LOG || fail
fi
codesign --verify --strict --verbose=2 $APP

echo "==> Packaging"
STAGE="$(mktemp -d)/Visage"
mkdir -p "$STAGE"
ditto $APP "$STAGE/Visage.app"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/License.txt"
cat > "$STAGE/Read Me First.txt" <<EOF
Visage $VERSION: face unlock for Mac
Made by cdwburhan. Free.

INSTALL
1. Drag Visage onto the Applications folder in this window.
2. Open Visage from Applications. If macOS says it can't check the app,
   right-click Visage, choose Open, then Open again.
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

if [[ -n "${VISAGE_NOTARY_PROFILE:-}" ]]; then
  echo "==> Signing and notarizing the DMG (usually a few minutes)"
  IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep "($VISAGE_TEAM)" | head -1 | awk '{print $2}')
  [[ -n "$IDENTITY" ]] || { echo "error: no Developer ID Application certificate for team $VISAGE_TEAM in the keychain" >&2; exit 1; }
  codesign --force --sign "$IDENTITY" --timestamp $DMG
  RESULT=$(xcrun notarytool submit $DMG --keychain-profile "$VISAGE_NOTARY_PROFILE" --wait 2>&1) || true
  echo "$RESULT"
  if ! grep -q "status: Accepted" <<< "$RESULT"; then
    ID=$(sed -nE 's/^Submission ID received: *//p' <<< "$RESULT" | head -1)
    [[ -n "$ID" ]] && xcrun notarytool log "$ID" --keychain-profile "$VISAGE_NOTARY_PROFILE"
    echo "error: notarization was not accepted" >&2
    exit 1
  fi
  xcrun stapler staple $DMG
  spctl -a -vv -t open --context context:primary-signature $DMG
fi

shasum -a 256 $DMG | tee $DMG.sha256
ls -lh $DMG
