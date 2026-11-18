# Jocker repo — agent instructions

## Stack (verified — not SwiftUI)
- UIKit (AppDelegate, view controllers) + SpriteKit (SKScene for gameplay)
- No SwiftUI, no Combine, no async/await in app-target code, no SPM/CocoaPods. Existing training-only Swift concurrency is allowed.
- Pure Swift services/coordinators. Settings use `UserDefaults`; game-session checkpoints and canonical statistics use atomic files with migration of legacy statistics, as specified by accepted [ADR-0001](docs/architecture/adr/0001-durable-game-session-persistence.md). Access storage through protocol-typed stores; presentation does not access storage backends directly.

## Project structure
- Xcode project at `Jocker/Jocker.xcodeproj` with 4 targets:
  - `Jocker` (app), `JockerTests` (unit), `JockerUITests` (UI), `JockerSelfPlayTools` (training CLI)
- `JockerSelfPlayTools` is a separate target — its sources (`BotSelfPlayEvolutionEngine+*.swift`, `BotTuning+SelfPlayEvolution.swift`, `BotTrainingRunner.swift`, `main.swift`) are NOT compiled into the app
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
- Test file placement mirrors app structure under `Jocker/JockerTests/<feature>/`
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
