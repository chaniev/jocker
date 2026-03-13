# Codex MCP and Skills Setup for Jocker

Last verified: 2026-03-13

## Why this setup

This repository is a native iOS project built around Swift, UIKit, SpriteKit, XCTest, Xcode, and GitHub Actions. The most useful Codex extensions for this repo are the ones that improve:

- Xcode build and test execution
- GitHub PR, issue, and CI workflow access
- Large-repo semantic navigation for Swift code

Relevant local indicators:

- `Jocker/Jocker/ViewControllers/GameFlow/GameViewController.swift` imports `UIKit` and `SpriteKit`
- `Jocker/JockerTests/Flow/GameFlowIntegrationTests.swift` imports `XCTest`
- `Makefile` and `.github/workflows/ios-tests.yml` center the workflow around `xcodebuild` and GitHub CI

## Recommended MCP Servers

### Install now

1. `github`

Purpose: PRs, issues, workflow runs, CI failures, and review coordination.

Source: <https://github.com/github/github-mcp-server>

2. `xcodebuild`

Purpose: Xcode builds, tests, simulator control, and native Apple-platform workflows.

Source: <https://github.com/getsentry/xcodebuildmcp>

Why it matters here: this is the highest-leverage MCP server for this repo because the project is Xcode-first.

### Optional but useful

3. `serena`

Purpose: semantic code navigation and larger refactors in a non-trivial codebase.

Source: <https://github.com/oraios/serena>

Why it matters here: useful for the large AI, game-flow, scoring, and test surfaces in this repo.

## Ready `config.toml`

Put this into `~/.codex/config.toml` and adjust secrets as needed.

```toml
[mcp_servers.github]
command = "docker"
args = [
  "run",
  "-i",
  "--rm",
  "-e",
  "GITHUB_PERSONAL_ACCESS_TOKEN",
  "ghcr.io/github/github-mcp-server"
]
env = { GITHUB_PERSONAL_ACCESS_TOKEN = "github_pat_replace_me" }

[mcp_servers.xcodebuild]
command = "npx"
args = ["-y", "xcodebuildmcp@latest"]

[mcp_servers.serena]
command = "uvx"
args = [
  "--from",
  "git+https://github.com/oraios/serena",
  "serena",
  "start-mcp-server",
  "--context",
  "codex"
]
```

Prerequisites:

- Docker for `github`
- Node.js/npm for `xcodebuild`
- `uv`/`uvx` for `serena`
- Restart Codex after config changes

## Recommended Skills

From the current OpenAI curated skills catalog, these are the best fit for this repository:

- `gh-fix-ci`: useful when GitHub Actions or branch checks fail
- `gh-address-comments`: useful when iterating on PR review feedback
- `screenshot`: useful for UI regression checks, modal layout review, and visual validation
- `security-review`: useful before merging larger refactors or gameplay/serialization changes
- `openai-docs`: useful when Codex or OpenAI API documentation needs to be consulted inside the workflow

## Skill install command

This environment already includes the system `skill-installer`. Use it like this:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo openai/skills \
  --path skills/.curated/gh-fix-ci \
  --path skills/.curated/gh-address-comments \
  --path skills/.curated/screenshot \
  --path skills/.curated/security-review \
  --path skills/.curated/openai-docs
```

Restart Codex after installing skills.

## Not recommended for this repo right now

- `playwright`
- `playwright-interactive`
- `vercel-deploy`
- `netlify-deploy`
- `render-deploy`
- most browser-first or web-deployment-only skills

Reason: this repository is a native iOS app, not a browser-first web product.

## Verification Sources

- OpenAI Codex MCP docs: <https://developers.openai.com/codex/mcp>
- OpenAI Codex Skills docs: <https://developers.openai.com/codex/skills>
- OpenAI curated skills listing: <https://api.github.com/repos/openai/skills/contents/skills/.curated>
- GitHub MCP server: <https://github.com/github/github-mcp-server>
- XcodeBuildMCP: <https://github.com/getsentry/xcodebuildmcp>
- Serena: <https://github.com/oraios/serena>
