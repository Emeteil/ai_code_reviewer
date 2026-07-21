#!/usr/bin/env bash
# Assembles prompt.txt from the prompt files, PR context and diff.
# Env: LANGUAGE, MAIN_PROMPT_FILE, PROJECT_CONTEXT_FILE, EXTRA_INSTRUCTIONS,
#      INCLUDE_PREVIOUS, INCLUDE_COMMENTS, SNIPPETS_DIR, GITHUB_ACTION_PATH
set -euo pipefail

source "$GITHUB_ACTION_PATH/scripts/lib.sh"

MAIN_PROMPT="${MAIN_PROMPT_FILE:-$GITHUB_ACTION_PATH/prompts/main.md}"

{
  echo "=== INSTRUCTIONS ==="
  echo ""
  if [ -f "$MAIN_PROMPT" ]; then
    MAIN_PROMPT_TEXT="$(cat "$MAIN_PROMPT")"
  else
    MAIN_PROMPT_TEXT="$(load_snippet fallback-instructions.md)"
  fi
  echo "${MAIN_PROMPT_TEXT//\{\{LANGUAGE\}\}/$LANGUAGE}"

  if [ -n "$EXTRA_INSTRUCTIONS" ]; then
    echo ""
    echo "=== EXTRA INSTRUCTIONS ==="
    echo "$EXTRA_INSTRUCTIONS"
  fi

  if [ -n "$PROJECT_CONTEXT_FILE" ] && [ -f "$PROJECT_CONTEXT_FILE" ]; then
    echo ""
    echo "=== PROJECT CONTEXT ==="
    echo ""
    cat "$PROJECT_CONTEXT_FILE"
  fi

  echo ""
  echo "=== PR / GIT CONTEXT ==="
  echo ""
  cat pr_context.txt

  if [ "$INCLUDE_PREVIOUS" != "false" ] && [ -f pr-comments/previous_ai_review.md ]; then
    echo ""
    echo "=== PREVIOUS AI REVIEW ==="
    echo ""
    load_snippet previous-review-note.md
    echo ""
    cat pr-comments/previous_ai_review.md
  fi

  if [ "$INCLUDE_COMMENTS" != "false" ] && [ -d pr-comments/others ] && [ -n "$(ls -A pr-comments/others 2>/dev/null)" ]; then
    echo ""
    echo "=== OTHER PR COMMENTS ==="
    echo ""
    load_snippet other-comments-note.md
    ls -1 pr-comments/others/ | sed 's/^/- pr-comments\/others\//'
  fi

  echo ""
  echo "=== DIFF (diff_trimmed.txt) ==="
  echo ""
  cat diff_trimmed.txt
} > prompt.txt

echo "Prompt size: $(wc -c < prompt.txt) bytes"
