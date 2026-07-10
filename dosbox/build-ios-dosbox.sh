#!/bin/bash
# Build a one-tap "Ultima III in DOSBox" app for your iPhone/iPad and install it,
# with YOUR copy of the game.
#
# The *complete* Ultima III (the real DOS game in DOSBox), built on litchie/dospad
# (the open-source iOS DOSBox, GPLv2) — cloned + patched at build time, not
# re-hosted here — and your own Ultima III data (never committed).
#
# Prereqs:
#   - Xcode (signed in with the Apple ID that owns your team).
#   - iPhone/iPad connected, unlocked, "Trust" accepted, Developer Mode on.
#   - Your Ultima III game folder (the one with ULTIMA.COM). On a Mac GOG install
#     that's usually /Applications/Ultima III™.app/Contents/Resources/game
#
# Usage: dosbox/build-ios-dosbox.sh <AppleTeamID> [/path/to/ultimaIII/gamedata]
# Find your Team ID: security find-identity -v -p codesigning (the code in parens).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEAM="${1:?Usage: build-ios-dosbox.sh <AppleTeamID> [ultimaIII-data-dir]}"
SRC="${2:-/Applications/Ultima III™.app/Contents/Resources/game}"
BUNDLE_ID="${U3DOS_BUNDLE_ID:-info.u3redux.u3dos}"
RUN_EXE="${U3DOS_RUN_EXE:-ULTIMA.COM}"     # the DOS program dospad auto-runs
APP_NAME="Ultima III"
ICON="ultima3-icon.png"
WORK="${HOME}/Library/Caches/u3-dosbox"
DOSPAD="$WORK/dospad"

if ! [[ "$TEAM" =~ ^[A-Za-z0-9]{10}$ ]]; then
  echo "ERROR: '$TEAM' is not a valid Apple Team ID (10 letters/digits)." >&2
  exit 1
fi
if [ ! -f "$SRC/$RUN_EXE" ]; then
  echo "ERROR: no $APP_NAME data ($RUN_EXE) at:" >&2
  echo "  $SRC" >&2
  echo "Pass the folder with $RUN_EXE as the 2nd argument." >&2
  exit 1
fi

mkdir -p "$WORK"

# 1. Clone the open-source iOS DOSBox (GPLv2).
if [ ! -d "$DOSPAD/.git" ]; then
  echo "Cloning dospad (iOS DOSBox, litchie) ..."
  git clone --depth 1 https://github.com/litchie/dospad.git "$DOSPAD"
fi
PROJ="$DOSPAD/dospad.xcodeproj/project.pbxproj"

# 2. Rebrand the bundle id to yours (covers the app + its thumbnail extension).
if grep -q "com.litchie.idos3" "$PROJ"; then
  sed -i '' "s/com\.litchie\.idos3/$BUNDLE_ID/g" "$PROJ"
fi

# 3. Patch: auto-run the game exe from the C-drive root on launch (one-tap boot).
EMU="$DOSPAD/dospad/Main/DOSPadEmulator.m"
if ! grep -q "one-tap boot" "$EMU"; then
  echo "Patching dospad to auto-run $RUN_EXE ..."
  python3 - "$EMU" "$RUN_EXE" <<'PY'
import sys
p, run_exe = sys.argv[1], sys.argv[2]
s = open(p).read()
marker = '[self.commandList addObject:@"REM END AUTOMOUNT"];'
template = marker + '''

    // one-tap boot: run the game exe from the C drive root on launch (dedicated app).
    {
        DPDrive *cDrive = [self.package findDrive:'C'];
        if (cDrive) {
            NSString *exe = [cDrive.sourceUrl.path stringByAppendingPathComponent:@"__EXE__"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:exe]) {
                [self.commandList addObject:@"C:"];
                [self.commandList addObject:@"__EXE__"];
            }
        }
    }'''
assert marker in s, "anchor not found in DOSPadEmulator.m"
open(p, "w").write(s.replace(marker, template.replace("__EXE__", run_exe), 1))
print("patched")
PY
fi

# 3b. Branding: swap the app icon and rename to the game.
MASTER="$SCRIPT_DIR/$ICON"
ICON_SET="$DOSPAD/Resources/Assets.xcassets/AppIcon.appiconset"
if [ -f "$MASTER" ] && [ -d "$ICON_SET" ]; then
  echo "Applying the $APP_NAME app icon ..."
  for f in "$ICON_SET"/icon-*.png; do
    n="$(basename "$f" .png | sed 's/icon-//')"
    [[ "$n" =~ ^[0-9]+$ ]] && sips -s format png -z "$n" "$n" "$MASTER" --out "$f" >/dev/null 2>&1 || true
  done
  [ -f "$ICON_SET/iTunesArtwork@2x.png" ] && \
    sips -s format png -z 1024 1024 "$MASTER" --out "$ICON_SET/iTunesArtwork@2x.png" >/dev/null 2>&1 || true
fi
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$DOSPAD/Resources/iDOS-Info.plist" 2>/dev/null || true

# 4. Build + sign.
echo "Building (this takes a few minutes the first time) ..."
xattr -cr "$DOSPAD" 2>/dev/null || true
xcodebuild -project "$DOSPAD/dospad.xcodeproj" -scheme iDOS -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath "$DOSPAD/dd" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic build
APP="$(find "$DOSPAD/dd/Build/Products" -name 'iDOS.app' -type d | head -1)"
xattr -cr "$APP" 2>/dev/null || true
echo "Signed app: $APP"

# 5. Find the device.
DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null \
  | grep -iE 'iPhone|iPad' | grep -i 'available' | grep -vi 'unavailable' \
  | grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)"
if [ -z "${DEVICE_ID:-}" ]; then
  echo "No available device found. Connect+unlock your iPhone (accept Trust) and re-run." >&2
  exit 1
fi

# 6. Install the app.
echo "Installing to $DEVICE_ID ..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"

# 7. Stage YOUR game data (+ an idos.json) and push it into the app's Documents
#    (which DOSBox mounts as drive C). None of this is committed to the repo.
STAGE="$WORK/gamedata"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp "$SRC"/* "$STAGE/" 2>/dev/null || find "$SRC" -maxdepth 1 -type f -exec cp {} "$STAGE/" \;
rm -f "$STAGE"/*.pdf "$STAGE"/dosbox*.conf 2>/dev/null || true
printf '{\n  "name": "%s",\n  "autorun": "%s"\n}\n' "$APP_NAME" "$RUN_EXE" > "$STAGE/idos.json"
echo "Copying your $APP_NAME data onto the device ..."
xcrun devicectl device copy to --device "$DEVICE_ID" --user mobile \
  --domain-type appDataContainer --domain-identifier "$BUNDLE_ID" \
  --source "$STAGE" --destination "Documents" || \
  echo "  (Data copy reported an issue — if the app boots to C:\\ , re-run this step.)"

# 8. Launch — boots straight into the game.
xcrun devicectl device process launch --terminate-existing --device "$DEVICE_ID" "$BUNDLE_ID" || true
echo
echo "Done. First run: trust the developer once under Settings > General >"
echo "  VPN & Device Management, then reopen. It boots straight into $APP_NAME."
