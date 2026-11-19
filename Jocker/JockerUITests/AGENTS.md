# UI tests

Follow [root policy](../../AGENTS.md), the [test placement mapping](../../FOLDER_STRUCTURE_SPEC.md#test-targets-layout)
and [XCTest practices](../../.agents/skills/xctest-practices/SKILL.md).

- Use XCUITest. Each scenario establishes its launch arguments, persisted state
  and other preconditions; never depend on locale, prior tests or a manual run.
- For relaunch/resume tests, retain only the state deliberately created by that
  scenario. Synchronize on observable UI state, not fixed sleeps.
- Cover changed player flows and relevant errors/accessibility behavior; add
  performance measurement when the task has a concrete performance requirement.
- Use targeted scenarios during iteration and the root harness for completion.
