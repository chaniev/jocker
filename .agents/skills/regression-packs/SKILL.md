---
name: regression-packs
description: Use when running, extending, or creating Jocker regression packs — targeted xcodebuild test sets for JOKER rules behavior, phase guardrails, and ranking guardrails. Covers pack selection by changed area, -list/-dry inspection, adding tests to a pack, and artifact expectations.
---

# Regression packs

Packs are the delivery vehicle for scenario regression coverage: shell
scripts that run `xcodebuild test -only-testing:...` with targeted test
lists. Full-suite runs (`scripts/run_all_tests.sh`) prove overall health;
packs prove the specific behavior an area owns.

## Pack inventory

| Pack | Command | Covers |
|---|---|---|
| JOKER regression | `make joker-pack` (`-all` adds probes) | JOKER rules behavior: joker mechanics, scoring, premiums |
| Phase guardrails (Stage 4) | `make stage4-phase-pack` | Phase-conditioned runtime behavior (`PHASE-*`, plus `BLIND`/`PREMIUM`/`JOKER` scenario tests) |
| Ranking guardrails (Stage 6b) | `make stage6b-pack` | Opponent-aware turn-candidate ranking (`BotTurnCandidateRankingServiceTests` scenarios) |
| Ranking + flow plumbing | `make stage6b-pack-all` | Adds opponent-model snapshot plumbing, evaluator/strategy `no-evidence` neutrality, style-shift checks |

## Selection by changed area

- Rules/scoring/gameplay behavior (`Models/`, `Scoring/`) → `make joker-pack`.
- Bot policy/tuning (`Models/Bot/`) → `make stage4-phase-pack` and
  `make stage6b-pack`.
- Playing-flow plumbing or opponent-model handoff → `make stage6b-pack-all`.
- Training/evolution scope → `make stage3-scope-validate`;
  parallelism changes → `make stage5-benchmark`.
- Anything structural or cross-cutting → full `bash scripts/run_all_tests.sh`.

When in doubt, run the pack plus the full suite; do not substitute a pack for
the full suite on structural changes.

## Inspection before runs

Every pack has list/dry modes — use them before executing:

```bash
make joker-pack-list && make joker-pack-dry
make stage4-phase-pack-list && make stage4-phase-pack-dry
make stage6b-pack-list && make stage6b-pack-dry
```

`-dry` prints the exact selected tests without running them; verify the
selection matches the change before spending a run.

## Adding tests to a pack

1. Write the test in the owning test class under `JockerTests/<feature>/`
   (scenario naming follows the established `BLIND-*`/`PREMIUM-*`/`PHASE-*`/
   `JOKER-*` conventions where applicable).
2. Prove it fails for the broken behavior and passes after the fix.
3. Add its `-only-testing` selector to the pack script's test list in
   `scripts/`.
4. Re-run the pack's `-list`/`-dry` to confirm the new selection.
5. Packs only gain tests; removing a test from a pack requires an explicit
   justification in the change description.

## Artifacts

Packs persist their runs under `.derivedData/<pack-runs>/<timestamp>/`
(`xcodebuild.log`, `summary.txt`, `selected-tests.txt`, and `.xcresult` where
generated). Reference the artifact directory when reporting outcomes; do not
commit artifacts.

## Report format

State: pack and mode run, selection (from `selected-tests.txt`), pass/fail
counts, failing test names with the failure assertion, artifact directory,
and follow-up.
