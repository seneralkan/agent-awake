#!/usr/bin/env bash
# One-command release: ./scripts/ship.sh 1.1.0
# Tags vX.Y.Z on the current main and pushes. The Release workflow then builds the app,
# publishes the GitHub release and bumps the Homebrew cask in <owner>/homebrew-tap.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?usage: ./scripts/ship.sh X.Y.Z}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must look like 1.2.3"; exit 1; }
[[ "$(git branch --show-current)" == "main" ]] || { echo "switch to main first"; exit 1; }
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || { echo "commit or stash your changes first"; exit 1; }
git fetch -q origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || { echo "main is not in sync with origin/main (pull or push first)"; exit 1; }
git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null && { echo "tag v$VERSION already exists"; exit 1; }

git tag -a "v$VERSION" -m "AgentAwake $VERSION"
git push -q origin "v$VERSION"
echo "Pushed v$VERSION. Follow the release: gh run watch \$(gh run list --workflow Release --limit 1 --json databaseId -q '.[0].databaseId')"
