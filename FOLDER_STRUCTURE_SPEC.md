# Folder Structure Spec (Jocker)

## Scope

This document owns placement, type/file conventions and intended build boundaries.
[AGENTS.md](AGENTS.md) owns stack, persistence, verification and delivery policy.
Rules, accepted requirements and ADRs own behavior; this is not a file inventory
or a task-status ledger. Inspect the filesystem for the current file list.

Concrete repository paths below start with `./` and are checked by the instruction
validator. A trailing `/` requires a directory; a glob requires at least one match.
Paths containing `<placeholders>` and fenced examples are templates, not existence
claims. Markdown links are also checked. All paths are relative to the repo root.

## Build Target Boundaries

| Build | Purpose and membership |
|---|---|
| `Jocker` | UIKit/SpriteKit app; runtime sources, including app-only persistence DTOs/stores |
| `JockerTests` | Unit/integration tests; may link the training library |
| `JockerUITests` | XCUITest sources |
| `JockerSelfPlayTools` | Xcode static library: training engine, adapter, runner and selected shared runtime sources; never linked into the app |
| Standalone CLI | Built by `./scripts/train_bot_tuning.sh`; training/shared sources plus `./Jocker/JockerSelfPlayTools/main.swift`, which belongs to no Xcode Sources phase |

- `./Jocker/Jocker.xcodeproj/project.pbxproj` records actual membership;
  `./Jocker/Jocker.xcodeproj/xcshareddata/xcschemes/Jocker.xcscheme` is the shared scheme.
- Training-only sources are `./Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine*.swift`,
  `./Jocker/Jocker/Game/Services/AI/BotTuning+SelfPlayEvolution.swift` and
  `./Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`. Their directory does not
  imply app membership. Existing training-only concurrency is allowed; runtime
  sources shared with training retain app constraints.
- Register Swift files in the appropriate Sources phases. Keep Xcode groups aligned
  with filesystem directories. The existing membership validator owns the check;
  conditional exclusions, synchronized groups and generated-source build rules
  require extending it before use.

## Repository Layout

