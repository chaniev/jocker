# Jocker app and shared Swift sources

Follow the repository AGENTS.md and FOLDER_STRUCTURE_SPEC.md.

- App UI uses UIKit + SpriteKit. No SwiftUI, Combine or Swift concurrency in app-target code.
- Existing self-play sources in Game/Services/AI are training-target code; their async/await implementation is allowed. Determine ownership from project.pbxproj, not directory alone.
- Rules and scoring belong in domain services; scenes and controllers present their state.
- Use explicit self., value-type services and protocol-based dependencies.
- New top-level types have matching files. Existing nested helper types and extensions are allowed.
- Before changing gameplay, read joker-game-rules; before presentation work, read joker-game-ui.
- Use make harness-plan BASE=<ref> and make harness-verify BASE=<ref> for change verification. Additional training acceptance gates remain in bot-training-pipeline.
