# Jocker repo — agent instructions

## Instruction ownership and conflicts
- The current user request defines task scope and authorization. Preserve decisions already supplied; do not request them again.
- This file owns repository-wide stack, persistence, style, verification and delivery policy. Nested `AGENTS.md`, skills, agent profiles and editor rules specialize it without contradicting it.
- `правила игры/` owns game mechanics; accepted requirements in `docs/requirements/` own the additional product contract. Conflicts require an explicit product decision; proposed requirements do not authorize changes.
- Accepted ADRs own technical decisions within those contracts. `FOLDER_STRUCTURE_SPEC.md` owns placement and target boundaries; `project.pbxproj` records actual build membership.
- An authorized, ready task plan describes the intended change within those constraints. Code, tests and build configuration are evidence of current behavior, not authority to override accepted target behavior. Other plans, reviews and historical notes are context.
- For a conflict, identify the owning source and apply an already accepted decision. Ask only for an unresolved product or material architectural choice; continue independent work. Update stale dependent guidance in the same task.

## Stack (verified — not SwiftUI)
- UIKit (AppDelegate, view controllers) + SpriteKit (SKScene for gameplay)
- No SwiftUI, no Combine, no async/await in app-target code, no SPM/CocoaPods. Existing training-only Swift concurrency is allowed.
- Pure Swift services/coordinators. Settings use `UserDefaults`; game-session checkpoints and canonical statistics use atomic files with migration of legacy statistics, as specified by accepted [ADR-0001](docs/architecture/adr/0001-durable-game-session-persistence.md). Access storage through protocol-typed stores; presentation does not access storage backends directly.

## Project structure
- Xcode project at `Jocker/Jocker.xcodeproj` with 4 targets:
  - `Jocker` (app), `JockerTests` (unit), `JockerUITests` (UI), `JockerSelfPlayTools` (training static library)
- Training engine/runner sources are excluded from the app. `Jocker/JockerSelfPlayTools/main.swift` is standalone CLI-only, not an Xcode target input. See the target table in `FOLDER_STRUCTURE_SPEC.md`.
- Read `FOLDER_STRUCTURE_SPEC.md` before making structural changes; update it after

## One type per file
- New top-level class/enum/struct → new file matching the type name exactly; existing nested helper types and extensions are allowed.
- App source under `Jocker/Jocker/`, tests under `Jocker/JockerTests/`

## Verification entry point
- `make harness-doctor` checks Xcode, shared scheme, xcresulttool support and boots an eligible simulator; verification invokes it automatically before builds.
- `make harness-plan BASE=<ref>` explains checks for the diff from the merge base, including local and untracked files.
- `make harness-verify BASE=<ref>` executes them and saves a versioned JSON report. Overlapping XCTest selections are combined; full-suite execution covers pack tests, while pack dry-run contracts remain separate.
- `BASE` defaults to `HEAD` for local uncommitted work; use `origin/main` for a task branch.
- Verification always checks Xcode source membership. Local Results/Statistics/History/Settings changes use module test groups; CI retains the full suite.
- A passed report validates checks for its recorded source fingerprint; it does not replace tuning acceptance or product review.
- Use targeted tests during iteration. Completion uses the harness-selected mandatory checks; a passing combined run satisfies its selected groups and packs. Do not rerun covered tests solely because another instruction names their standalone command.
- Reuse verification after a conflict-free merge when the candidate and integrated source trees match. Repeat affected checks when source content, integration or the relevant environment changes.

## Workspaces and delivery
- Implement code changes in a dedicated worktree using `task-worktree`. New task branches use `codex/JCR-NNN-short-name` or `codex/TASK-NNN-short-name`; preserve an existing plan's declared branch when resuming, including legacy names.
- For authorized implementation-plan execution, completion means verified local integration into `main` and updated task evidence. For other requests, follow the requested deliverable; analysis or planning alone does not authorize implementation.
- Push, remote PR creation, CI execution and release publication require authorization covering that action. Local implementation does not imply remote publication. CI still runs the full suite when invoked.
- Remove only this task's clean, merged worktree/branch after preserving required evidence; keep unfinished work. `task-worktree` owns the mechanics.

