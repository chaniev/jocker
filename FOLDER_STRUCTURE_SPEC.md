# Folder Structure Spec (Jocker)

## Scope

This document is the source of truth for repository structure and file placement.

## Repository Layout (actual)

```
/
├── AGENTS.md
├── .github/
│   └── workflows/
│       └── ios-tests.yml
├── Makefile
├── FOLDER_STRUCTURE_SPEC.md
├── BOT_AI_IMPROVEMENT_PLAN.md
├── BOT_AI_IMPROVEMENT_PLAN_REVIEW.md
├── BOT_AI_IMPROVEMENT_PROPOSALS_UNIFIED.md
├── BOT_AI_TEST_SCENARIOS.md
├── CARDS_DOCUMENTATION.md
├── CODE_REFACTORING_BACKLOG.md
├── README.md
├── README_CARDS.md
├── XCODE_INTEGRATION.md
├── scripts/
│   ├── run_all_tests.sh
│   ├── run_bot_ab_comparison_snapshot.sh
│   ├── run_bot_baseline_snapshot.sh
│   ├── run_joker_regression_pack.sh
│   ├── run_stage6b_ranking_guardrails.sh
│   └── train_bot_tuning.sh
├── правила игры/
│   ├── выбор козыря.txt
│   ├── выбор первого раздающего.txt
│   ├── забор карт с кона.txt
│   ├── общие.txt
│   ├── особенности игры с джокером.txt
│   ├── особенности игры в поледнем блоке.txt
│   ├── подсчет очков.txt
│   ├── присуждение премии.txt
│   ├── раздача карт.txt
│   ├── правила раздачи карт на 4 игроков.txt
│   └── ход.txt
└── Jocker/
    ├── Jocker/                    (main app target sources)
    ├── JockerTests/               (unit tests)
    ├── JockerUITests/             (UI tests)
    └── Jocker.xcodeproj/          (Xcode project: `Jocker`, `JockerSelfPlayTools`, `JockerTests`, `JockerUITests` targets)
```

## Key File Responsibilities

