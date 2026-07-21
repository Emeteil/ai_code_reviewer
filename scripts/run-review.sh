#!/usr/bin/env bash
# Runs opencode on prompt.txt and strips any preamble before the review.
# Env: AI_REVIEW_MODEL, OPENCODE_API_KEY, OPENCODE_ARGS, FAIL_ON_ERROR
set -euo pipefail

# shellcheck disable=SC2086 # OPENCODE_ARGS is intentionally word-split into CLI args
if opencode run --model "$AI_REVIEW_MODEL" $OPENCODE_ARGS "$(cat prompt.txt)" > review_raw.md; then
  :
elif [ "$FAIL_ON_ERROR" = "true" ]; then
  echo "opencode run failed and fail-on-error is enabled." >&2
  exit 1
fi

if grep -qm1 '^## ' review_raw.md; then
  awk 'f || /^## / { print; f = 1 }' review_raw.md > review.md
else
  cp review_raw.md review.md
fi

echo "Review size: $(wc -c < review.md) bytes"
