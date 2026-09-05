---
name: architecture-decision
description: Evaluate and record a significant Jocker technical or architectural choice as an ADR when alternatives affect boundaries, contracts, data, runtime, or long-term reversibility. Do not use for product decisions or routine local implementation choices.
---

# Architecture decision

Produce a reviewable Architecture Decision Record without changing product
behavior or approving the decision on behalf of its owner.

## Establish authority and evidence

1. Read the root `AGENTS.md`. Treat any nested `AGENTS.md` as subordinate;
   the root file is verified for this stack.
2. Read the governing product sources: the relevant texts in
   `правила игры/`, the source implementation plan, existing ADRs, and
   accepted reviews such as `docs/PRODUCT_OWNER_REVIEW_RU.md` that constrain
   the choice.
3. Establish current behavior from tests and public contracts first, then
   build configuration (`project.pbxproj`, schemes, CI), source code, and
   supporting documentation.
4. Separate product uncertainty from technical uncertainty. If different
   answers change player-visible rules, scoring, modes, or scope, stop and
   request a product decision instead of resolving it in an ADR.

An ADR may explain how accepted plans will be implemented. It never overrides
or silently changes them.

## Decide whether an ADR is warranted

Use an ADR when the choice is material, including:

- ownership or boundaries between the rules core (`Models/`, `Scoring/`),
  the SpriteKit client (`Game/`), UIKit screens (`ViewControllers/`), bot AI
  (`Models/Bot/`), the training CLI (`JockerSelfPlayTools/`), and build/CI;
- a persistence, statistics, or data-ownership strategy (e.g. anything
  replacing or wrapping the `UserDefaults` stores);
- a new framework, major dependency, or shared cross-cutting pattern (the
  project currently has no SPM/CocoaPods dependencies — introducing one is
  material);
- an integration boundary such as the SLM proposal in
  `docs/SLM_INTEGRATION_PROPOSAL.md`;
- the target boundaries or compilation contract of `JockerSelfPlayTools`
  versus the app;
- a broad structural refactor or another costly-to-reverse decision;
- two or more credible approaches with materially different consequences.

Do not create an ADR for a small, local, readily reversible implementation
choice that follows established conventions.

## Compare the options

State the decision that is needed now and the concrete forces that constrain
it. Compare the current approach when it is credible and at least one genuine
alternative. Do not invent weak alternatives to satisfy a count.

Evaluate only applicable criteria:

- consistency with the rules texts and accepted plans;
- cross-layer impact (rules core, presentation, bot AI, training CLI);
- determinism and reproducibility for tests and self-play training;
- simulator/device runtime cost and memory behavior;
- test and regression-pack coverage, and how the decision can be falsified;
- implementation and maintenance complexity;
- compatibility, incremental adoption, and reversibility.

Use the relevant specialist agents for bounded evidence or review when the
decision crosses their area. The coordinating agent resolves disagreements
using repository evidence precedence and records unresolved conflicts; a
specialist preference does not override the rules texts or `AGENTS.md`.

## Record the decision

Create the next `docs/architecture/adr/NNNN-kebab-title.md` (create the
directory with an index `README.md` on first use). Structure each record as:
Status, Context, Decision, Options compared, Consequences (including honest
negatives), Affected layers and consumers, Validation, and Links.

- Use `Proposed` for an agent-authored draft.
- Use `Accepted (name, role, YYYY-MM-DD)` only when the user or named human
  owner explicitly approves this exact decision.
- Preserve accepted ADRs. Replace a changed decision with a new ADR and mark
  the old one `Superseded by ADR-NNNN`.
- Link the governing source: the rules text file, implementation plan, or
  review document. Use `none — <specific behavior-preserving reason>` only
  when the decision cannot change product behavior.
- Record concrete validation (tests, packs, training evidence) that would
  falsify the decision.
- Update the ADR index in `docs/architecture/adr/README.md` in the same
  change, and add one concise link in the related plan when one exists. Do
  not copy the ADR into the plan.

## Stop conditions

Leave the ADR `Proposed` and stop before implementation when:

- a required product decision is missing;
- the choice conflicts with the rules texts or root `AGENTS.md` invariants
  (stack constraints, determinism, target boundaries);
- persisted player data (statistics, history) cannot be migrated safely;
- affected producer and consumer contracts cannot be coordinated;
- evidence cannot distinguish the options and the choice is costly to
  reverse;
- the approving owner is unknown for a decision that requires acceptance.

## Handoff

Report the ADR path and status, selected option and decisive criteria,
discarded options, affected layers, required reviewers, validation evidence,
and remaining open questions. Never report a draft as an accepted project
decision.
