# Jocker app and shared Swift sources

Follow [root AGENTS.md](../../AGENTS.md) and
[FOLDER_STRUCTURE_SPEC.md](../../FOLDER_STRUCTURE_SPEC.md).

- Existing self-play sources in Game/Services/AI are training-target code; their async/await implementation is allowed. Determine ownership from project.pbxproj, not directory alone.
- Rules and scoring belong in domain services; scenes and controllers present their state.
- Before changing gameplay, read [joker-game-rules](../../.agents/skills/joker-game-rules/SKILL.md); before presentation work, read [joker-game-ui](../../.agents/skills/joker-game-ui/SKILL.md).
- App implementation mechanics are in [spritekit-uikit-best-practices](../../.agents/skills/spritekit-uikit-best-practices/SKILL.md). Follow the root verification contract; additional tuning acceptance belongs to [bot-training-pipeline](../../.agents/skills/bot-training-pipeline/SKILL.md).