| Location | Responsibility |
|---|---|
| `./Jocker/Jocker/` | App and shared Swift sources; training exceptions above |
| `./Jocker/JockerSelfPlayTools/` | Training runner and standalone CLI entrypoint |
| `./Jocker/JockerTests/`, `./Jocker/JockerUITests/` | Unit/integration and UI tests |
| `./.agents/skills/`, `./.codex/agents/`, `./.cursor/rules/` | Procedures, agent roles and editor entrypoints; inventory in the [generated catalog](docs/AGENTS_SKILLS_HARNESS.md#каталог) |
| `./backlog/` | Task cards, plans and logs; [queue/lifecycle contract](backlog/README.md#обработка-требований) |
| `./docs/requirements/` | Product contract and decision history |
| `./docs/architecture/adr/` | Architectural decisions |
| `./docs/` | Project guides, reviews and historical plans |
| `./scripts/`, `./Makefile` | Developer automation and command entrypoints |
| `./scripts/harness/`, `./scripts/harness/tests/` | Verification tooling and its Python tests; outside Xcode targets |
| `./.github/workflows/`, `./.github/pull_request_template.md` | CI and review template |
| `./правила игры/` | Authoritative game-rule texts |

Backlog queues are created when first used: `./backlog/<queue>/` is a template.
Completed cards/plans use `./backlog/done/<YYYY-MM-DD>/`. Their lifecycle and
verification evidence belong in the cards; logs are append-only.

## App Source Layout

| Location | Responsibility |
|---|---|
| `./Jocker/Jocker/App/` | Application lifecycle and dependency setup |
| `./Jocker/Jocker/Core/` | Shared primitives |
| `./Jocker/Jocker/Models/` | Domain/state models grouped into Bot, Cards, Gameplay, History, Joker, Players, Statistics |
| `./Jocker/Jocker/Scoring/` | Score calculation, premiums and accumulated scores |
| `./Jocker/Jocker/Game/Scenes/` | SpriteKit scene lifecycle, interaction, rendering and flow extensions |
| `./Jocker/Jocker/Game/Nodes/` | SpriteKit presentation nodes |
| `./Jocker/Jocker/Game/Coordinator/` | Game orchestration, presentation and persistence coordination |
| `./Jocker/Jocker/Game/Services/AI/` | Bot services and the explicit training-only exceptions above |
| `./Jocker/Jocker/Game/Services/Flow/` | Round/turn orchestration and animation services |
| `./Jocker/Jocker/Game/Services/History/` | Deal capture and export |
| `./Jocker/Jocker/Game/Services/Persistence/` | Session store, codec, repository and persistence errors |
| `./Jocker/Jocker/Game/Services/Settings/` | Player settings storage |
| `./Jocker/Jocker/Game/Services/Statistics/` | Statistics contracts, canonical file store and legacy migration adapter |
| `./Jocker/Jocker/ViewControllers/` | UIKit flows: Bidding, GameFlow, Results, Statistics; shared views/style in Common |
| `./Jocker/Jocker/Resources/`, `./Jocker/Jocker/Assets.xcassets/`, `./Jocker/Jocker/Base.lproj/` | SpriteKit resources, assets and storyboards |

Scenes and controllers present domain state; rules/scoring stay in the domain core
and its services. Use the existing owning layer before adding another directory.

## Test Targets Layout

The following mapping owns test placement. Specific rows take precedence over
broader rows. Preserve existing feature groups and suites; do not relocate tests
solely to make the directory tree symmetrical.

| Source responsibility | Test location |
|---|---|
| Bot models, AI services, training engine/runner | `./Jocker/JockerTests/Bot/` |
| BiddingRules, TrickTakingResolver | `./Jocker/JockerTests/Rules/` |
| GameState, flow services, gameplay scenes/coordinators | `./Jocker/JockerTests/Flow/` |
| Session persistence models | `./Jocker/JockerTests/Models/Gameplay/` |
| Session stores, restore and completion recovery/coordinator | `./Jocker/JockerTests/Game/Services/Persistence/` |
| Scene persistence and session lifecycle | `./Jocker/JockerTests/Game/Scenes/` |
| Other card/gameplay/history/joker/player models | `./Jocker/JockerTests/Models/` |
| PlayerDisplayNameFormatter and settings services | `./Jocker/JockerTests/Players/` |
| History services | `./Jocker/JockerTests/History/` |
| Scoring | `./Jocker/JockerTests/Scoring/` |
| Results controllers/views/builders | `./Jocker/JockerTests/Results/` |
| Statistics models/services/controllers | `./Jocker/JockerTests/Statistics/` |
| End-to-end UI flows | `./Jocker/JockerUITests/` |

- Existing integration suites can span types. Keep shared bot builders/fixtures in
  `./Jocker/JockerTests/Bot/`; other fixtures stay with their owning suite.
  Frozen session-schema fixtures live in `./Jocker/JockerTests/Models/Gameplay/Fixtures/`.
- For an area absent from the table, mirror its full app-relative directory under
  `./Jocker/JockerTests/`. Example only: `./Jocker/JockerTests/ViewControllers/<flow>/`.
  Add a mapping exception here only when the new responsibility needs one.
- XCTest mechanics and isolated setup are in [xctest-practices](.agents/skills/xctest-practices/SKILL.md).

## Type/File Rule

- Each new top-level class, struct, enum or protocol gets a file named exactly
  after that type. Apply this to test classes and shared fixtures too.
- Nested helper types remain with their owning type. Extensions may stay in that
  file or use `Type+Purpose.swift`; existing test extension names are retained.
- Existing multi-type files do not authorize new unrelated top-level types and
  do not require a broad cleanup during an unrelated change.

## Persistence and Artifacts

- Session DTOs live with their domains under Models; score snapshots live under
  Scoring. Session DTOs and persistence stores are app-only. Shared game/score
  models expose passive model-typed restore APIs usable by the training target.
- [ADR-0001](docs/architecture/adr/0001-durable-game-session-persistence.md) owns
  durability, migration and recovery. Player files live in Application Support,
  outside the repository; presentation accesses protocol-typed stores.
- Build/test/training outputs stay in gitignored `./.derivedData/<run-directory>/`.
  Harness reports and child artifacts use `./.derivedData/harness-runs/<run-id>/`;
  standalone scripts retain their documented defaults. Committed deterministic
  test fixtures are source data, not generated run output.
- Harness implementation/report details are in [the harness guide](docs/AGENTS_SKILLS_HARNESS.md).
  Training commands are in [bot-training-pipeline](.agents/skills/bot-training-pipeline/SKILL.md);
  regression commands are in [regression-packs](.agents/skills/regression-packs/SKILL.md).

## Maintaining This Contract

Read this specification before adding, moving or renaming files. Update it when a
layer, placement mapping, build boundary or concrete referenced path changes.
Adding a file to an existing documented area does not require a manual inventory
entry. Keep examples/templates explicit; retain no dated task-status sections.

Use [folder-structure](.agents/skills/folder-structure/SKILL.md) for the change
procedure and the root verification contract for completion. Instruction checks
validate concrete paths and links; Xcode membership is checked separately.
