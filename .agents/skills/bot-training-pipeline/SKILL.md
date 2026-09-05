---
name: bot-training-pipeline
description: Use for self-play training runs, tuning replacement, and training-side validation — canonical Makefile profiles (bt, train-bot-final, esab variants), ensembles, early stopping, A/B holdout, baseline snapshots, scope validation, and parallel benchmarks. Use before starting or resuming training, and before accepting any new BotTuning values.
---

# Bot training pipeline

Training is a reproducible pipeline with persisted evidence, not an
interactive session. The canonical entry points are Makefile targets that
wrap `scripts/train_bot_tuning.sh`; never reconstruct a training command ad
hoc when a target exists.

## Canonical targets

| Goal | Command |
|---|---|
| Canonical balanced full-match training | `make bt` (= `make train-bot`) |
| Final validation ensemble | `make train-bot-final` |
| Full-match battle with early stop + A/B | `make bt-hard-fullgame-battle-esab` |
| Pipeline smoke (compile/baseline/evolution) | `make training-pipeline-smoke` |
| Baseline snapshot | `make bot-baseline` (or `-smoke`) |
| A/B comparison | `make bot-compare` (or `-medium`/`-smoke`) |
| Evolution scope validation | `make stage3-scope-validate` (+ `-medium`/`-smoke`) |
| Parallel benchmark | `make stage5-benchmark` |

`legacy-bt-<difficulty>-<smoke|balanced|battle>` targets are legacy
short-random-round profiles kept for comparison; the canonical signal is the
full-match (4-block, seat-rotated) profiles.

## Profile semantics

- `smoke` — pipeline sanity only; never evidence of quality.
- `balanced` — iterative improvement default.
- `battle` — high-budget decisive runs; final acceptance level.
- `esab` variants add early stopping (`--early-stop-*`) and A/B holdout
  validation (`--ab-validate`, disjoint holdout seed list).
- Final ensembles train across the fixed seed list with median aggregation.

## Acceptance gate for tuning replacement

A new `BotTuning` replaces the checked-in values only with:

1. a baseline snapshot (`make bot-baseline`) of the current preset;
2. an A/B comparison (`make bot-compare`) where the candidate beats the
   baseline on the holdout seeds;
3. both runs tied to the exact candidate commit and persisted artifacts.

Report the artifact directories, not just conclusions.

## Artifacts and reproducibility

- All training/harness outputs land under `.derivedData/<harness>/<timestamp>/`
  (gitignored). Never commit raw logs or metrics blobs.
- Every run's exact command line is preserved by the harness (e.g.
  `command.txt`); a result that cannot be reproduced from the recorded
  command is not evidence.
- Training seeds and holdout seeds must be disjoint when A/B validation is
  used; call out seed overlap as an invalidating flaw.
- Parallel evaluation (`--max-parallel-evaluations`) must report parity with
  sequential evaluation before its speedup is trusted (`make stage5-benchmark`).

## Working rules

- Inspect before running: use `<pack>-list` / `-dry` modes where available to
  confirm what will execute and its expected cost.
- Long runs (battle profiles, ensembles) are started deliberately with a
  stated budget; report early-stop outcomes rather than silently extending.
- Keep `make training-pipeline-smoke` green after any change to the runner,
  engine sources, or `scripts/train_bot_tuning.sh`.
- Evolution/engine code changes belong in `JockerSelfPlayTools` sources only
  (see `.agents/skills/bot-ai-conventions/SKILL.md`); runtime policy changes
  in the app are a separate task with their own packs.

## Report format

For each run: target/command, profile, seeds, artifact directory,
fitness/holdout metrics for the best candidate, anomalies (stagnation,
divergence, seed sensitivity), and the accept/reject verdict with the
evidence paths.