- `Jocker/Jocker/Game/Scenes/GameScene.swift`: base gameplay scene shell (scene lifecycle, table/player/UI setup, shared layout helpers, top-level touch routing, and runtime-only state orchestration).
- `Jocker/Jocker/Game/Scenes/GameSceneInputConfiguration.swift`: explicit external setup configuration for `GameScene` (player count/names/control modes/bot difficulty settings) applied before scene presentation.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionBlockers.swift`: `OptionSet` for centralized interaction-blocking flags used by `GameScene` flow and modal gating.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionState.swift`: explicit high-level interaction state (primary flow + pending modal) derived from blockers, used for safer `GameScene` flow-state reasoning and conflict assertions.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionTransitionPolicy.swift`: pure blocker transition policy for setting/clearing high-level flow and pending-modal states while preserving unrelated blocker groups.
- `Jocker/Jocker/Game/Scenes/GameScene+DealingFlow.swift`: dealing pipeline for each round (deck reset/shuffle, pre-deal blind step, staged dealing, and dealer-left trump choice stage).
- `Jocker/Jocker/Game/Scenes/GameScene+BiddingFlow.swift`: bidding pipeline (bidding order, human/bot bid progression, dealer forbidden-bid rule, and bidding-to-playing transition).
- `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`: trick-playing pipeline (tap hit-testing, bot autoplay scheduling, card placement, trick resolution, and trick-win registration).
- `Jocker/Jocker/Game/Scenes/GameScene+ModalFlow.swift`: unified overlay-modal entrypoints and callbacks for trump selection, bid/blind input, and joker play-mode decision fallback.
- `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift`: facade over round/turn/animation services; keeps scene logic thin and serializes trick resolution.
- `Jocker/Jocker/Game/Coordinator/GameEnvironment.swift`: dependency container for `GameScene` infrastructure/services (coordinator, stores/export, and bot service factories), enabling explicit DI at scene creation.
- `Jocker/Jocker/Game/Services/Flow/GameRoundService.swift`: transitions between rounds/blocks, one-time block finalization recording, and score-manager recording via shared round-result snapshots.
- `Jocker/Jocker/Game/Services/Flow/GameTurnService.swift`: entrypoint for automatic bot turn decision and trick winner resolution.
- `Jocker/Jocker/Game/Services/AI/BotMatchContextBuilder.swift`: pure builder mapping `GameState` + `ScoreManager` to `BotMatchContext` (premium snapshot + opponent model), keeping `GameScene` UI-focused.
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift`: runtime bot move orchestrator that resolves legal cards, round context, and fallback move selection.
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`: runtime evaluator loop for bot turns (candidate enumeration, heuristic scoring, round projections, and best-move selection).
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`: runtime candidate-ranking helper for bot turns (utility calculation and deterministic tie-break policy).
- `Jocker/Jocker/Game/Services/AI/BotTurnCardHeuristicsService.swift`: low-level runtime card/trick heuristics for bot turns (joker decision variants, threat scoring, unseen-card modeling, and immediate trick-win probability).
- `Jocker/Jocker/Game/Services/AI/BotTurnRoundProjectionService.swift`: runtime round projection helper for bot turns (bid normalization, future trick estimates, expected round score, and remaining-hand projection).
- `Jocker/Jocker/Game/Services/AI/BotTuning+SelfPlayEvolution.swift`: thin `BotTuning` adapter over self-play evolution/head-to-head APIs (typealiases + forwarding methods), compiled in `JockerSelfPlayTools` (not in runtime app target).
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine.swift`: facade/namespace for self-play evolution; implementation is split across `BotSelfPlayEvolutionEngine+*.swift` and compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+PublicTypes.swift`: public API types for self-play evolution (config, results, progress event), compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift`: self-play evolution orchestration (top-level `evolveViaSelfPlay`, head-to-head evaluation, early stopping), compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Fitness.swift`: fitness scoring configuration, per-seat metric aggregation, and candidate tuning evaluation, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Genome.swift`: genome model + mutation/crossover, evolution scope masking, and projection to `BotTuning`, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Simulation.swift`: self-play match simulation (legacy + full-match rules), metrics accumulator, and debug helpers, compiled in `JockerSelfPlayTools`.
- `Makefile`: developer convenience targets; `make bt` (alias `make train-bot`) runs bot self-play training workflow. Legacy quick presets (`bt-<difficulty>-<smoke|balanced|battle>`) run short random-round profiles for `easy`/`normal`/`hard`; `bt-hard-fullgame-<smoke|balanced|battle>` run full-match (4-block) single-seed training with seat rotation; `bt-hard-final` runs multi-seed ensemble full-match training. `make joker-pack` / `make joker-pack-all` run the Stage-5 `JOKER` regression pack (`strict` only vs `strict+probe`). `make stage6b-pack` runs the Stage-6b opponent-aware ranking guardrails pack; `make stage6b-pack-all` adds cross-service Stage-6 guardrails (flow plumbing + evaluator/strategy `no-evidence` neutrality + style-shift checks) (`make stage6b-pack-list`, `make stage6b-pack-dry` for inspection). `make bot-baseline` / `make bot-baseline-smoke` run the Stage-0 baseline snapshot harness (`generations=0`) with persisted artifacts. `make bot-compare` / `make bot-compare-smoke` run the Stage-0 A/B comparison harness (baseline preset vs tuned candidate) with parsed A/B summary artifacts.
- `BOT_AI_IMPROVEMENT_PLAN.md`: staged implementation roadmap for bot gameplay AI improvements (premiums/blind/joker/phase-aware decisions/opponent adaptation), including acceptance criteria and PR slicing.
- `BOT_AI_IMPROVEMENT_PLAN_REVIEW.md`: review notes and critique of `BOT_AI_IMPROVEMENT_PLAN.md`.
- `BOT_AI_IMPROVEMENT_PROPOSALS_UNIFIED.md`: unified proposals backlog (best of mapped+consolidated) with runtime gaps taxonomy, metric definitions, and roadmap.
- `BOT_AI_TEST_SCENARIOS.md`: draft catalog of deterministic bot-AI regression scenarios (`BLIND` / `PREMIUM` / `JOKER` / `PHASE`) plus baseline comparison templates and reproducibility fields for stage-0 measurements.
- `CARDS_DOCUMENTATION.md`: rules notes and card/game documentation.
- `CODE_REFACTORING_BACKLOG.md`: codebase refactoring notes and no-behavior-change improvement backlog (maintainability/testability).
- `.github/workflows/ios-tests.yml`: GitHub Actions CI workflow that runs Xcode tests on macOS for every `push` and uploads test run artifacts from `.derivedData/test-runs`.
- `scripts/run_all_tests.sh`: developer CLI entrypoint for full `xcodebuild test` run with persisted artifacts (`xcodebuild.log`, `TestResults.xcresult`, and `summary.txt`) under `.derivedData/test-runs/<timestamp>/`.
- `scripts/run_bot_ab_comparison_snapshot.sh`: Stage-0 companion harness for reproducible `baseline vs candidate` A/B validation (`A=basePreset`, `B=tunedOutput`); runs `train_bot_tuning.sh` with fixed training/validation seed profiles and saves raw/parsed A/B artifacts (`ab-*-section.txt`, `ab-*-metrics.txt`, `comparison-table.md`) under `.derivedData/bot-ab-runs/<timestamp>/`.
- `scripts/run_bot_baseline_snapshot.sh`: Stage-0 baseline harness for bot AI metrics; runs `train_bot_tuning.sh` in baseline-only mode (`--generations 0`) on fixed seed lists and stores artifacts (`train_bot_tuning.log`, `summary.txt`, `baseline-metrics.txt`, `command.txt`) under `.derivedData/bot-baseline-runs/<timestamp>/`.
- `scripts/run_joker_regression_pack.sh`: developer CLI entrypoint for Stage-5 `JOKER` regression pack runs (selected `strict` tests and optional `probe` tests) with persisted artifacts (`xcodebuild.log`, `TestResults.xcresult`, `summary.txt`, and `selected-tests.txt`) under `.derivedData/joker-regression-runs/<timestamp>/`.
- `scripts/run_stage6b_ranking_guardrails.sh`: developer CLI entrypoint for Stage-6b opponent-aware ranking guardrails pack (selected `BotTurnCandidateRankingServiceTests` for `BLIND-004`, `PREMIUM-010/011`, `PHASE-003`, `JOKER-016`), with optional `--include-flow-plumbing` mode that adds cross-service Stage-6 guardrails (`GameScenePlayingFlowTests` opponent-model snapshot plumbing + evaluator/strategy `no-evidence` neutrality and style-shift checks); persists artifacts (`xcodebuild.log`, `TestResults.xcresult`, `summary.txt`, and `selected-tests.txt`) under `.derivedData/stage6b-ranking-runs/<timestamp>/`.
- `Jocker/Jocker.xcodeproj/xcshareddata/xcschemes/Jocker.xcscheme`: shared Xcode scheme committed for CI/automation so `xcodebuild test -scheme Jocker` works on clean GitHub runners.
- `Jocker/Jocker.xcodeproj/project.pbxproj`: defines target boundaries; `JockerSelfPlayTools` (static library) owns self-play/training sources, while `Jocker` app target excludes them from runtime build.
- `scripts/train_bot_tuning.sh`: developer CLI entrypoint for offline self-play training; compiles a local runner and prints tuned `BotTuning` values.
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`: bot bidding heuristic that projects expected tricks and selects bid with best projected score.
- `Jocker/Jocker/Game/Services/AI/HandFeatureExtractor.swift`: shared hand-analysis extractor for bot AI services (regular cards, suit counts, joker/high-card counts) reused by bidding, trump selection, and round projection heuristics.
- `Jocker/Jocker/Game/Services/AI/BotHandStrengthModel.swift`: unified hand-strength model for bot AI services (shared bidding expected tricks, future-trick projection, and trump suit profile synthesis).
- `Jocker/Jocker/Game/Services/AI/BotRankNormalization.swift`: centralized named rank-normalization helpers for bot AI modes (`bidding`, `future projection`, `trump selection`) and shared high-card threshold predicate, preserving legacy formulas.
- `Jocker/Jocker/Game/Services/AI/BotTrumpSelectionService.swift`: bot trump chooser for blocks 2 and 4 based on the pre-deal subset of cards.
- `Jocker/Jocker/Game/Services/History/DealHistoryStore.swift`: in-memory capture of deal playback data (trump per deal, ordered trick moves, trick winners) plus per-move training samples (state/action/outcome).
- `Jocker/Jocker/Game/Services/History/DealHistoryExportService.swift`: persistent JSON export of deal history and training samples on block/game completion.
- `Jocker/Jocker/Game/Services/Flow/GameAnimationService.swift`: deal and delayed trick-resolution animation scheduling/cancellation.
- `Jocker/Jocker/Game/Services/Settings/GamePlayersSettingsStore.swift`: persistence of editable player names and per-bot difficulty presets (`UserDefaults`, v1 key).
- `Jocker/Jocker/Game/Services/Statistics/GameStatisticsStore.swift`: storage contract for game statistics persistence and retrieval.
- `Jocker/Jocker/Game/Services/Statistics/UserDefaultsGameStatisticsStore.swift`: `UserDefaults`-backed aggregation for all/3-player/4-player statistics.
- `Jocker/Jocker/Game/Nodes/TrickNode.swift`: current trick state and move legality checks (including joker lead modes).
- `Jocker/Jocker/Models/Gameplay/TrickTakingResolver.swift`: pure winner algorithm for a trick with joker semantics.
- `Jocker/Jocker/Models/Gameplay/BiddingRules.swift`: pure bidding/blind constraints and bidding order helpers shared by gameplay flow and self-play simulation.
- `Jocker/Jocker/Models/Gameplay/TrumpSelectionRules.swift`: round-level rules for trump selection mode (automatic vs player-chosen), chooser seat, and staged-deal size.
- `Jocker/Jocker/Models/Statistics/GameFinalPlayerSummary.swift`: computes final standings payload per player (place, total score, block-by-block scores, premiums per block, total premiums, and fourth-block blind count).
- `Jocker/Jocker/Models/Statistics/GameStatisticsScope.swift`: statistics tabs (`all games`, `4 players`, `3 players`) and visible seat count per tab.
- `Jocker/Jocker/Models/Statistics/GameStatisticsPlayerRecord.swift`: aggregated counters by player seat (games, places, premiums by block, blind bids, max/min game score).
- `Jocker/Jocker/Models/Statistics/GameStatisticsSnapshot.swift`: persisted statistics snapshot grouped by scope.
- `Jocker/Jocker/Models/History/DealHistory.swift`: immutable snapshot of one deal history (deal key, trump, and trick history list).
- `Jocker/Jocker/Models/History/DealHistoryKey.swift`: normalized identifier of deal position inside game (block index + round index).
- `Jocker/Jocker/Models/History/DealTrickHistory.swift`: trick-level history payload with ordered moves and winner player index.
- `Jocker/Jocker/Models/History/DealTrickMove.swift`: move-level history payload with player, card, and joker play context.
- `Jocker/Jocker/Models/History/DealTrainingMoveSample.swift`: per-move training payload with pre-move state, chosen action, and trick outcome.
- `Jocker/Jocker/Models/Players/PlayerControlType.swift`: player control mode (`human` / `bot`) used by the scene/controller flow.
- `Jocker/Jocker/Models/Players/GamePlayersSettings.swift`: normalized snapshot of editable names for 4 player slots and stored bot difficulties for slots 2–4.
- `Jocker/Jocker/Models/Bot/BotDifficulty.swift`: bot difficulty presets (`easy` / `normal` / `hard`) used to select AI behavior profile.
- `Jocker/Jocker/Models/Bot/BotMatchContext.swift`: normalized runtime match/block context payload for bot decisions (block index/progress, scores, dealer-relative seat position), used as feature-plumbing for stage 4a+.
- `Jocker/Jocker/Models/Bot/BotOpponentModel.swift`: Stage-6 MVP opponent-style snapshot model (per-opponent observed blind/bid outcome/aggression rates within current block) built for runtime AI feature-plumbing.
- `Jocker/Jocker/Models/Bot/BotTuning.swift`: centralized coefficients and timing presets consumed by bot services and gameplay flow delays.
- `Jocker/Jocker/Scoring/GameRoundResultsBuilder.swift`: shared mapper from `GameState` runtime round state to `[RoundResult]`, reused by flow recording and in-progress score-table snapshots.
- `Jocker/Jocker/Scoring/ScoreCalculator.swift`: pure scoring formulas (round score, premium bonus, premium penalty, zero premium).
- `Jocker/Jocker/Scoring/PremiumRules.swift`: pure block-level premium/penalty finalization (premium players, zero-premium eligibility, penalty targets, and bonus embedding into the last deal).
- `Jocker/Jocker/Scoring/ScoreManager.swift`: sole owner of accumulated game scores, block persistence, standings helpers, and premium application.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableView.swift`: render-only score grid that maps rounds/blocks to table rows and summary lines, with defensive summary/cumulative rendering for partial score arrays.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableInProgressRoundSnapshotProvider.swift`: provider that precomputes in-progress round cells for `ScoreTableView`, removing direct `ScoreManager` reads from row render passes.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRenderSnapshotBuilder.swift`: pure snapshot/model builder for `ScoreTableView` that extracts score data and computes premium/penalty decoration metadata outside the view render pass.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableLabelFrameResolver.swift`: pure frame calculator for `ScoreTableView` labels (header, cards, tricks, points) and pinned-header y-adjustment based on current column widths and row metrics.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowNavigationResolver.swift`: pure row navigation helper for `ScoreTableView` that resolves scroll targets for deal rows and block summary rows from static row mappings.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowPresentationResolver.swift`: pure row presentation helper for `ScoreTableView` that defines cards-column text and row-level points label style (`regular` vs `summary`).
- `Jocker/Jocker/ViewControllers/Results/ScoreTableScrollOffsetResolver.swift`: pure scroll-offset calculator for `ScoreTableView` that centers target rows and clamps vertical offsets to scroll bounds.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableTapTargetResolver.swift`: pure tap hit-testing helper for `ScoreTableView` that maps tap coordinates to a deal row target (`blockIndex`, `roundIndex`) using static row mappings.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowTextRenderer.swift`: pure row text renderer for `ScoreTableView` that builds per-cell tricks/points strings for deal/subtotal/cumulative rows, including in-progress round overlays and summary score formatting.
- `Jocker/Jocker/ViewControllers/Bidding/JokerModeSelectionViewController.swift`: modal joker play-mode picker (lead and non-lead cases).
- `Jocker/Jocker/ViewControllers/Bidding/BidSelectionModalBaseViewController.swift`: shared modal UI building blocks for bid-related selectors (container, labels, scroll grid, and bid-button rows).
- `Jocker/Jocker/ViewControllers/Bidding/BidSelectionViewController.swift`: modal selector of human post-deal bid amount with current hand/trump context and bidding summary panel.
- `Jocker/Jocker/ViewControllers/Bidding/PreDealBlindSelectionViewController.swift`: modal selector of pre-deal blind mode (`open after deal` vs `blind bid`) and blind bid amount list.
- `Jocker/Jocker/ViewControllers/Bidding/TrumpSelectionViewController.swift`: modal selector of trump suit (or no-trump) for the chooser in blocks 2 and 4.
- `Jocker/Jocker/ViewControllers/GameFlow/GameParametersViewController.swift`: full-screen settings form for all player names and per-bot difficulty controls.
- `Jocker/Jocker/ViewControllers/GameFlow/FirstPlayerAnnouncementViewController.swift`: overlay modal that announces the first player and confirms continuation before the first deal.
- `Jocker/Jocker/ViewControllers/Results/GameResultsViewController.swift`: end-of-game modal showing final placements and per-player summary metrics across all blocks.
- `Jocker/Jocker/ViewControllers/Statistics/GameStatisticsViewController.swift`: statistics screen with tabbed table for all games, 4-player games, and 3-player games.
- `Jocker/Jocker/ViewControllers/Statistics/GameStatisticsTableView.swift`: grid-style statistics table where rows are metrics and columns are player seats.
- `Jocker/Jocker/ViewControllers/Results/DealHistoryViewController.swift`: modal details for a selected deal with trump, full move sequence, and trick winners.

## App Source Layout

```
Jocker/Jocker/
├── AGENTS.md
├── App/
│   └── AppDelegate.swift
├── Core/
│   └── GameColors.swift
├── Game/
│   ├── Coordinator/
│   │   ├── GameSceneCoordinator.swift
│   │   └── GameEnvironment.swift
│   ├── Nodes/
│   │   ├── CardHandNode.swift
│   │   ├── CardNode.swift
│   │   ├── GameButton.swift
│   │   ├── PlayerNode.swift
│   │   ├── PokerTableNode.swift
│   │   ├── TrickNode.swift
│   │   ├── TrumpIndicator.swift
│   │   └── TurnIndicatorNode.swift
│   ├── Scenes/
│   │   ├── CardDemoScene.swift
│   │   ├── GameScene.swift
│   │   ├── GameSceneInputConfiguration.swift
│   │   ├── GameSceneInteractionBlockers.swift
│   │   ├── GameSceneInteractionState.swift
│   │   ├── GameSceneInteractionTransitionPolicy.swift
│   │   ├── GameScene+DealingFlow.swift
│   │   ├── GameScene+BiddingFlow.swift
│   │   ├── GameScene+PlayingFlow.swift
│   │   └── GameScene+ModalFlow.swift
│   └── Services/
│       ├── AI/
│       │   ├── BotBiddingService.swift
│       │   ├── BotRankNormalization.swift
│       │   ├── HandFeatureExtractor.swift
│       │   ├── BotHandStrengthModel.swift
│       │   ├── BotMatchContextBuilder.swift
│       │   ├── BotTurnCandidateEvaluatorService.swift
│       │   ├── BotTurnCandidateRankingService.swift
│       │   ├── BotTurnCardHeuristicsService.swift
│       │   ├── BotSelfPlayEvolutionEngine.swift
│       │   ├── BotTuning+SelfPlayEvolution.swift
│       │   ├── BotTurnRoundProjectionService.swift
│       │   ├── BotTrumpSelectionService.swift
│       │   └── BotTurnStrategyService.swift
│       ├── Flow/
│       │   ├── GameAnimationService.swift
│       │   ├── GameRoundService.swift
│       │   └── GameTurnService.swift
│       ├── History/
│       │   ├── DealHistoryExportService.swift
│       │   └── DealHistoryStore.swift
│       ├── Settings/
│       │   └── GamePlayersSettingsStore.swift
│       └── Statistics/
│           ├── GameStatisticsStore.swift
│           └── UserDefaultsGameStatisticsStore.swift
├── Models/
│   ├── Bot/
│   │   ├── BotDifficulty.swift
│   │   ├── BotMatchContext.swift
│   │   ├── BotOpponentModel.swift
│   │   └── BotTuning.swift
│   ├── Cards/
│   │   ├── Card.swift
│   │   ├── CardColor.swift
│   │   ├── Deck.swift
│   │   ├── Rank.swift
│   │   └── Suit.swift
│   ├── Gameplay/
│   │   ├── BlockResult.swift
│   │   ├── BiddingRules.swift
│   │   ├── GameBlock.swift
│   │   ├── GameBlockFormatter.swift
│   │   ├── GameConstants.swift
│   │   ├── GamePhase.swift
│   │   ├── GameState.swift
│   │   ├── RoundResult.swift
│   │   ├── TrickTakingResolver.swift
│   │   └── TrumpSelectionRules.swift
│   ├── History/
│   │   ├── DealHistory.swift
│   │   ├── DealHistoryKey.swift
│   │   ├── DealTrainingMoveSample.swift
│   │   ├── DealTrickHistory.swift
│   │   └── DealTrickMove.swift
│   ├── Joker/
│   │   ├── JokerLeadDeclaration.swift
│   │   ├── JokerPlayDecision.swift
│   │   ├── JokerPlayStyle.swift
│   │   └── PlayedTrickCard.swift
│   ├── Players/
│   │   ├── GamePlayersSettings.swift
│   │   ├── PlayerControlType.swift
│   │   └── PlayerInfo.swift
│   └── Statistics/
│       ├── GameFinalPlayerSummary.swift
│       ├── GameStatisticsPlayerRecord.swift
│       ├── GameStatisticsScope.swift
│       └── GameStatisticsSnapshot.swift
├── Resources/
│   ├── Actions.sks
│   └── GameScene.sks
├── Scoring/
│   ├── GameRoundResultsBuilder.swift
│   ├── ScoreCalculator.swift
│   ├── PremiumRules.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── Bidding/
│   │   ├── BidSelectionModalBaseViewController.swift
│   │   ├── BidSelectionViewController.swift
│   │   ├── JokerModeSelectionViewController.swift
│   │   ├── PreDealBlindSelectionViewController.swift
│   │   └── TrumpSelectionViewController.swift
│   ├── GameFlow/
│   │   ├── FirstPlayerAnnouncementViewController.swift
│   │   ├── GameParametersViewController.swift
│   │   ├── GameViewController.swift
│   │   └── PlayerSelectionViewController.swift
│   ├── Results/
│   │   ├── DealHistoryViewController.swift
│   │   ├── GameResultsViewController.swift
│   │   ├── ScoreTableInProgressRoundSnapshotProvider.swift
│   │   ├── ScoreTableRenderSnapshotBuilder.swift
│   │   ├── ScoreTableLabelFrameResolver.swift
│   │   ├── ScoreTableRowNavigationResolver.swift
│   │   ├── ScoreTableRowPresentationResolver.swift
│   │   ├── ScoreTableScrollOffsetResolver.swift
│   │   ├── ScoreTableTapTargetResolver.swift
│   │   ├── ScoreTableRowTextRenderer.swift
│   │   ├── ScoreTableView.swift
│   │   └── ScoreTableViewController.swift
│   └── Statistics/
│       ├── GameStatisticsTableView.swift
│       └── GameStatisticsViewController.swift
├── Assets.xcassets/
└── Base.lproj/
    ├── LaunchScreen.storyboard
    └── Main.storyboard
