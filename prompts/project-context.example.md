# Project context

> This is a template. Copy it into your repository (default location:
> `.github/ai-review/project-context.md`) and replace the content below with your
> own project's details: stack, code style, architecture, and any rules the
> reviewer must respect. The more concrete it is, the more useful the review.
> If you don't need project context, set the action input `project-context-file`
> to an empty value (or point it at a non-existent path) and it is skipped.

## What to review and what to ignore

State which code to review and which files to skip even when they appear in the
diff. Typical things worth **ignoring** (adjust to your project):

- CI/config and infrastructure: `.github/` (workflows, the reviewer's own prompts,
  `*.yml`), `.gitignore`, `.editorconfig`, lock files, `Dockerfile`, build configs.
- Third-party / vendored dependencies: `node_modules/`, `vendor/`, `third_party/`,
  generated code.
- Binary and service files.

If the diff contains no code that falls under review, say so in the summary and do
not invent findings about config files.

## Always read the PR description and comments

Before reviewing, read `PR DESCRIPTION` from `PR / GIT CONTEXT`, and the PR
comments in the `pr-comments/others/` folder (via your file-reading tools).
Replies to previous-pass findings are written both in the description and in the
comments — check both sources. Do not re-raise anything already resolved or
explained there; a justification removes a nitpick but does not cancel a real bug.

## Stack

- Language / framework: <e.g. TypeScript + React, Python + FastAPI, C# + Unity>
- Package manager / build: <npm, pnpm, poetry, dotnet, ...>

## Code style

Describe the mandatory style rules (naming, formatting, file structure, forbidden
practices). The reviewer flags violations as a separate category.

- Naming: <...>
- Formatting: <...>
- Forbidden: <...>

## Architecture and patterns

Describe the patterns, layers and key modules used in the project, and what to
avoid. The reviewer uses this when assessing the design of changes.

- <...>
