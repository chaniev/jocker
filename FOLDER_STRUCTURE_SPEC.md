# Folder Structure Spec (Jocker)

## Scope

This document is the source of truth for repository structure and file placement.

## Repository Layout

```
/
├── AGENTS.md
├── FOLDER_STRUCTURE_SPEC.md
├── LICENSE
├── Makefile
├── README.md
├── .github/
│   └── workflows/
│       └── ios-tests.yml
├── docs/
│   ├── BOT_AI_FULL_TEST_COVERAGE_PLAN.md
│   ├── BOT_AI_IMPROVEMENT_PLAN.md
│   ├── BOT_AI_IMPROVEMENT_PLAN_REVIEW.md
│   ├── BOT_AI_IMPROVEMENT_PROPOSALS_UNIFIED.md
│   ├── BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md
│   ├── BOT_AI_LEARNING_IMPROVEMENT_DETAILED_PLANS/
│   │   ├── 01_TRAINING_PIPELINE_RECOVERY_PLAN.md
│   │   ├── 02_FITNESS_GUARDRAILS_EXPANSION_PLAN.md
│   │   ├── 03_RUNTIME_POLICY_EVOLUTION_SCOPE_PLAN.md
│   │   ├── 04_PHASE_CONDITIONED_POLICY_MULTIPLIERS_PLAN.md
│   │   ├── 05_PARALLEL_CANDIDATE_EVALUATION_PLAN.md
│   │   ├── 06_EVOLUTION_SEARCH_STABILITY_PLAN.md
│   │   ├── 07_OPPONENT_MODEL_V2_PLAN.md
│   │   └── 08_EXPERIMENT_HARNESS_AND_REPORTING_PLAN.md
│   ├── BOT_AI_TEST_SCENARIOS.md
│   ├── BOT_RUNTIME_POLICY_AND_TUNING_REFACTORING_PLAN.md
│   ├── CARDS_DOCUMENTATION.md
│   ├── CODEX_MCP_SKILLS_SETUP.md
│   ├── CODE_REFACTORING_BACKLOG.md
│   ├── README_CARDS.md
│   └── XCODE_INTEGRATION.md
├── scripts/
│   ├── run_all_tests.sh
│   ├── run_bot_ab_comparison_snapshot.sh
│   ├── run_bot_baseline_snapshot.sh
│   ├── run_joker_regression_pack.sh
│   ├── run_stage4_phase_guardrails.sh
│   ├── run_stage5_parallel_benchmark.sh
│   ├── run_training_pipeline_smoke.sh
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
│   ├── правила раздачи карт на 4 игроков.txt
│   ├── присуждение премии.txt
│   ├── раздача карт.txt
│   └── ход.txt
└── Jocker/
    ├── Jocker/                    (main app target sources)
    ├── JockerSelfPlayTools/       (checked-in Swift CLI entrypoints for self-play/training automation)
    ├── JockerTests/               (unit tests)
    ├── JockerUITests/             (UI tests)
    └── Jocker.xcodeproj/          (Xcode project: `Jocker`, `JockerSelfPlayTools`, `JockerTests`, `JockerUITests` targets)
```

Notes:
- `docs/` contains project documentation (plans, Xcode integration notes, and card/rules docs).
- `.derivedData/` contains local build/test artifacts and is gitignored.
- `.cursor/` contains local editor configuration and is not a build input.

## Key File Responsibilities

Selected, non-exhaustive list of key files and what they own.

