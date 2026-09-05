---
name: joker-game-rules
description: Use for any change to Joker game behavior — dealing, bidding, trump and joker mechanics, trick play, scoring, premiums, block/match structure, or the pairs mode. Treats the texts in 'правила игры/' as the source of truth and reconciles code against them. Use before implementing, reviewing, or testing gameplay changes in Models/, Scoring/, or gameplay flow.
---

# Joker game rules

The written rules are the contract for game behavior. Code, tests, plans, and
documentation never override them silently; a deliberate rule change is a
product decision recorded in an accepted plan or review, not an
implementation side effect.

## Source of truth

Map each rules area to its authoritative text:

| Area | Rules text |
|---|---|
| General structure, players, blocks | `правила игры/общие.txt` |
| Dealing, first dealer | `правила игры/раздача карт.txt`, `правила игры/правила раздачи карт на 4 игроков.txt`, `правила игры/выбор первого раздающего.txt` |
| Trump selection | `правила игры/выбор козыря.txt` |
| Joker mechanics | `правила игры/особенности игры с джокером.txt` |
| Trick play and taking cards | `правила игры/ход.txt`, `правила игры/забор карт с кона.txt` |
| Last block specifics | `правила игры/особенности игры в поледнем блоке.txt` |
| Scoring | `правила игры/подсчет очков.txt` |
| Premiums | `правила игры/присуждение премии.txt` |
| Pairs mode | `правила игры/пара на пару.txt` |

Supporting notes live in `docs/CARDS_DOCUMENTATION.md` and
`docs/README_CARDS.md`; they are secondary to the rules texts.

## Workflow

1. Locate the governing text and quote the exact rule as the contract for the
   change. If no text governs the situation, stop: that is a product
   question, not an implementation choice.
2. Establish current behavior from tests and the domain types
   (`Models/Gameplay`, `Models/Cards`, `Models/Joker`, `Models/Players`,
   `Scoring/`) before writing code.
3. Separate three cases and treat them differently:
   - code contradicts the text → defect; fix code, add a regression test;
   - text is ambiguous → product question; surface it with the observed
     consequences of each reading;
   - behavior is intentionally extended (new mode, changed balance) →
     requires an accepted plan (e.g. `docs/PAIRS_MODE_IMPLEMENTATION_PLAN.md`)
     or an explicit user decision.
4. Write the test first for behavior changes: deterministic setup, explicit
   hands/seed, observable outcome (score, taken cards, turn transition).
5. Run the checks for the touched area: targeted `-only-testing` classes, then
   `make joker-pack` when rules behavior changed.

## Invariants to preserve

- Score arithmetic, premium conditions, and block/match completion must match
   the texts exactly, including edge cases: joker in play, last-block
   behavior, and premium disputes.
- Rules logic stays in the domain core; scenes, nodes, and view controllers
   consume results and must not re-derive them.
- Pairs mode (`пара на пару`) is a mode of the same game: individual and team
   scoring paths share the core rules and differ only where the text says so
   (partner cooperation, team score aggregation).
- Behavior must stay deterministic for a fixed deal/seed so tests and
   self-play training remain reproducible.
- History and statistics (`Models/History`, `Models/Statistics`) record what
   the rules produced; changing a rule must not silently reinterpret stored
   data — call out migration needs.

## Quality gate

Before reporting done:

- every behavior change traces to a rules text quote or an accepted plan;
- new/changed edge cases are covered by tests (joker, premium, last block,
  pairs);
- `make joker-pack` passes (or `-dry` reviewed and targeted classes run);
- ambiguities found are reported as product questions, not silently resolved.

Do not propose rule redesigns inside implementation tasks; list them as
product questions with consequences.