```

## Test Targets Layout

```
Jocker/JockerTests/
├── AGENTS.md
├── Bot/
│   ├── BotBiddingServiceTests.swift
│   ├── BotHandStrengthModelTests.swift
│   ├── HandFeatureExtractorTests.swift
│   ├── BotMatchContextBuilderTests.swift
│   ├── BotOpponentModelTests.swift
│   ├── BotRankNormalizationTests.swift
│   ├── BotTurnCandidateEvaluatorServiceTests.swift
│   ├── BotTurnCandidateRankingServiceTests.swift
│   ├── BotTurnCandidateRankingServiceTestFixture.swift
│   ├── BotTurnCandidateRankingServiceTests_TieBreak.swift
│   ├── BotTurnCandidateRankingServiceTests_Blind.swift
│   ├── BotTurnCandidateRankingServiceTests_JokerDeclaration.swift
│   ├── BotTurnCandidateRankingServiceTests_PhaseThreat.swift
│   ├── BotTurnCandidateRankingServiceTests_PremiumPenalty.swift
│   ├── BotTurnCardHeuristicsServiceTests.swift
│   ├── BotSelfPlayEvolutionEngineTests.swift
│   ├── BotTrumpSelectionServiceTests.swift
│   ├── BotTuningTests.swift
│   ├── BotTurnRoundProjectionServiceTests.swift
│   └── BotTurnStrategyServiceTests.swift
├── Models/
│   ├── CardModelTests.swift
│   ├── DeckTests.swift
│   ├── SuitRankTests.swift
│   ├── GameplayModelsTests.swift
│   ├── RulesTests.swift
│   ├── JokerModelsTests.swift
│   ├── HistoryModelsTests.swift
│   └── PlayerStatisticsModelsTests.swift
├── Flow/
│   ├── AutoPlayFlowTests.swift
│   ├── GameFlowIntegrationTests.swift
│   ├── GameSceneInteractionStateTests.swift
│   ├── GameSceneInteractionTransitionPolicyTests.swift
│   ├── GameScenePlayingFlowTests.swift
│   └── GameStateTests.swift
├── History/
│   ├── DealHistoryExportServiceTests.swift
│   └── DealHistoryStoreTests.swift
├── Players/
│   └── GamePlayersSettingsStoreTests.swift
├── Results/
│   ├── GameResultsPresentationIntegrationTests.swift
│   ├── ScoreTableInProgressRoundSnapshotProviderTests.swift
│   ├── ScoreTableRowNavigationResolverTests.swift
│   ├── ScoreTableRenderSnapshotBuilderTests.swift
│   ├── ScoreTableLabelFrameResolverTests.swift
│   ├── ScoreTableRowPresentationResolverTests.swift
│   ├── ScoreTableScrollOffsetResolverTests.swift
│   ├── ScoreTableTapTargetResolverTests.swift
│   └── ScoreTableRowTextRendererTests.swift
├── Rules/
│   ├── BiddingRulesTests.swift
│   └── TrickTakingResolverTests.swift
├── Scoring/
│   ├── PremiumRulesTests.swift
│   ├── ScoreCalculatorTests.swift
│   └── ScoreManagerTests.swift
├── Statistics/
│   ├── GameFinalPlayerSummaryTests.swift
│   ├── GameStatisticsTableViewTests.swift
│   └── GameStatisticsStoreTests.swift
└── JockerTests.swift