- `Jocker/Jocker/Game/Scenes/GameScene.swift`: base gameplay scene shell (scene lifecycle, table/player/UI setup, shared layout helpers, top-level touch routing, and orchestration over extracted scene session/presentation/persistence helpers).
- `Jocker/Jocker/Game/Scenes/GameSceneInputConfiguration.swift`: explicit external setup configuration for `GameScene` (player count/names/control modes/bot difficulty settings) applied before scene presentation.
- `Jocker/Jocker/Game/Scenes/GameSceneLayoutResolver.swift`: pure geometry helper for `GameScene` (player seats, table-centered controls, bid-info sizing, trump/joker overlays, and first-dealer announcement layout).
- `Jocker/Jocker/Game/Scenes/GameSceneNodeFactory.swift`: small SpriteKit node factory for `GameScene` reusable node setup (poker table and primary action buttons) so construction details do not live inline in scene orchestration.
- `Jocker/Jocker/Game/Scenes/GameSceneSessionState.swift`: transient scene-owned runtime/session state (pending bids/blind selections, result-presentation flags, export markers, and did-deal markers) separated from domain game state.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionBlockers.swift`: `OptionSet` for centralized interaction-blocking flags used by `GameScene` flow and modal gating.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionState.swift`: explicit high-level interaction state (primary flow + pending modal) derived from blockers, used for safer `GameScene` flow-state reasoning and conflict assertions.
- `Jocker/Jocker/Game/Scenes/GameSceneInteractionTransitionPolicy.swift`: pure blocker transition policy for setting/clearing high-level flow and pending-modal states while preserving unrelated blocker groups.
- `Jocker/Jocker/Game/Scenes/GameScene+DealingFlow.swift`: dealing pipeline for each round (deck reset/shuffle, pre-deal blind step, staged dealing, and dealer-left trump choice stage).
- `Jocker/Jocker/Game/Scenes/GameScene+BiddingFlow.swift`: bidding pipeline (bidding order, human/bot bid progression, dealer forbidden-bid rule, and bidding-to-playing transition).
- `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`: trick-playing pipeline (tap hit-testing, bot autoplay scheduling, card placement, trick resolution, and trick-win registration).
- `Jocker/Jocker/Game/Scenes/GameScene+ModalFlow.swift`: unified overlay-modal entrypoints and callbacks for trump selection, bid/blind input, joker play-mode decision fallback, and delegation into scene presentation/persistence coordinators.
- `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift`: facade over round/turn/animation services; keeps scene logic thin and serializes trick resolution.
- `Jocker/Jocker/Game/Coordinator/GameEnvironment.swift`: dependency container for `GameScene` infrastructure/services (coordinator, stores/export, and bot service factories), enabling explicit DI at scene creation.
- `Jocker/Jocker/Game/Coordinator/GameSceneModalPresenter.swift`: UIKit modal presenter/navigation helper for `GameScene`, encapsulating root/top controller traversal and dismiss-to-start-screen behavior outside scene logic.
- `Jocker/Jocker/Game/Coordinator/GameResultsPersistenceCoordinator.swift`: post-game persistence/export coordinator for `GameScene`, applying statistics saving and deal-history export rules against extracted session state.
- `Jocker/Jocker/Game/Coordinator/DealHistoryPresentationCoordinator.swift`: presents deal-history details or a missing-history alert from score-table navigation without embedding UIKit routing into `GameScene`.
- `Jocker/Jocker/Game/Services/Flow/GameRoundService.swift`: transitions between rounds/blocks, one-time block finalization recording, and score-manager recording via shared round-result snapshots.
- `Jocker/Jocker/Game/Services/Flow/GameTurnService.swift`: entrypoint for automatic bot turn decision and trick winner resolution.
- `Jocker/Jocker/Game/Services/AI/BotMatchContextBuilder.swift`: pure builder mapping `GameState` + `ScoreManager` to `BotMatchContext` (premium snapshot + opponent model), keeping `GameScene` UI-focused.
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift`: runtime bot move orchestrator that resolves legal cards, round context, and fallback move selection.
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`: runtime bot-turn evaluator facade that enumerates candidates, builds ranking context, delegates rollout/endgame/simulation work to extracted helpers, and chooses the final best move.
- `Jocker/Jocker/Game/Services/AI/BotTurnBeliefStateBuilder.swift`: isolated belief-state inference helper for bot turns (`BotBeliefState.infer` plumbing from round/trick snapshots).
- `Jocker/Jocker/Game/Services/AI/BotTurnOpponentOrderResolver.swift`: seat/order helper for runtime AI (remaining-opponent order, normalized player indices, lead-suit resolution, simulation seat context, and opponent-intention modeling).
- `Jocker/Jocker/Game/Services/AI/BotTurnSamplingService.swift`: deterministic rollout/endgame sampling helper (stable seed builder, RNG, opponent-hand sampling, and shuffle utilities) shared by evaluator subsystems.
- `Jocker/Jocker/Game/Services/AI/BotTurnSimulationService.swift`: extracted low-level simulation helper for sampled tricks/hands (legal cards, joker decisions, trick-win checks, and card-power ordering).
- `Jocker/Jocker/Game/Services/AI/BotTurnRolloutService.swift`: rollout scoring helper for top bot-turn candidates (gating, urgency weighting, sampled future-trick simulation, and utility adjustments).
- `Jocker/Jocker/Game/Services/AI/BotTurnEndgameSolver.swift`: small-hand endgame solver for bot turns (solver gating, sampled round completion, and endgame utility adjustments).
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`: runtime candidate-ranking facade for bot turns that gathers utility adjustments from extracted ranking helpers and delegates deterministic tie-break comparison to a dedicated policy object.
- `Jocker/Jocker/Game/Services/AI/BlockPlanResolver.swift`: block-level score-state/risk-budget helper for ranking (`match catch-up`, urgency, premium-preserve bias, and deny-opponent bias).
- `Jocker/Jocker/Game/Services/AI/OpponentPressureAdjuster.swift`: opponent-style/intention pressure helper for ranking (premium-deny multipliers, blind contest pressure, and bid/intention utility adjustments).
- `Jocker/Jocker/Game/Services/AI/PremiumPreserveAdjuster.swift`: premium/zero-premium preservation utility helper for ranking decisions.
- `Jocker/Jocker/Game/Services/AI/PenaltyAvoidAdjuster.swift`: penalty-risk utility helper that deforms ranking away from score lines threatening premium penalties.
- `Jocker/Jocker/Game/Services/AI/PremiumDenyAdjuster.swift`: anti-premium utility helper that biases ranking against preserving opponents' premium trajectories.
- `Jocker/Jocker/Game/Services/AI/JokerDeclarationAdjuster.swift`: lead face-up joker declaration utility helper, including goal-oriented declaration shaping and early `wish` penalty.
- `Jocker/Jocker/Game/Services/AI/MoveUtilityComposer.swift`: final ranking utility composer that merges tactical/risk/opponent/joker components into a stabilized utility score.
- `Jocker/Jocker/Game/Services/AI/CandidateTieBreakPolicy.swift`: isolated deterministic tie-break policy for equal/near-equal ranked move candidates.
- `Jocker/Jocker/Game/Services/AI/BotTurnCardHeuristicsService.swift`: low-level runtime card/trick heuristics for bot turns (joker decision variants, threat scoring, unseen-card modeling, and immediate trick-win probability).
- `Jocker/Jocker/Game/Services/AI/BotTurnRoundProjectionService.swift`: runtime round projection helper for bot turns (bid normalization, future trick estimates, expected round score, and remaining-hand projection).
- `Jocker/Jocker/Game/Services/AI/BotTuning+SelfPlayEvolution.swift`: thin `BotTuning` adapter over self-play evolution/head-to-head APIs (typealiases + forwarding methods), compiled in `JockerSelfPlayTools` (not in runtime app target).
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine.swift`: facade/namespace for self-play evolution; implementation is split across `BotSelfPlayEvolutionEngine+*.swift` and compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+PublicTypes.swift`: public API types for self-play evolution (config, results, progress event), compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift`: self-play evolution orchestration (top-level `evolveViaSelfPlay`, head-to-head evaluation, early stopping), compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Fitness.swift`: fitness scoring configuration, per-seat metric aggregation, and candidate tuning evaluation, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Genome.swift`: genome model + mutation/crossover, evolution scope masking, and projection to `BotTuning`, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Simulation.swift`: shared self-play simulation types plus debug/public simulation entrypoints, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+SimulationMetrics.swift`: self-play metrics accumulator, blind exposure counters, and premium-support loss aggregation, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+SimulationBlindBidding.swift`: pre-deal blind context resolution and bidding-order helpers for self-play matches, compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+SimulationRoundEvaluation.swift`: round-level self-play evaluation (play loop, bid-loss penalties, and scored round assembly), compiled in `JockerSelfPlayTools`.
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+SimulationOrchestration.swift`: legacy/full-match self-play orchestration, dealing helpers, and seat-service bundling, compiled in `JockerSelfPlayTools`.
- `Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`: checked-in Swift training CLI that parses self-play options, runs baseline/evolution modes, aggregates ensemble tunings, and prints training/A-B summaries without shell-generated Swift sources.
- `Jocker/JockerSelfPlayTools/main.swift`: executable entrypoint for the checked-in training runner compiled by `scripts/train_bot_tuning.sh`.
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`: thin facade over regular bid selection and pre-deal blind bidding policy services.
- `Jocker/Jocker/Game/Services/AI/BotBidSelectionService.swift`: regular post-deal bid selection based on projected round score and block-progress-aware utility tie-breaking.
- `Jocker/Jocker/Game/Services/AI/BotBlindBidPolicy.swift`: pre-deal blind bidding risk engine that translates match pressure into target share, aggressive floor, and Monte Carlo inputs.
- `Jocker/Jocker/Game/Services/AI/BotBlindBidMonteCarloEstimator.swift`: deterministic blind bid estimator that samples pre-deal hands and ranks allowed blind bids under typed blind Monte Carlo policy.
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
- `Jocker/Jocker/Models/Players/PlayerDisplayNameFormatter.swift`: centralized trim/fallback player-name formatting shared by settings, flow models, export, and UIKit table/controllers.
- `Jocker/Jocker/Models/Bot/BotDifficulty.swift`: bot difficulty presets (`easy` / `normal` / `hard`) used to select AI behavior profile.
- `Jocker/Jocker/Models/Bot/BotMatchContext.swift`: normalized runtime match/block context payload for bot decisions (block index/progress, scores, dealer-relative seat position), used as feature-plumbing for stage 4a+.
- `Jocker/Jocker/Models/Bot/BotBlockPhase.swift`: block phase enum (early/mid/late) and deterministic mapping from `blockProgressFraction`; `PhaseMultipliers` for phase-conditioned policy scaling.
- `Jocker/Jocker/Models/Bot/BotOpponentModel.swift`: Stage-6 MVP opponent-style snapshot model (per-opponent observed blind/bid outcome/aggression rates within current block) built for runtime AI feature-plumbing.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy.swift`: centralized runtime policy model for non-evolutionary AI config previously spread across ranking/bidding/evaluator/rollout/endgame/simulation/hand-strength/heuristics/opponent constants, keeping the canonical `preset(for:)` entrypoint plus difficulty patch logic.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+PresetSections.swift`: assembles `hardBaselinePreset` from per-section constants; no longer holds section definitions directly.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+RankingPreset.swift`: `hardBaselineRanking` preset for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+BiddingPreset.swift`: `hardBaselineBidding` preset for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+EvaluatorPreset.swift`: `hardBaselineEvaluator` preset for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+RolloutPreset.swift`: `hardBaselineRollout` and `hardBaselineEndgame` presets for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+HeuristicsPreset.swift`: `hardBaselineSimulation`, `hardBaselineHandStrength`, and `hardBaselineHeuristics` presets for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+OpponentModelingPreset.swift`: `hardBaselineOpponentModeling` preset for `BotRuntimePolicy`.
- `Jocker/Jocker/Models/Bot/BotTuning.swift`: centralized bot config root that owns tunable coefficients, timing presets, runtime policy, and joker-policy projection consumed by bot services and gameplay flow delays, while keeping `BotTuning(difficulty:)` as the canonical preset entrypoint.
- `Jocker/Jocker/Models/Bot/BotTuning+Presets.swift`: hard-baseline preset data plus `normal`/`easy` patch helpers for `BotTuning`, so preset values no longer live as three independent monolithic literals.
- `Jocker/Jocker/Scoring/GameRoundResultsBuilder.swift`: shared mapper from `GameState` runtime round state to `[RoundResult]`, reused by flow recording and in-progress score-table snapshots.
- `Jocker/Jocker/Scoring/ScoreCalculator.swift`: pure scoring formulas (round score, premium bonus, premium penalty, zero premium).
- `Jocker/Jocker/Scoring/PremiumRules.swift`: pure block-level premium/penalty finalization (premium players, zero-premium eligibility, penalty targets, and bonus embedding into the last deal).
- `Jocker/Jocker/Scoring/ScoreManager.swift`: sole owner of accumulated game scores, block persistence, standings helpers, and premium application.
- `Jocker/Jocker/ViewControllers/Common/PanelAppearance.swift`: shared UIKit panel palette and chrome constants for full-screen and overlay screens.
- `Jocker/Jocker/ViewControllers/Common/PanelTypography.swift`: shared AvenirNext typography helpers for UIKit panel headers, buttons, and compact table labels.
- `Jocker/Jocker/ViewControllers/Common/PanelContainerView.swift`: reusable rounded/bordered panel shell for UIKit screen and modal containers.
- `Jocker/Jocker/ViewControllers/Common/PanelHeaderView.swift`: reusable title/subtitle header stack with left/center alignment for panel screens.
- `Jocker/Jocker/ViewControllers/Common/PrimaryPanelButton.swift`: shared primary CTA button with accent panel styling.
- `Jocker/Jocker/ViewControllers/Common/SecondaryPanelButton.swift`: shared secondary/neutral CTA button for panel screens.
- `Jocker/Jocker/ViewControllers/GameFlow/PlayerSettingsRowView.swift`: reusable settings row for one player slot (name field + bot difficulty controls) used by `GameParametersViewController` without tag-based action decoding.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableView.swift`: render-only score grid that maps rounds/blocks to table rows and summary lines, with defensive summary/cumulative rendering for partial score arrays.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableInProgressRoundSnapshotProvider.swift`: provider that precomputes in-progress round cells for `ScoreTableView`, removing direct `ScoreManager` reads from row render passes.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRenderSnapshotBuilder.swift`: pure snapshot/model builder for `ScoreTableView` that extracts score data and computes premium/penalty decoration metadata outside the view render pass.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableLabelFrameResolver.swift`: pure frame calculator for `ScoreTableView` labels (header, cards, tricks, points) and pinned-header y-adjustment based on current column widths and row metrics.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowNavigationResolver.swift`: pure row navigation helper for `ScoreTableView` that resolves scroll targets for deal rows and block summary rows from static row mappings.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowPresentationResolver.swift`: pure row presentation helper for `ScoreTableView` that defines cards-column text and row-level points label style (`regular` vs `summary`).
- `Jocker/Jocker/ViewControllers/Results/ScoreTableScrollOffsetResolver.swift`: pure scroll-offset calculator for `ScoreTableView` that centers target rows and clamps vertical offsets to scroll bounds.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableTapTargetResolver.swift`: pure tap hit-testing helper for `ScoreTableView` that maps tap coordinates to a deal row target (`blockIndex`, `roundIndex`) using static row mappings.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableRowTextRenderer.swift`: pure row text renderer for `ScoreTableView` that builds per-cell tricks/points strings for deal/subtotal/cumulative rows, including in-progress round overlays and summary score formatting.
- `Jocker/Jocker/ViewControllers/Results/DealHistoryPresentationBuilder.swift`: pure presentation builder for one deal history screen (header text, hand rows, trick sections, and normalized export payload).
- `Jocker/Jocker/ViewControllers/Results/DealHistoryExportCoordinator.swift`: export/share flow helper for the deal-history screen, encapsulating JSON export state, alerts, and activity presentation.
- `Jocker/Jocker/ViewControllers/Bidding/JokerModeSelectionViewController.swift`: modal joker play-mode picker (lead and non-lead cases).
- `Jocker/Jocker/ViewControllers/Bidding/BidSelectionModalBaseViewController.swift`: shared bid-selector modal base built on common panel chrome (container, labels, primary actions, scroll grid, and bid-button rows).
- `Jocker/Jocker/ViewControllers/Bidding/BidSelectionViewController.swift`: modal selector of human post-deal bid amount with current hand/trump context and bidding summary panel.
- `Jocker/Jocker/ViewControllers/Bidding/PreDealBlindSelectionViewController.swift`: modal selector of pre-deal blind mode (`open after deal` vs `blind bid`) and blind bid amount list.
- `Jocker/Jocker/ViewControllers/Bidding/TrumpSelectionViewController.swift`: modal selector of trump suit (or no-trump) for the chooser in blocks 2 and 4.
- `Jocker/Jocker/ViewControllers/GameFlow/GameParametersViewController.swift`: full-screen settings form for all player names and per-bot difficulty controls, now delegating row UI and difficulty selection handling to `PlayerSettingsRowView`.
- `Jocker/Jocker/ViewControllers/GameFlow/FirstPlayerAnnouncementViewController.swift`: overlay modal that announces the first player and confirms continuation before the first deal.
- `Jocker/Jocker/ViewControllers/Results/GameResultsViewController.swift`: end-of-game modal showing final placements and per-player summary metrics across all blocks.
- `Jocker/Jocker/ViewControllers/Statistics/GameStatisticsPresentationProvider.swift`: presentation provider for statistics tables (metric definitions, score formatting, seat normalization, and row view models).
- `Jocker/Jocker/ViewControllers/Statistics/GameStatisticsViewController.swift`: statistics screen with tabbed table for all games, 4-player games, and 3-player games, delegating row construction to `GameStatisticsPresentationProvider`.
- `Jocker/Jocker/ViewControllers/Statistics/GameStatisticsTableView.swift`: render-only grid-style statistics table that consumes prebuilt presentation rows.
- `Jocker/Jocker/ViewControllers/Results/DealHistoryViewController.swift`: modal details for a selected deal that renders builder-produced sections and delegates export/share flow to `DealHistoryExportCoordinator`.

