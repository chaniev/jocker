# Unit and integration tests

Follow [root policy](../../AGENTS.md), the [test placement mapping](../../FOLDER_STRUCTURE_SPEC.md#test-targets-layout)
and [XCTest practices](../../.agents/skills/xctest-practices/SKILL.md).

- Assert observable behavior with deterministic inputs and isolated store state;
  fixtures must not depend on earlier tests or the user's persisted data.
- Keep shared bot builders in Bot/ and other fixtures with their owning suites;
  frozen session payloads belong in Models/Gameplay/Fixtures/.
- Use targeted classes during iteration and the root harness for completion;
  do not repeat tests already covered by its combined run.
