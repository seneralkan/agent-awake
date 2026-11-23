#!/usr/bin/env bash
# Builds build/AgentAwake.app (universal: Apple silicon + Intel).
#
#   ./scripts/build.sh              build only
#   ./scripts/build.sh --install    build, copy to ~/Applications, (re)launch
#
# Env:
#   VERSION=1.2.0                         version written into Info.plist
#                                         (default: from git — "1.2.0" on a tagged commit, "1.2.0-dev" after it)
#   SIGN_IDENTITY="Developer ID Application: …"   sign for distribution (default: ad-hoc "-")
#   ARCHS="arm64"                         build fewer architectures (default: "arm64 x86_64")
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${VERSION:-}" ]]; then
  if tag=$(git describe --tags --exact-match 2>/dev/null); then
    VERSION="${tag#v}"
  elif tag=$(git describe --tags --abbrev=0 2>/dev/null); then
    VERSION="${tag#v}-dev"
  else
    VERSION="0.0.0-dev"
  fi
fi
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ARCHS="${ARCHS:-arm64 x86_64}"

binaries=()
for arch in $ARCHS; do
  swift build -c release --triple "$arch-apple-macosx13.0"
  binaries+=(".build/$arch-apple-macosx/release/AgentAwake")
done

APP=build/AgentAwake.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "${binaries[@]}" -output "$APP/Contents/MacOS/AgentAwake"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi
echo "Built $APP ($VERSION, $(lipo -archs "$APP/Contents/MacOS/AgentAwake"))"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x AgentAwake || true
  rm -rf ~/Applications/AgentAwake.app
  mkdir -p ~/Applications
  cp -R "$APP" ~/Applications/
  open ~/Applications/AgentAwake.app
  echo "Installed to ~/Applications/AgentAwake.app"
fi
