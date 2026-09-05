# Jocker repo — agent instructions

## Stack (verified — not SwiftUI)
- UIKit (AppDelegate, view controllers) + SpriteKit (SKScene for gameplay)
- No SwiftUI, no Combine, no async/await, no SPM/CocoaPods
- Pure Swift services/coordinators, `UserDefaults` for persistence

## Project structure
- Xcode project at `Jocker/Jocker.xcodeproj` with 4 targets:
  - `Jocker` (app), `JockerTests` (unit), `JockerUITests` (UI), `JockerSelfPlayTools` (training CLI)
- `JockerSelfPlayTools` is a separate target — its sources (`BotSelfPlayEvolutionEngine+*.swift`, `BotTuning+SelfPlayEvolution.swift`, `BotTrainingRunner.swift`, `main.swift`) are NOT compiled into the app
- Read `FOLDER_STRUCTURE_SPEC.md` before making structural changes; update it after

## One type per file
- New class/enum/struct → new file matching the type name exactly
- App source under `Jocker/Jocker/`, tests under `Jocker/JockerTests/`

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
- All test artifacts go to `.derivedData/test-runs/<timestamp>/` (gitignored)
- CI (GitHub Actions, `macos-15`) runs: `run_all_tests.sh` → `run_training_pipeline_smoke.sh`
- Test file placement mirrors app structure under `Jocker/JockerTests/<feature>/`
- Regression packs are shell scripts that run `xcodebuild test -only-testing:...` with targeted test lists

## Bot AI
- Config lives in `BotRuntimePolicy` + `BotTuning` with difficulty presets (`easy`/`normal`/`hard`)
- Self-play evolution is a CLI tool (`JockerSelfPlayTools/main.swift`); not part of the app runtime
- All training/baseline/benchmark scripts shell out to `train_bot_tuning.sh`

## Style conventions
- Classes for SpriteKit nodes and UIKit VCs; structs for models/services (prefer value types)
- Protocols for testability (e.g., `GameStatisticsStore` / `UserDefaultsGameStatisticsStore`)
- Default parameter labels, full `.self` for type references
- Explicit `self.` in instance methods
