# AI Code Reviewer

**English** · [Русский](README_RU.md)

A GitHub Action that automatically reviews every Pull Request with an agentic LLM
([opencode](https://opencode.ai)) and leaves a structured comment.

> **Completely free — no sign-up, no API key.** opencode offers several models for
> free without registration or API keys. So you can wire the reviewer into your
> project at zero cost: just add the workflow, no secrets required.
>
> ⚠️ **Not recommended for sensitive code.** Free models may log or train on the
> data you send them. Do **not** use them for enterprise/proprietary code or
> anything sensitive to ending up in a training dataset. For such projects, don't
> use the store version (`uses: Emeteil/ai_code_reviewer@v1`) — copy `action.yml`/
> the workflow into your repo and adapt it to your self-hosted model. In a
> corporate environment, also prefer an internal npm mirror (and other internal
> mirrors/proxies) over the public registry.

## Features

- **Structured output**: summary → 🔴 critical → 🟡 non-critical → 🏛️ architecture → ✅ what's good.
- **Agentic repo access**: the reviewer reads neighbouring files for context, but
  comments **only on the diff** (approved code is left alone).
- **PR context**: the title, description, commit messages and changed files are fed
  into the prompt.
- **Memory across runs**: the previous review of the same PR is fed back in — the
  agent notes what's fixed and avoids repeating itself. Comments from other
  reviewers are saved to `pr-comments/others/` for the agent to read on demand
  (e.g. when the author explains *why* the code is written a certain way).
- **Code style checks** from your project context file.
- **One comment per PR**: on new pushes the existing comment is updated instead of
  spamming new ones (switch with `comment-mode: create`).
- **Fully configurable** via action inputs, with sensible defaults — works out of
  the box.
- **Prompts in separate files** — edit them without touching YAML.

## Quick start

Add a workflow to your repository at `.github/workflows/ai-review.yml`:

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: Emeteil/ai_code_reviewer@v1.0.2
        with:
          language: English
          # Only needed if the chosen model requires a provider key:
          opencode-api-key: ${{ secrets.OPENCODE_API_KEY }}
```

That's it — every PR gets a review comment. See [`examples/ai-review.yml`](examples/ai-review.yml).

## Inputs

All inputs are optional.

| Input | Description | Default |
| --- | --- | --- |
| `model` | opencode model id | `""` (opencode default) |
| `language` | Language of the review output | `English` |
| `max-diff-bytes` | Max diff size (bytes) included in the prompt | `40000` |
| `main-prompt-file` | Path to the core reviewer prompt (empty = bundled `prompts/main.md`) | `` (bundled) |
| `project-context-file` | Path in your repo to a project-specific context prompt; skipped if missing | `.github/ai-review/project-context.md` |
| `extra-instructions` | Extra one-off instructions appended to the prompt | `` |
| `title` | Heading used for the PR comment | `🤖 AI Code Review` |
| `comment-mode` | `update` (edit one comment) or `create` (new each run) | `update` |
| `include-previous` | Feed the previous AI review of this PR into the context | `true` |
| `include-comments` | Save other reviewers' comments into `pr-comments/others/` | `true` |
| `snippets-dir` | Directory in your repo overriding the bundled `prompts/snippets/*.md` (per-file; missing ones fall back) | `` (bundled) |
| `comment-marker` | Hidden marker identifying the comment; change it to run several independent reviewers on one PR | `<!-- ai-code-review -->` |
| `opencode-args` | Extra CLI args passed to `opencode run` | `` |
| `fail-on-error` | Fail the job if the model call fails, instead of posting a fallback comment | `false` |
| `opencode-api-key` | API key for the opencode provider (if the model needs one) | `` |
| `github-token` | Token used to read PR data and post the comment | `${{ github.token }}` |

## Project context (recommended)

To make the review project-aware (stack, code style, architecture, what to ignore),
copy [`prompts/project-context.example.md`](prompts/project-context.example.md)
into your repo at `.github/ai-review/project-context.md` and fill it in. The action
picks it up automatically. Point `project-context-file` elsewhere, or set it empty
to disable.

## How it works

The action assembles a single prompt from several parts:

```
=== INSTRUCTIONS ===      (bundled prompts/main.md, {{LANGUAGE}} substituted)
=== EXTRA INSTRUCTIONS === (extra-instructions input, if set)
=== PROJECT CONTEXT ===    (project-context-file, if present)
=== PR / GIT CONTEXT ===   (title, description, commits, changed files)
=== PREVIOUS AI REVIEW === (previous review of this PR, if any and enabled)
=== OTHER PR COMMENTS ===  (pointer to pr-comments/others/, if any)
=== DIFF ===               (truncated PR diff, merge-base..head)
```

A dedicated step pulls the previous review into `pr-comments/previous_ai_review.md`
and other participants' comments (conversation, reviews, inline comments) into
`pr-comments/others/` (one file per comment). Then `opencode run` executes in the
repo root — the agent can read those files and the whole repository — and the
result is posted/updated as a PR comment.

## Customising the prompts

- `prompts/main.md` — the reviewer's role, rules and output format. Usually no need
  to change. The `{{LANGUAGE}}` placeholder is substituted from the `language` input.
- `project-context.md` (in your repo) — everything specific to your project.
- `prompts/snippets/*.md` — the small injected texts (section notes, the comment
  footer, fallback messages). Override any of them per-file via `snippets-dir`.

To override the bundled core prompt, point `main-prompt-file` at a file in your repo.

## Notes

- **Permissions**: the workflow needs `pull-requests: write` (to post the comment)
  and `contents: read`.
- **API key**: not required with the default free model — some opencode models run
  without registration or keys. For other/paid providers, pass `opencode-api-key`
  from a secret.
- **`language`** accepts any language name, e.g. `English`, `Русский`, `Deutsch`.

## License

[MIT](LICENSE) — free to use, modify and distribute; just keep the copyright and
license notice.
