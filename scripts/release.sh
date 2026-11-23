#!/usr/bin/env bash
# Produces dist/AgentAwake-<version>.zip for a GitHub release and prints its SHA-256 (for the Homebrew cask).
#
#   VERSION=1.0.0 ./scripts/release.sh
#       ad-hoc signed build (works, but Gatekeeper warns on first open)
#
#   VERSION=1.0.0 SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=agentawake ./scripts/release.sh
#       Developer ID signed + notarized + stapled (opens without warnings).
#       Create the profile once: xcrun notarytool store-credentials agentawake --apple-id … --team-id … --password <app-specific>
set -euo pipefail
cd "$(dirname "$0")/.."
: "${VERSION:?set VERSION, e.g. VERSION=1.0.0}"
export VERSION

./scripts/build.sh

mkdir -p dist
ZIP="dist/AgentAwake-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent build/AgentAwake.app "$ZIP"

if [[ -n "${SIGN_IDENTITY:-}" && "$SIGN_IDENTITY" != "-" ]]; then
  : "${NOTARY_PROFILE:?set NOTARY_PROFILE to a notarytool keychain profile}"
  xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple build/AgentAwake.app
  rm -f "$ZIP"
  ditto -c -k --keepParent build/AgentAwake.app "$ZIP"
fi

echo "Release artifact: $ZIP"
shasum -a 256 "$ZIP"
