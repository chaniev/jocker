---
name: joker-game-ui
description: Design, implement, review, or test Joker screens and gameplay presentation for players — bidding, trick play, results, statistics, and the pairs mode UI on UIKit + SpriteKit. Use for new screens, flow redesigns, interaction states, visual quality, and player-facing acceptance. Preserve rules-core ownership and complete every screen state before polish.
---

# Joker game UI

Design and implement player-facing screens and gameplay presentation as
complete, feedback-rich states of one game, not as isolated visual edits.

The stack is fixed by the root `AGENTS.md`: UIKit view controllers with a
SpriteKit gameplay scene. No SwiftUI, no Combine, no async/await.

## Screen inventory

Own the state completeness of:

- game setup and mode selection (individual vs `пара на пару`);
- bidding screens (`ViewControllers/Bidding/`);
- the gameplay table (`Game/Scenes`, `Game/Nodes`): hands, trick area, trump
  indicator, joker state, turn indicator;
- block/match progression and score visibility during play;
- results and premiums (`ViewControllers/Results/`);
- statistics and history (`ViewControllers/Statistics/`).

## Workflow

1. Enumerate the screen's states before any layout work: initial/loading,
   active, waiting-for-opponent, blocked, error/empty, and result states.
   A screen is not done until every reachable state is designed and
   implemented.
2. Establish what the player must know and decide at each step; the screen's
   hierarchy serves that decision (turn ownership, legal moves, current
   scores).
3. Use a rendered design gate for material visual changes: sketch or mock the
   layout (or describe the target composition precisely) and get acceptance
   before implementing visual rework of an existing screen.
4. Implement with project conventions (see
   `.agents/skills/spritekit-uikit-best-practices/SKILL.md`); keep rules and
   scoring in the domain core.
5. Validate as a player: one normal full-block path, one interrupted path
   (backgrounding mid-trick), and one end-of-match path into results and
   statistics.

## Acceptance rules

- Every player action produces visible feedback or a state change; nothing
  silently no-ops. Illegal moves are prevented or explained, never ignored.
- Turn ownership and phase are unmistakable on the table at all times.
- Trump, joker presence, and current block/round are visible when they
  affect decisions.
- Pairs mode distinguishes partner and opponents visually and shows team
  score aggregation.
- Results let the player reconstruct the outcome: final scores, premiums,
  and per-block progression where established.
- User-facing terminology is consistent Russian matching existing screens
  and the rules texts; do not invent synonyms for bids, premiums, or blocks.
- Statistics screens never imply data the stores do not persist.

## Boundaries

- Do not change rules, scoring, or bot behavior from UI work; route those
  changes to the owning agents.
- Do not add new dependencies, SwiftUI, or reactive frameworks.
- Accessibility: preserve Dynamic Type and dark mode where the project
  already supports them; extend coverage deliberately, not implicitly.

## Quality gate

Before reporting done:

- state inventory listed and each state implemented;
- player-visible acceptance rules above checked on the touched flow;
- `bash scripts/run_all_tests.sh` (or the targeted screen/flow test classes)
  passes;
- simulator checks performed; physical-device and long-match checks listed
  as explicitly unverified when not run.
