# Jocker repo — agent instructions

## Instruction ownership and conflicts
- The current user request defines scope and authorization. Preserve supplied decisions; do not request them again.
- This file owns repository-wide stack, persistence, style, verification and delivery policy. Nested instructions specialize it; skills own procedures, agent profiles own role boundaries, editor rules are entrypoints.
- [Game rules](правила%20игры/) own mechanics; accepted [requirements](docs/requirements/README.md) own the additional product contract. Proposed requirements do not authorize implementation.
- Accepted [ADRs](docs/architecture/adr/README.md) own technical decisions within those contracts. [FOLDER_STRUCTURE_SPEC.md](FOLDER_STRUCTURE_SPEC.md) owns placement, type/file rules and build boundaries; project.pbxproj records actual membership.
- An authorized ready plan describes the intended change. Code/tests/build configuration are evidence, not authority to override accepted behavior; other plans and historical notes are context.
- Resolve conflicts through the owning source and accepted decisions. Ask only for unresolved product or material architectural choices; continue independent work and update stale dependent guidance.

## Stack and style
- UIKit + SpriteKit; no SwiftUI, Combine, async/await in app-target code, SPM or CocoaPods. Existing training-only concurrency is allowed.
- Classes for SpriteKit nodes/UIKit controllers; prefer structs for models/services and protocols for testability. Use default parameter labels, full `.self` type references and explicit `self.` in instance methods.
- Settings use UserDefaults; session checkpoints and canonical statistics use atomic files with legacy migration under [ADR-0001](docs/architecture/adr/0001-durable-game-session-persistence.md). Presentation accesses protocol-typed stores, never storage backends directly.
- Xcode project: `Jocker/Jocker.xcodeproj`. JockerSelfPlayTools is a training static library; its standalone CLI main is outside all Xcode Sources phases. Follow the [target table](FOLDER_STRUCTURE_SPEC.md#build-target-boundaries).
- Before structural changes use [folder-structure](.agents/skills/folder-structure/SKILL.md). Update the specification when its contract or referenced paths change; test placement follows its mapping.

## Verification entry point
- `make harness-plan BASE=<ref>` explains checks for the merge-base diff, including local/untracked files; `make harness-verify BASE=<ref>` executes them and saves versioned evidence.
- BASE defaults to HEAD for uncommitted work; use origin/main for a task branch. Doctor automatically prepares an eligible simulator before builds; `make harness-doctor` diagnoses it separately.
- Completion requires the harness-selected checks. Use targeted tests during iteration; combined/full XCTest runs cover selected groups/packs without repeats, while pack dry-run contracts remain separate. CI runs `make harness-ci` with the full suite.
- Reports and child artifacts go to `.derivedData/harness-runs/<run-id>/`; standalone scripts retain their defaults. A passed report validates its recorded source fingerprint, not product review or tuning acceptance.
- Reuse verification after a conflict-free merge when candidate/integrated trees match. Repeat affected checks if source content, integration or the relevant environment changes.
- See [harness commands and report contract](docs/AGENTS_SKILLS_HARNESS.md), [XCTest](.agents/skills/xctest-practices/SKILL.md) and [regression packs](.agents/skills/regression-packs/SKILL.md) for execution details.

## Workspaces and delivery
- Implement code changes in a dedicated worktree using [task-worktree](.agents/skills/task-worktree/SKILL.md). New branches use codex/JCR-NNN-short-name or codex/TASK-NNN-short-name; preserve a resumed plan's declared branch, including legacy names.
- Authorized implementation-plan execution ends with verified local integration into main and updated task evidence. Other requests follow their requested deliverable; analysis/planning does not authorize implementation.
- Push, remote PR creation, CI execution and release publication require authorization covering that action. Local implementation does not imply remote publication.
- Remove only this task's clean, merged worktree/branch after preserving evidence; keep unfinished work. The worktree skill owns the mechanics.

## Bot AI
- Training/retraining, including training-pipeline-smoke, is a separate task requiring an explicit user request; never add it to routine implementation or CI verification.
- Replacing checked-in tuning requires baseline and A/B evidence under [bot-training-pipeline](.agents/skills/bot-training-pipeline/SKILL.md); it also owns the training command reference.
- Runtime AI work follows [bot-ai-conventions](.agents/skills/bot-ai-conventions/SKILL.md).

## Requirements and backlog workflow
- [The requirements registry](docs/requirements/README.md) owns decision/implementation states and task/plan metadata. Update affected requirements, history and CHANGELOG with behavior changes; mark implemented only with evidence in main.
- Before backlog work read [backlog/AGENTS.md](backlog/AGENTS.md). Capture `зафиксируй` / `зафикчируй` text verbatim in backlog/inbox/YYYY-MM-DD.md using the user's date, appending without triage.
- Route requested triage/status reconciliation to [codex-backlog-skill](.agents/skills/codex-backlog-skill/SKILL.md), product questions to [product-plan-clarification](.agents/skills/product-plan-clarification/SKILL.md), planning to [tasks-ready-to-implementation](.agents/skills/tasks-ready-to-implementation/SKILL.md), authorized execution to [implement-release-plan](.agents/skills/implement-release-plan/SKILL.md).
- Resuming historical docs/ plans requires an up-to-date backlog card and requirements mapping. `make requirements-check BASE=<ref>` validates traceability and CHANGELOG co-change; the harness includes it.

## Maintaining instructions
- Change a rule in its owning source first; update dependent guidance in the same task. Keep reusable instructions separate from task status, which belongs in backlog cards.
- After adding/removing/renaming skills or profiles, or changing their metadata, run `python3 scripts/harness/instructions.py catalog --write`; never hand-edit the generated catalog.
- `python3 scripts/harness/verify.py instructions` checks entrypoints, known stack conflicts, metadata, local links, structural paths and catalog drift. It does not prove semantic consistency, product acceptance or external-link availability.
