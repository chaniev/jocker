---
name: ios-hig-audit
description: Use only when an independent compliance audit of an implemented Jocker interface is explicitly requested — Apple HIG alignment, accessibility, Dynamic Type, dark mode, touch targets, and interaction consistency. Reports findings without redesigning the game flow or overriding joker-game-ui.
---

# iOS HIG audit

An independent audit of an already-implemented interface. It reports findings
with evidence; it does not redesign the game UX, change rules, or replace the
project's own UI conventions (`.agents/skills/joker-game-ui/SKILL.md` is the
authoritative convention set; this skill only checks compliance and platform
consistency).

## Scope of the audit

Check only what is implemented and in scope:

- platform consistency: navigation, modal presentation, alert usage versus
  Apple HIG patterns for game apps;
- accessibility: Dynamic Type behavior, VoiceOver labels and traits on
  interactive elements, sufficient contrast, hit-target sizes;
- dark mode and appearance: correctness where the project supports it, and
  explicit listing of unsupported surfaces rather than silent omission;
- layout: safe areas, orientation/size-class behavior, truncation and
  overflow on the smallest supported size;
- interaction consistency: feedback for every action, prevention or
  explanation of illegal moves, interruption behavior (backgrounding during
  bidding/trick play);
- terminology consistency with existing screens and the rules texts.

## Method

1. Run the affected flow on a simulator; observe, do not infer from code
   alone.
2. For each finding record: screen and state, exact observable evidence
   (what was done, what was shown), the HIG or project convention involved,
   and severity:
   - **blocking** — prevents task completion or misleads the player;
   - **major** — clear friction or accessibility failure on a main path;
   - **minor** — polish; safe to defer.
3. Distinguish findings that require a product/UX decision from mechanical
   fixes; do not resolve flow decisions inside the audit.

## Boundaries

- Do not modify code, assets, or project configuration during the audit.
- Do not propose rule changes or flow redesigns; list them as questions for
  the owning decision.
- Do not audit against web or third-party design systems; HIG plus the
  project's own conventions are the standard.
- Explicitly list what was not verified: physical devices, VoiceOver runtime
  behavior if not exercised, long-match sessions, localization beyond
  Russian.

## Report format

For each finding: severity, screen/state, evidence, standard violated,
smallest recommended remediation. End with an overall verdict for the audited
flow and the prioritized follow-up list. State the simulator OS/version and
device used.
