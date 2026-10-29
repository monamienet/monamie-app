#!/usr/bin/env bash
# Prints the versionName of the build being deployed (rules: AGENTS.md,
# "Releases"), computed from the Conventional Commits since the last v* tag:
#   - a "Release-As: X.Y.Z" footer in any commit wins (the human's call for
#     a new major version);
#   - otherwise feat: commits touching the app (lib/, android/, assets/) bump
#     the minor, fix: commits the patch;
#   - otherwise the version stays the same (nothing user-visible changed).
# With no v* tag yet, the version in pubspec.yaml is used as is.
# In CI it also writes name=<version> and new=<true|false> to $GITHUB_OUTPUT;
# new is true when that version has no tag yet.
set -euo pipefail

output() {
  echo "$1"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    { echo "name=$1"; echo "new=$2"; } >> "$GITHUB_OUTPUT"
  fi
}

if ! last=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null); then
  output "$(sed -n 's/^version: \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' pubspec.yaml)" true
  exit 0
fi
IFS=. read -r major minor patch <<< "${last#v}"

release_as=$(git log --format=%B "$last..HEAD" \
  | sed -n 's/^Release-As: *\([0-9]*\.[0-9]*\.[0-9]*\) *$/\1/p' | head -n 1)
subjects=$(git log --no-merges --format=%s "$last..HEAD" -- lib android assets)

if [ -n "$release_as" ]; then
  next=$release_as
elif grep -qE '^feat(\([^)]*\))?:' <<< "$subjects"; then
  next="$major.$((minor + 1)).0"
elif grep -qE '^fix(\([^)]*\))?:' <<< "$subjects"; then
  next="$major.$minor.$((patch + 1))"
else
  next="$major.$minor.$patch"
fi

if git rev-parse -q --verify "refs/tags/v$next" > /dev/null; then
  output "$next" false
else
  output "$next" true
fi
