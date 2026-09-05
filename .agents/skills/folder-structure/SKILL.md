---
name: folder-structure
description: Use before any structural change — adding, moving, or renaming files and directories in the Jocker repository — and after it, to keep FOLDER_STRUCTURE_SPEC.md authoritative. Covers the one-type-per-file rule, app/test placement mirroring, target boundaries, and artifact locations.
---

# Folder structure

`FOLDER_STRUCTURE_SPEC.md` is the source of truth for repository structure
and file placement. Read it before making structural changes; update it in
the same change afterwards.

## Core rules

- One type per file; the file name matches the type name exactly.
- App sources live under `Jocker/Jocker/`; unit tests under
  `Jocker/JockerTests/`; UI tests under `Jocker/JockerUITests/`.
- Test file placement mirrors app structure under
  `Jocker/JockerTests/<feature>/`.
- The Xcode project has four targets with fixed ownership:
  - `Jocker` — app;
  - `JockerTests` — unit tests;
  - `JockerUITests` — UI tests;
  - `JockerSelfPlayTools` — training CLI (`BotSelfPlayEvolutionEngine+*.swift`,
    `BotTuning+SelfPlayEvolution.swift`, `BotTrainingRunner.swift`,
    `main.swift`). These sources are NOT compiled into the app.
- A new source file must be added to the correct target membership in
  `project.pbxproj`; a file in the wrong target is a structural defect.

## Where things go

| Content | Location |
|---|---|
| Game rules logic, models | `Jocker/Jocker/Models/`, `Jocker/Jocker/Scoring/` |
| SpriteKit gameplay | `Jocker/Jocker/Game/` (Scenes, Nodes, Coordinator, Services) |
| Screens and navigation | `Jocker/Jocker/ViewControllers/` (Bidding, GameFlow, Results, Statistics, Common) |
| App bootstrap | `Jocker/Jocker/App/` |
| Cross-cutting helpers | `Jocker/Jocker/Core/` |
| Unit tests | `Jocker/JockerTests/<feature>/` mirroring app layout |
| Shell harness scripts | `scripts/` |
| Make wrappers | `Makefile` |
| Rules source texts | `правила игры/` (never edited as part of code tasks) |
| Plans, reviews, specs | `docs/` |
| Build/test/training artifacts | `.derivedData/` (gitignored, never committed) |

## Rules of engagement

- Before adding a directory or moving files, check the spec's Repository
  Layout and Placement Conventions sections; if the intended home does not
  exist, that is a structural decision — propose it and update the spec.
- After any structural change (new directories, moved files, new top-level
  artifacts, new scripts), update `FOLDER_STRUCTURE_SPEC.md` in the same
  change: the layout tree and the Tooling & Documentation entries.
- Do not commit artifacts: test runs, `.xcresult` bundles, training logs, and
  `bot-train-*.log` files belong under `.derivedData/`.
- Do not edit files under `правила игры/` as part of implementation; rule
  changes are product decisions routed through plans.
- Agent infrastructure lives in `.agents/skills/<name>/SKILL.md` and
  `.codex/agents/<name>.toml`; changes to that set update
  `docs/AGENTS_SKILLS_HARNESS.md`.

## Verification

For a structural change, report: files moved/added with old and new paths,
target membership updates, `FOLDER_STRUCTURE_SPEC.md` diff, and that
`bash scripts/run_all_tests.sh` still compiles the expected targets.