### Tooling & Documentation

- `Makefile`: developer convenience targets; `make bt` / `make train-bot` point to the canonical full-match training workflow, `make train-bot-final` runs the canonical final validation workflow, and legacy short random-round profiles are now prefixed `legacy-` (`legacy-bt-<difficulty>-<smoke|balanced|battle>`). `bt-hard-fullgame-<smoke|balanced|battle>` run full-match (4-block) single-seed training with seat rotation; `bt-hard-final` runs multi-seed ensemble full-match training. `make training-pipeline-smoke` runs compile/baseline/evolution smoke checks for the checked-in runner (including a tiny parallel evolution with `--max-parallel-evaluations 2`). `make stage5-benchmark` runs the Stage-05 parallel benchmark (canonical profile `bt-hard-fullgame-balanced`, sequential vs 2/4 parallel, parity and speedup summary under `.derivedData/stage5-parallel-benchmark/<timestamp>/`). `make joker-pack` / `make joker-pack-all` run the Stage-5 `JOKER` regression pack (`strict` only vs `strict+probe`). `make stage4-phase-pack` runs the Stage-4 phase-conditioned runtime guardrails pack (`make stage4-phase-pack-list`, `make stage4-phase-pack-dry` for inspection). `make stage6b-pack` runs the Stage-6b opponent-aware ranking guardrails pack; `make stage6b-pack-all` adds cross-service Stage-6 guardrails (flow plumbing + evaluator/strategy `no-evidence` neutrality + style-shift checks) (`make stage6b-pack-list`, `make stage6b-pack-dry` for inspection). `make bot-baseline` / `make bot-baseline-smoke` run the Stage-0 baseline snapshot harness (`run-mode=baselineOnly`) with persisted artifacts. `make bot-compare` / `make bot-compare-smoke` run the Stage-0 A/B comparison harness (baseline preset vs tuned candidate) with parsed A/B summary artifacts.
- `docs/BOT_AI_IMPROVEMENT_PLAN.md`: staged implementation roadmap for bot gameplay AI improvements (premiums/blind/joker/phase-aware decisions/opponent adaptation), including acceptance criteria and PR slicing.
- `docs/BOT_RUNTIME_POLICY_AND_TUNING_REFACTORING_PLAN.md`: concrete step-by-step refactoring plan for `BotRuntimePolicy.swift` and `BotTuning.swift`, including fixed design decisions, execution order, and completion criteria.
- `docs/BOT_AI_IMPROVEMENT_PLAN_REVIEW.md`: review notes and critique of `docs/BOT_AI_IMPROVEMENT_PLAN.md`.
- `docs/BOT_AI_IMPROVEMENT_PROPOSALS_UNIFIED.md`: unified proposals backlog (best of mapped+consolidated) with runtime gaps taxonomy, metric definitions, and roadmap.
- `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`: learning-centric proposals for bot improvements (training signal, evaluation, and self-play iteration ideas).
- `docs/BOT_AI_LEARNING_IMPROVEMENT_DETAILED_PLANS/`: ordered, per-track execution plans derived from `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, with dependencies and sequencing aligned to `docs/BOT_RUNTIME_POLICY_AND_TUNING_REFACTORING_PLAN.md`.
- `docs/BOT_AI_FULL_TEST_COVERAGE_PLAN.md`: plan for extending bot-related test coverage (gaps, priorities, and slicing).
- `docs/BOT_AI_TEST_SCENARIOS.md`: draft catalog of deterministic bot-AI regression scenarios (`BLIND` / `PREMIUM` / `JOKER` / `PHASE`) plus baseline comparison templates and reproducibility fields for stage-0 measurements.
- `docs/CARDS_DOCUMENTATION.md`: rules notes and card/game documentation.
- `docs/CODEX_MCP_SKILLS_SETUP.md`: project-specific Codex setup guide covering recommended MCP servers, curated skills, and ready-to-paste `~/.codex/config.toml` snippets for this Swift/UIKit/SpriteKit repo.
- `docs/README_CARDS.md`: quick entrypoint/index to card-related documentation.
- `docs/XCODE_INTEGRATION.md`: how to open/build/test the project in Xcode (schemes, DerivedData, and CI alignment).
- `docs/CODE_REFACTORING_BACKLOG.md`: codebase refactoring notes and no-behavior-change improvement backlog (maintainability/testability).
- `.github/workflows/ios-tests.yml`: GitHub Actions CI workflow that runs Xcode tests on macOS for every `push` and uploads test run artifacts from `.derivedData/test-runs`.
- `scripts/run_all_tests.sh`: developer CLI entrypoint for full `xcodebuild test` run with persisted artifacts (`xcodebuild.log`, `TestResults.xcresult`, and `summary.txt`) under `.derivedData/test-runs/<timestamp>/`.
- `scripts/run_bot_ab_comparison_snapshot.sh`: Stage-0 companion harness for reproducible `baseline vs candidate` A/B validation (`A=basePreset`, `B=tunedOutput`); runs `train_bot_tuning.sh` with fixed training/validation seed profiles and saves raw/parsed A/B artifacts (`ab-*-section.txt`, `ab-*-metrics.txt`, `comparison-table.md`) under `.derivedData/bot-ab-runs/<timestamp>/`.
- `scripts/run_bot_baseline_snapshot.sh`: Stage-0 baseline harness for bot AI metrics; runs `train_bot_tuning.sh` in baseline-only mode (`--run-mode baselineOnly`) on fixed seed lists and stores artifacts (`train_bot_tuning.log`, `summary.txt`, `baseline-metrics.txt`, `command.txt`) under `.derivedData/bot-baseline-runs/<timestamp>/`.
- `scripts/run_joker_regression_pack.sh`: developer CLI entrypoint for Stage-5 `JOKER` regression pack runs (selected `strict` tests and optional `probe` tests) with persisted artifacts (`xcodebuild.log`, `TestResults.xcresult`, `summary.txt`, and `selected-tests.txt`) under `.derivedData/joker-regression-runs/<timestamp>/`.
- `scripts/run_stage4_phase_guardrails.sh`: developer CLI entrypoint for Stage-4 phase-conditioned guardrails pack (selected `PHASE-001`, `PHASE-003`, `BLIND-004`, `PREMIUM-012`, `JOKER-017` tests plus tuned variants where applicable), with persisted artifacts (`xcodebuild.log`, `summary.txt`, and `selected-tests.txt`) under `.derivedData/stage4-phase-runs/<timestamp>/`; the harness records phase expectations in `summary.txt` and intentionally skips `.xcresult` generation in local runs for simulator stability.
- `scripts/run_stage5_parallel_benchmark.sh`: Stage-05 parallel evaluation benchmark; warms runner via `--compile-only`, runs canonical profile (`bt-hard-fullgame-balanced`) with `--max-parallel-evaluations 1`, `2`, and `4`, saves raw logs and writes `summary.txt` with parity (aggregated metrics and best candidate) and speedup; artifacts under `.derivedData/stage5-parallel-benchmark/<timestamp>/`.
- `scripts/run_training_pipeline_smoke.sh`: checked-in smoke harness for the training pipeline; compiles the Swift runner, runs a short `baselineOnly` evaluation, runs a short 1-generation evolution, runs a tiny parallel evolution (`--max-parallel-evaluations 2`), and asserts that baseline mode does not enter the generation loop.
- `scripts/run_stage6b_ranking_guardrails.sh`: developer CLI entrypoint for Stage-6b opponent-aware ranking guardrails pack (selected `BotTurnCandidateRankingServiceTests` for `BLIND-004`, `PREMIUM-010/011`, `PHASE-003`, `JOKER-016`), with optional `--include-flow-plumbing` mode that adds cross-service Stage-6 guardrails (`GameScenePlayingFlowTests` opponent-model snapshot plumbing + evaluator/strategy `no-evidence` neutrality + style-shift checks); persists artifacts (`xcodebuild.log`, `TestResults.xcresult`, `summary.txt`, and `selected-tests.txt`) under `.derivedData/stage6b-ranking-runs/<timestamp>/`.
- `scripts/train_bot_tuning.sh`: thin shell entrypoint for offline self-play training; compiles the checked-in Swift runner from `Jocker/JockerSelfPlayTools/`, forwards CLI arguments, and optionally persists stdout logs.
- `Jocker/Jocker.xcodeproj/xcshareddata/xcschemes/Jocker.xcscheme`: shared Xcode scheme committed for CI/automation so `xcodebuild test -scheme Jocker` works on clean GitHub runners.
- `Jocker/Jocker.xcodeproj/project.pbxproj`: defines target boundaries; `JockerSelfPlayTools` (static library) owns self-play/training sources, while `Jocker` app target excludes them from runtime build.

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
│   │   ├── GameEnvironment.swift
│   │   ├── GameSceneModalPresenter.swift
│   │   ├── GameResultsPersistenceCoordinator.swift
│   │   └── DealHistoryPresentationCoordinator.swift
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
│   │   ├── GameSceneLayoutResolver.swift
│   │   ├── GameSceneNodeFactory.swift
│   │   ├── GameSceneSessionState.swift
│   │   ├── GameSceneInteractionBlockers.swift
│   │   ├── GameSceneInteractionState.swift
│   │   ├── GameSceneInteractionTransitionPolicy.swift
│   │   ├── GameScene+DealingFlow.swift
│   │   ├── GameScene+BiddingFlow.swift
│   │   ├── GameScene+PlayingFlow.swift
│   │   └── GameScene+ModalFlow.swift
│   └── Services/
│       ├── AI/
│       │   ├── BotBidSelectionService.swift
│       │   ├── BotBlindBidMonteCarloEstimator.swift
│       │   ├── BotBlindBidPolicy.swift
│       │   ├── BotBiddingService.swift
│       │   ├── BotRankNormalization.swift
│       │   ├── HandFeatureExtractor.swift
│       │   ├── BotHandStrengthModel.swift
│       │   ├── BotMatchContextBuilder.swift
│       │   ├── BotTurnBeliefStateBuilder.swift
│       │   ├── BotTurnCandidateEvaluatorService.swift
│       │   ├── BlockPlanResolver.swift
│       │   ├── OpponentPressureAdjuster.swift
│       │   ├── PremiumPreserveAdjuster.swift
│       │   ├── PenaltyAvoidAdjuster.swift
│       │   ├── PremiumDenyAdjuster.swift
│       │   ├── JokerDeclarationAdjuster.swift
│       │   ├── MoveUtilityComposer.swift
│       │   ├── CandidateTieBreakPolicy.swift
│       │   ├── BotTurnCandidateRankingService.swift
│       │   ├── BotTurnCardHeuristicsService.swift
│       │   ├── BotTurnEndgameSolver.swift
│       │   ├── BotTurnOpponentOrderResolver.swift
│       │   ├── BotTurnRolloutService.swift
│       │   ├── BotSelfPlayEvolutionEngine.swift
│       │   ├── BotSelfPlayEvolutionEngine+PublicTypes.swift
│       │   ├── BotSelfPlayEvolutionEngine+Fitness.swift
│       │   ├── BotSelfPlayEvolutionEngine+Genome.swift
│       │   ├── BotSelfPlayEvolutionEngine+Evolution.swift
│       │   ├── BotSelfPlayEvolutionEngine+Simulation.swift
│       │   ├── BotSelfPlayEvolutionEngine+SimulationMetrics.swift
│       │   ├── BotSelfPlayEvolutionEngine+SimulationBlindBidding.swift
│       │   ├── BotSelfPlayEvolutionEngine+SimulationRoundEvaluation.swift
│       │   ├── BotSelfPlayEvolutionEngine+SimulationOrchestration.swift
│       │   ├── BotTurnSamplingService.swift
│       │   ├── BotTurnSimulationService.swift
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
│   │   ├── BotRuntimePolicy.swift
│   │   ├── BotRuntimePolicy+PresetSections.swift
│   │   ├── BotRuntimePolicy+RankingPreset.swift
│   │   ├── BotRuntimePolicy+BiddingPreset.swift
│   │   ├── BotRuntimePolicy+EvaluatorPreset.swift
│   │   ├── BotRuntimePolicy+RolloutPreset.swift
│   │   ├── BotRuntimePolicy+HeuristicsPreset.swift
│   │   ├── BotRuntimePolicy+OpponentModelingPreset.swift
│   │   ├── BotTuning.swift
│   │   └── BotTuning+Presets.swift
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
│   │   ├── PlayerDisplayNameFormatter.swift
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
│   ├── Common/
│   │   ├── PanelAppearance.swift
│   │   ├── PanelContainerView.swift
│   │   ├── PanelHeaderView.swift
│   │   ├── PanelTypography.swift
│   │   ├── PrimaryPanelButton.swift
│   │   └── SecondaryPanelButton.swift
│   ├── GameFlow/
│   │   ├── FirstPlayerAnnouncementViewController.swift
│   │   ├── GameParametersViewController.swift
│   │   ├── GameViewController.swift
│   │   ├── PlayerSettingsRowView.swift
│   │   └── PlayerSelectionViewController.swift
│   ├── Results/
│   │   ├── DealHistoryExportCoordinator.swift
│   │   ├── DealHistoryPresentationBuilder.swift
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
│       ├── GameStatisticsPresentationProvider.swift
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
│   ├── BotBiddingServiceTestFixture.swift
│   ├── BotBiddingServiceTests.swift
│   ├── BotBlindBidPolicyTestFixture.swift
│   ├── BotBlindBidPolicyTests.swift
│   ├── BotBlockPhaseTests.swift
│   ├── BotHandStrengthModelTests.swift
│   ├── HandFeatureExtractorTests.swift
│   ├── BotMatchContextBuilderTestFixture.swift
│   ├── BotMatchContextBuilderTests.swift
│   ├── BotMatchContextTestBuilder.swift
│   ├── BotOpponentModelTests.swift
│   ├── BotRankNormalizationTests.swift
│   ├── BotTestCards.swift
│   ├── BotTrickNodeBuilder.swift
│   ├── BotTurnCandidateEvaluatorServiceTestFixture.swift
│   ├── BotTurnCandidateEvaluatorServiceTests.swift
│   ├── BotTurnCandidateRankingServiceTests.swift
│   ├── BotTurnCandidateRankingServiceTestFixture.swift
│   ├── BotTurnCandidateRankingServiceTests_TieBreak.swift
│   ├── BotTurnCandidateRankingServiceTests_Blind.swift
│   ├── BotTurnCandidateRankingServiceTests_JokerDeclaration.swift
│   ├── BotTurnCandidateRankingServiceTests_PhaseThreat.swift
│   ├── BotTurnCandidateRankingServiceTests_PremiumPenalty.swift
│   ├── BotTurnCardHeuristicsServiceTests.swift
│   ├── BotTurnDecisionContextBuilder.swift
│   ├── BotSelfPlayEvolutionEngineTests.swift
│   ├── BotTrumpSelectionServiceTests.swift
│   ├── BotTuningTests.swift
│   ├── BotTurnRoundProjectionServiceTests.swift
│   ├── BotTurnStrategyServiceTestFixture.swift
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
│   ├── GamePlayersSettingsStoreTests.swift
│   └── PlayerDisplayNameFormatterTests.swift
├── Results/
│   ├── DealHistoryPresentationBuilderTests.swift
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
│   ├── GameStatisticsPresentationProviderTests.swift
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
- Shared AI test builders and service fixtures live in `Jocker/JockerTests/Bot/` next to the bot service regression suites they support.
- Unit tests are grouped by feature under `Jocker/JockerTests/` subfolders.
- Xcode Project Navigator groups under `Models/`, `Game/Services/`, `ViewControllers/`, and `JockerTests/` should mirror these filesystem subfolders 1:1.
- Shared core primitives are placed in `Jocker/Jocker/Core/`.
- Resource files (`.sks`, assets, storyboards) stay under `Jocker/Jocker/Resources/`, `Jocker/Jocker/Assets.xcassets/`, and `Jocker/Jocker/Base.lproj/`.
- Developer automation scripts are placed in `scripts/` at repository root.
- Project documentation Markdown lives under `docs/` at repository root.
- Game rules reference notes live under `правила игры/`.

## Type/File Rule

- For new entities, keep one top-level type per file and match file name to type name.
