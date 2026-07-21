#!/usr/bin/env bash
# Builds diff.txt / diff_trimmed.txt and pr_context.txt from the PR.
# Env: BASE_SHA, HEAD_SHA, PR_TITLE, PR_BODY, MAX_DIFF_BYTES, SNIPPETS_DIR, GITHUB_ACTION_PATH
set -euo pipefail

source "$GITHUB_ACTION_PATH/scripts/lib.sh"

MERGE_BASE="$(git merge-base "$BASE_SHA" "$HEAD_SHA" || echo "$BASE_SHA")"

git diff "$MERGE_BASE" "$HEAD_SHA" > diff.txt
head -c "$MAX_DIFF_BYTES" diff.txt > diff_trimmed.txt

{
  echo "PR TITLE: ${PR_TITLE:-(none)}"
  echo ""
  echo "PR DESCRIPTION:"
  echo "${PR_BODY:-(none)}"
  echo ""
  echo "COMMITS:"
  git log --no-merges --pretty=format:'- %s' "$MERGE_BASE".."$HEAD_SHA" || true
  echo ""
  echo ""
  echo "CHANGED FILES:"
  git diff --name-status "$MERGE_BASE" "$HEAD_SHA" || true
} > pr_context.txt

if [ "$(wc -c < diff.txt)" -gt "$MAX_DIFF_BYTES" ]; then
  TRUNC="$(load_snippet diff-truncated.md)"
  echo "" >> diff_trimmed.txt
  echo "${TRUNC//\{\{MAX_DIFF_BYTES\}\}/$MAX_DIFF_BYTES}" >> diff_trimmed.txt
fi
