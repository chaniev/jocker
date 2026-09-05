---
name: xctest-practices
description: Use when creating, reviewing, or substantially restructuring XCTest tests in JockerTests or JockerUITests — test placement, deterministic setup, targeted execution with -only-testing, artifact locations, and assertion quality. Derives behavior expectations from game rules and existing contracts, not from generic examples.
---

# XCTest practices

Tests are deterministic evidence about game behavior. This skill covers the
mechanics; behavior expectations come from the rules texts, plans, and
existing contracts (see `.agents/skills/joker-game-rules/SKILL.md`).

## Placement and naming

- Mirror app structure: a type under `Jocker/Jocker/<area>/` is tested under
  `Jocker/JockerTests/<feature>/` with a `<TypeName>Tests.swift` file.
- One test class per tested type; keep fixtures local to the class that uses
  them.
- Scenario tests follow the established naming conventions
  (`BLIND-*`, `PREMIUM-*`, `PHASE-*`, `JOKER-*`) when they encode a bot-AI
  scenario from `docs/BOT_AI_TEST_SCENARIOS.md`.

## Determinism rules

- Fixed, explicit inputs: construct hands/deals directly or use fixed seeds;
  never depend on `Date()`, `UUID()`, wall-clock timing, or dictionary
  iteration order in assertions.
- No sleep-based synchronization; assert on observable state transitions
  produced by the code under test.
- UI tests must not depend on simulator-locale, first-launch state, or
  previously executed tests; each test sets up its own preconditions.
- Mark non-deterministic-by-nature checks explicitly and justify them; prefer
  to redesign the seam (protocol store, injected scheduler/dealer) instead.

## Assertion quality

- Assert observable outcomes: computed scores, awarded premiums, turn
  transitions, persisted statistics — not internal call counts or mock
  bookkeeping when the real outcome is checkable.
- One behavior per test method; name the method after the behavior
  (`testJokerTakesTrickOverTrumpAce`, not `testScenario17`).
- On failure, the assertion message plus test name must identify the rule or
  contract violated without reading the body.

## Execution

Run a single class during iteration:

```bash
xcodebuild test \
  -project Jocker/Jocker.xcodeproj \
  -scheme Jocker \
  -destination "platform=iOS Simulator" \
  -only-testing:JockerTests/BotTurnCandidateRankingServiceTests
```

Run everything through the canonical entry point so artifacts persist:

```bash
bash scripts/run_all_tests.sh
```

## Artifacts

- Full runs persist `xcodebuild.log`, `TestResults.xcresult`, and
  `summary.txt` under `.derivedData/test-runs/<timestamp>/`.
- Pack runs persist under their own `.derivedData/<pack-runs>/<timestamp>/`.
- Artifacts are never committed; reference the directory path in reports.

## Review checklist

- placement mirrors app structure; one type per test file;
- setup is explicit and local; no hidden ordering between tests;
- assertions check player/game-observable outcomes;
- the test fails for the broken behavior (demonstrated) and passes after;
- targeted class run provided for iteration; full-suite/pack run cited for
  completion;
- runtime cost of the addition is reasonable for CI (45-minute workflow
  budget).