## Commands
| What | How |
|---|---|
| Run all tests | `bash scripts/run_all_tests.sh` |
| Run a single test class | `xcodebuild test -project Jocker/Jocker.xcodeproj -scheme Jocker -destination "platform=iOS Simulator" -only-testing:JockerTests/BotTurnCandidateRankingServiceTests` |
| Bot training (canonical) | `make bt` or `make train-bot` |
| Bot training (final ensemble) | `make train-bot-final` |
| Training pipeline smoke | `make training-pipeline-smoke` |
| JOKER regression pack | `make joker-pack` / `make joker-pack-all` |
| Phase guardrails pack | `make stage4-phase-pack` |
| Ranking guardrails pack | `make stage6b-pack` / `make stage6b-pack-all` |
| Baseline snapshot | `make bot-baseline` |
| A/B comparison | `make bot-compare` |
| Scope validation | `make stage3-scope-validate` |
| Parallel benchmark | `make stage5-benchmark` |
| List regression tests (dry) | `make <pack>-list` or `make <pack>-dry` |

## Testing
- Harness reports and child test artifacts go to `.derivedData/harness-runs/<run-id>/` (gitignored). Standalone scripts retain their `.derivedData/` defaults.
- CI (GitHub Actions, `macos-15`) runs `make harness-ci`: instruction checks, harness tests and full Xcode tests; bot training is not scheduled automatically.
- Test placement follows the source-to-test mapping in `FOLDER_STRUCTURE_SPEC.md`; existing feature groups are preserved.
- Regression packs are shell scripts that run `xcodebuild test -only-testing:...` with targeted test lists

## Bot AI
- Bot training/retraining, including `training-pipeline-smoke`, is a separate task run only when explicitly requested by the user. Do not add it as a mandatory step after implementation, including bot changes, or to routine local/CI verification. Manual training commands remain available; replacing checked-in tuning still requires baseline + A/B evidence.
- Config lives in `BotRuntimePolicy` + `BotTuning` with difficulty presets (`easy`/`normal`/`hard`)
- Self-play evolution is a CLI tool (`JockerSelfPlayTools/main.swift`); not part of the app runtime
- All training/baseline/benchmark scripts shell out to `train_bot_tuning.sh`

## Style conventions
- Classes for SpriteKit nodes and UIKit VCs; structs for models/services (prefer value types)
- Protocols for testability (e.g., `GameStatisticsStore` / `FileGameStatisticsStore`)
- Default parameter labels, full `.self` for type references
- Explicit `self.` in instance methods

## Requirements and backlog workflow
- `docs/requirements/README.md` defines the product registry, decision and implementation states.
- For game mechanics, `правила игры/` remains the primary source; a conflicting REQ requires an explicit product decision before implementation.
- Every active backlog card and unfinished backlog plan carries requirements metadata. Behavior-changing work references REQ; behavior-preserving work may use `none` with a reason. `pending` belongs only in needs-clarification.
- Proposed requirements do not authorize implementation. Record explicit decisions already supplied by the user; do not request them again.
- Update affected requirements, their history and CHANGELOG in the same task as the behavior change. Mark implemented only with evidence in main.
- Before backlog work read `backlog/AGENTS.md`. Capture `зафиксируй` / `зафикчируй` text verbatim into `backlog/inbox/YYYY-MM-DD.md` (user's current date), appending without triage.
- Use `codex-backlog-skill` for requested triage/status reconciliation, `product-plan-clarification` for product questions, `tasks-ready-to-implementation` for planning, and `implement-release-plan` for authorized execution.
- Historical plans in docs/ require an up-to-date backlog card and requirements mapping when resumed; they are not automatically executable.
- `make requirements-check BASE=<ref>` validates traceability and requirements CHANGELOG co-change; the verification harness and CI include it.

## Maintaining instructions
- Change a rule in its owning source first (see Instruction ownership and conflicts); update dependent links/guidance in the same task. Skills own procedures, agent profiles own role boundaries, and editor rules are entry points into those sources.
- Keep reusable instructions separate from historical task status. Backlog cards own task progress; structural documentation links to them rather than copying their current status into several sections.
- After adding, removing, renaming or changing skill/profile metadata, run `python3 scripts/harness/instructions.py catalog --write`. Do not hand-edit the generated section in `docs/AGENTS_SKILLS_HARNESS.md`.
- `python3 scripts/harness/verify.py instructions` checks required entry points, known affirmative stack conflicts, metadata, local file links and catalog drift. It is also part of the harness; it does not prove semantic consistency, product acceptance or external-link availability.
