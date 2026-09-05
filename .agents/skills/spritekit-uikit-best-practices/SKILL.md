---
name: spritekit-uikit-best-practices
description: Use when implementing, reviewing, or refactoring Jocker app sources to follow the verified stack conventions — UIKit + SpriteKit without SwiftUI/Combine/async-await, value-type services, protocol-based testability, explicit self., one type per file. Derives behavior from root AGENTS.md and FOLDER_STRUCTURE_SPEC.md; use for mechanics and structure, not for game rules or UX design.
---

# SpriteKit + UIKit best practices

The root `AGENTS.md` is the verified authority for this stack. It overrides
generic iOS guidance and any stale nested instruction file.

## Stack constraints (hard)

- UIKit (`AppDelegate`, view controllers) + SpriteKit (`SKScene` for
  gameplay).
- No SwiftUI. No Combine. No async/await. No SPM/CocoaPods dependencies.
- Pure Swift services/coordinators; `UserDefaults` for persistence.
- Concurrency and timing use completion handlers / delegation consistent
  with the existing code.

When existing code violates a convention, match the surrounding style in a
small change and note the debt; do not stage a framework migration inside an
unrelated task.

## Type and file conventions

- One type per file; the file name matches the type exactly.
- Classes for SpriteKit nodes/scenes and UIKit view controllers; structs for
  models and services (prefer value types).
- Protocols for testability, following the established pattern (e.g.
  `GameStatisticsStore` / `UserDefaultsGameStatisticsStore`).
- App sources under `Jocker/Jocker/`; tests under `Jocker/JockerTests/`
  mirroring app structure.
- New files must be added to the correct Xcode target; `JockerSelfPlayTools`
  sources are never part of the app target.

## Style conventions

- Explicit `self.` in instance methods.
- Default parameter labels; full `.self` for type references.
- Clear naming: verbs for methods, `is/has/should` for booleans, no
  unexplained abbreviations.

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
- Persistence goes through protocol-typed stores (`UserDefaults`-backed);
  never read `UserDefaults` directly from a scene or view controller.
- Screen transitions keep state restoration behavior consistent with the
  existing flow (what survives backgrounding must not change silently).

## Review checklist

For any diff in `Game/` or `ViewControllers/`:

- no SwiftUI/Combine/async/await introduced;
- one type per file preserved; new files in the right target;
- rules/scoring logic not duplicated into presentation;
- explicit `self.` in instance methods and closures;
- scene/VC teardown releases observers, actions, timers;
- tests updated under the mirrored `JockerTests/<feature>/` path.

When structural placement questions arise, defer to
`FOLDER_STRUCTURE_SPEC.md` and update it in the same change when structure
changes.
