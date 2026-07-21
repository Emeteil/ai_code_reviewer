#!/usr/bin/env bash
# Shared helpers. Resolves a snippet by name: a file with the same name in
# SNIPPETS_DIR (if set and present) wins over the bundled prompts/snippets/.
load_snippet() {
  local name="$1"
  if [ -n "${SNIPPETS_DIR:-}" ] && [ -f "$SNIPPETS_DIR/$name" ]; then
    cat "$SNIPPETS_DIR/$name"
  else
    cat "$GITHUB_ACTION_PATH/prompts/snippets/$name"
  fi
}
