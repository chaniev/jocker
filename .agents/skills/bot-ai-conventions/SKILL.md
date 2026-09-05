---
name: bot-ai-conventions
description: Use for any change to bot intelligence in the app target — BotRuntimePolicy, BotTuning, difficulty presets, turn-candidate ranking, opponent modeling, and pairs-mode cooperation under Models/Bot/. Also use when touching the JockerSelfPlayTools evolution sources or their target boundary.
---

# Bot AI conventions

Bots are measurable, deterministic game players. Their quality is proven by
tests and training evidence, not by narrative.

## Configuration home

- `BotRuntimePolicy` + `BotTuning` own bot configuration, with difficulty
  presets `easy` / `normal` / `hard`.
- Tuning parameters are produced by the training pipeline (see
  `.agents/skills/bot-training-pipeline/SKILL.md`); hand-authored numeric
  changes are hypotheses that require baseline + A/B evidence before
  replacing checked-in values.

## Determinism

- For a fixed tuning and fixed deal/seed, bot decisions must be reproducible.
  Tests and self-play training depend on this.
- Do not introduce hidden state, wall-clock time, or unordered iteration into
  decision paths.
- When randomness is required, source it from the seeded generator the
  engine already uses.

## Target boundary

- Self-play/training sources (`BotSelfPlayEvolutionEngine+*.swift`,
  `BotTuning+SelfPlayEvolution.swift`, `BotTrainingRunner.swift`,
  `main.swift`) compile only into the `JockerSelfPlayTools` target. They are
  not part of the app runtime.
- App-facing bot code lives under `Models/Bot/` and must not import or call
  training-only types.
- After any project membership change, verify the app target still excludes
  self-play sources.

## Decision architecture

- Turn-candidate ranking is the decision surface: candidates are generated,
  scored by policy/tuning, and deterministically ordered. Keep this pipeline
  intact so guardrails packs can measure it.
- Opponent modeling flows through the playing flow's snapshot plumbing; keep
  the snapshot handoff explicit and testable (`make stage6b-pack-all`
  covers it).
- Phase-conditioned behavior, blind/premium/joker awareness are covered by
  scenario tests (`BLIND-*`, `PREMIUM-*`, `PHASE-*`, `JOKER-*`) — extend the
  matching scenario instead of adding parallel mechanisms.
- Pairs-mode cooperation builds on partner awareness in the existing policy
  structure; do not fork a separate bot implementation for the mode.

## Difficulty presets

- A preset change affects every surface that uses it (app play, tests,
  training baselines). State which presets a change touches.
- `easy` must remain observably weaker and `hard` observably stronger on the
  packs' scenario metrics; a change that flattens the difficulty ladder is a
  regression.

## Required validation

- `make stage4-phase-pack` and `make stage6b-pack` for policy changes;
  `make stage6b-pack-all` when flow plumbing changed.
- `make training-pipeline-smoke` after evolution/runner changes.
- Replacing checked-in tuning requires `make bot-baseline` and
  `make bot-compare` evidence tied to the candidate commit.

## Stop conditions

- A desired behavior that contradicts the rules texts is a product question,
  not a bot hack.
- A quality claim without pack or comparison evidence is not done.

Report the decision-level delta (what changes per difficulty in observable
play), the evidence run, and the training handoff if parameters need
retraining.
