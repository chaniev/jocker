---
name: spritekit-uikit-best-practices
description: Use when implementing, reviewing, or refactoring Jocker app sources to follow the verified stack conventions — UIKit + SpriteKit without SwiftUI/Combine/async-await, value-type services, protocol-based testability, explicit self., one type per file. Derives behavior from root AGENTS.md and FOLDER_STRUCTURE_SPEC.md; use for mechanics and structure, not for game rules or UX design.
---

# SpriteKit + UIKit best practices

Read [AGENTS.md](../../../AGENTS.md) for the stack, persistence, style and
verification contract, and applicable nested instructions for local ownership.
[ADR-0001](../../../docs/architecture/adr/0001-durable-game-session-persistence.md)
defines durable session/statistics storage; do not infer a storage backend from
legacy store names. [FOLDER_STRUCTURE_SPEC.md](../../../FOLDER_STRUCTURE_SPEC.md)
owns type placement and build target boundaries.

This skill covers implementation mechanics. Use completion handlers/delegation
consistent with the existing app. When a small change encounters older style,
keep scope local and record the debt instead of starting a framework migration.
Use descriptive names: verbs for methods and `is/has/should` for booleans.

## SpriteKit-specific rules

- Scenes and nodes render state owned by the domain core; game rules are not
  re-derived in `Game/`.
- Use explicit `self.` in closures and actions; avoid retain cycles with
  weak captures where a parent references a child callback.
- Keep the update loop lean: no per-frame allocations, no unbounded node
  accumulation across a full 4-block match; clean up actions, observers, and
  timers on scene teardown.
- Animate with cancellable `SKAction` sequences so scene transitions and
  interruptions do not strand half-finished sequences.
- Hit-testing and gesture recognizers must be testable independently of
  visual timing.

## UIKit-specific rules

- View controllers stay coordination-light: bind state, present screens,
  forward input; business decisions live in the domain core or services.
- Layout uses the project's established approach; support the orientations
  and size classes the project already targets.
- Persistence goes through protocol-typed stores. Scenes and view controllers
  do not access `UserDefaults` or persistence files directly.
- Screen transitions keep state restoration behavior consistent with the
  existing flow (what survives backgrounding must not change silently).

## Review checklist

For any diff in `Game/` or `ViewControllers/`:

- root stack/style contract and target ownership preserved;
- rules/scoring logic not duplicated into presentation;
- scene/VC teardown releases observers, actions, timers;
- tests updated in the source-to-test location defined by the specification.

When structural placement questions arise, defer to
`FOLDER_STRUCTURE_SPEC.md` and update it when its placement contract or referenced
paths change. New files in existing areas need no manual inventory entry.
