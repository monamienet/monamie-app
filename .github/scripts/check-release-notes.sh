#!/usr/bin/env bash
# Checks the Play release notes in distribution/whatsnew/ before a build is
# uploaded (rules: AGENTS.md, "Releases"):
#   1. whatsnew-pt-BR and whatsnew-en-US exist and are not empty;
#   2. each has at most 500 characters, the Play limit per language;
#   3. if feat:/fix: commits touched the app (lib/, android/, assets/) since
#      the last v* tag, the notes were also changed since that tag.
# Check 3 needs the full history and tags (actions/checkout fetch-depth: 0)
# and is skipped while no release has been tagged.
set -euo pipefail
export LC_ALL=C.UTF-8

dir=distribution/whatsnew
max=500
failed=0

for lang in pt-BR en-US; do
  file="$dir/whatsnew-$lang"
  if [ ! -s "$file" ]; then
    echo "::error file=$file::Release notes missing or empty: $file"
    failed=1
    continue
  fi
  chars=$(wc -m < "$file")
  if [ "$chars" -gt "$max" ]; then
    echo "::error file=$file::$file has $chars characters; Play accepts at most $max."
    failed=1
  fi
done

if tag=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null); then
  app_changes=$(git log --format=%s "$tag..HEAD" -- lib android assets \
    | grep -E '^(feat|fix)(\([^)]*\))?:' || true)
  notes_changes=$(git log --format=%H "$tag..HEAD" -- "$dir")
  if [ -n "$app_changes" ] && [ -z "$notes_changes" ]; then
    echo "::error::App changes since $tag but $dir was not updated since then:"
    echo "$app_changes"
    failed=1
  fi
else
  echo "No v* tag yet: skipping the check that the notes follow the app changes."
fi

exit "$failed"