Jocker/JockerUITests/
├── AGENTS.md
├── GameRepeatResultsFlowUITests.swift
├── JockerUITests.swift
└── JockerUITestsLaunchTests.swift
```

## Placement Conventions

- Scene classes are placed in `Jocker/Jocker/Game/Scenes/`.
- Scene coordinators are placed in `Jocker/Jocker/Game/Coordinator/`.
- SpriteKit node classes are placed in `Jocker/Jocker/Game/Nodes/`.
- Game services are grouped by responsibility in `Jocker/Jocker/Game/Services/AI/`, `Jocker/Jocker/Game/Services/Flow/`, `Jocker/Jocker/Game/Services/History/`, `Jocker/Jocker/Game/Services/Settings/`, and `Jocker/Jocker/Game/Services/Statistics/`.
- Domain and state models are grouped in `Jocker/Jocker/Models/Bot/`, `Jocker/Jocker/Models/Cards/`, `Jocker/Jocker/Models/Gameplay/`, `Jocker/Jocker/Models/History/`, `Jocker/Jocker/Models/Joker/`, `Jocker/Jocker/Models/Players/`, and `Jocker/Jocker/Models/Statistics/`.
- Scoring logic is placed in `Jocker/Jocker/Scoring/`.
- UIKit controllers and views are grouped by flow in `Jocker/Jocker/ViewControllers/Bidding/`, `Jocker/Jocker/ViewControllers/GameFlow/`, `Jocker/Jocker/ViewControllers/Results/`, and `Jocker/Jocker/ViewControllers/Statistics/`.
- Unit tests are grouped by feature under `Jocker/JockerTests/` subfolders.
- Xcode Project Navigator groups under `Models/`, `Game/Services/`, `ViewControllers/`, and `JockerTests/` should mirror these filesystem subfolders 1:1.
- Shared core primitives are placed in `Jocker/Jocker/Core/`.
- Resource files (`.sks`, assets, storyboards) stay under `Jocker/Jocker/Resources/`, `Jocker/Jocker/Assets.xcassets/`, and `Jocker/Jocker/Base.lproj/`.
- Developer automation scripts are placed in `scripts/` at repository root.

## Type/File Rule

- For new entities, keep one top-level type per file and match file name to type name.
