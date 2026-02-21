# Folder Structure Spec (Jocker)

## Scope

This document is the source of truth for repository structure and file placement.

## Repository Layout (actual)

```
/
├── AGENTS.md
├── Makefile
├── FOLDER_STRUCTURE_SPEC.md
├── CARDS_DOCUMENTATION.md
├── README.md
├── README_CARDS.md
├── XCODE_INTEGRATION.md
├── scripts/
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
    └── Jocker.xcodeproj/          (Xcode project)
```

## Key File Responsibilities

- `Jocker/Jocker/Game/Scenes/GameScene.swift`: base gameplay scene shell (scene lifecycle, table/player/UI setup, shared layout helpers, and top-level touch routing).
- `Jocker/Jocker/Game/Scenes/GameScene+DealingFlow.swift`: dealing pipeline for each round (deck reset/shuffle, pre-deal blind step, staged dealing, and dealer-left trump choice stage).
- `Jocker/Jocker/Game/Scenes/GameScene+BiddingFlow.swift`: bidding pipeline (bidding order, human/bot bid progression, dealer forbidden-bid rule, and bidding-to-playing transition).
- `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`: trick-playing pipeline (tap hit-testing, bot autoplay scheduling, card placement, trick resolution, and trick-win registration).
- `Jocker/Jocker/Game/Scenes/GameScene+ModalFlow.swift`: unified overlay-modal entrypoints and callbacks for trump selection, bid/blind input, and joker play-mode decision fallback.
- `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift`: facade over round/turn/animation services; keeps scene logic thin and serializes trick resolution.
- `Jocker/Jocker/Game/Services/Flow/GameRoundService.swift`: transitions between rounds/blocks, one-time block finalization recording, and round recording guards against inconsistent player snapshots.
- `Jocker/Jocker/Game/Services/Flow/GameTurnService.swift`: entrypoint for automatic bot turn decision and trick winner resolution.
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift`: bot move strategy (target bid tracking, card selection priority, joker mode declaration) plus deterministic self-play evolution API for tuning coefficients.
- `Makefile`: developer convenience targets; `make bt` (alias `make train-bot`) runs bot self-play training workflow. Legacy quick presets (`bt-<difficulty>-<smoke|balanced|battle>`) run short random-round profiles for `easy`/`normal`/`hard`, while `bt-hard-fullgame-<smoke|balanced|battle>` and alias `bt-hard-final` run full-match (4-block) multi-seed training with seat rotation.
- `scripts/train_bot_tuning.sh`: developer CLI entrypoint for offline self-play training; compiles a local runner and prints tuned `BotTuning` values.
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`: bot bidding heuristic that projects expected tricks and selects bid with best projected score.
- `Jocker/Jocker/Game/Services/AI/BotTrumpSelectionService.swift`: bot trump chooser for blocks 2 and 4 based on the pre-deal subset of cards.
- `Jocker/Jocker/Game/Services/History/DealHistoryStore.swift`: in-memory capture of deal playback data (trump per deal, ordered trick moves, trick winners) plus per-move training samples (state/action/outcome).
- `Jocker/Jocker/Game/Services/History/DealHistoryExportService.swift`: persistent JSON export of deal history and training samples on block/game completion.
- `Jocker/Jocker/Game/Services/Flow/GameAnimationService.swift`: deal and delayed trick-resolution animation scheduling/cancellation.
- `Jocker/Jocker/Game/Services/Settings/GamePlayersSettingsStore.swift`: persistence of editable player names and per-bot difficulty presets (`UserDefaults`, v1 key).
- `Jocker/Jocker/Game/Services/Statistics/GameStatisticsStore.swift`: storage contract for game statistics persistence and retrieval.
- `Jocker/Jocker/Game/Services/Statistics/UserDefaultsGameStatisticsStore.swift`: `UserDefaults`-backed aggregation for all/3-player/4-player statistics.
- `Jocker/Jocker/Game/Nodes/TrickNode.swift`: current trick state and move legality checks (including joker lead modes).
- `Jocker/Jocker/Models/Gameplay/TrickTakingResolver.swift`: pure winner algorithm for a trick with joker semantics.
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
- `Jocker/Jocker/Models/Bot/BotTuning.swift`: centralized coefficients and timing presets consumed by bot services and gameplay flow delays.
- `Jocker/Jocker/Scoring/ScoreCalculator.swift`: pure scoring formulas (round score, premium bonus, premium penalty, zero premium).
- `Jocker/Jocker/Scoring/ScoreManager.swift`: score persistence through blocks and premium application.
- `Jocker/Jocker/ViewControllers/Results/ScoreTableView.swift`: render-only score grid that maps rounds/blocks to table rows and summary lines, with defensive summary/cumulative rendering for partial score arrays.
- `Jocker/Jocker/ViewControllers/Bidding/JokerModeSelectionViewController.swift`: modal joker play-mode picker (lead and non-lead cases).
- `Jocker/Jocker/ViewControllers/Bidding/BidSelectionViewController.swift`: modal selector of human bid amount and pre-deal blind choice, built from shared UI factories (container, labels, scroll grid, and bid-button rows).
- `Jocker/Jocker/ViewControllers/Bidding/TrumpSelectionViewController.swift`: modal selector of trump suit (or no-trump) for the chooser in blocks 2 and 4.
- `Jocker/Jocker/ViewControllers/GameFlow/GameParametersViewController.swift`: full-screen settings form for all player names and per-bot difficulty controls.
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
│   │   └── GameSceneCoordinator.swift
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
│   │   ├── GameScene+DealingFlow.swift
│   │   ├── GameScene+BiddingFlow.swift
│   │   ├── GameScene+PlayingFlow.swift
│   │   └── GameScene+ModalFlow.swift
│   └── Services/
│       ├── AI/
│       │   ├── BotBiddingService.swift
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
│   │   └── BotTuning.swift
│   ├── Cards/
│   │   ├── Card.swift
│   │   ├── CardColor.swift
│   │   ├── Deck.swift
│   │   ├── Rank.swift
│   │   └── Suit.swift
│   ├── Gameplay/
│   │   ├── BlockResult.swift
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
│   ├── ScoreCalculator.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── Bidding/
│   │   ├── BidSelectionViewController.swift
│   │   ├── JokerModeSelectionViewController.swift
│   │   └── TrumpSelectionViewController.swift
│   ├── GameFlow/
│   │   ├── GameParametersViewController.swift
│   │   ├── GameViewController.swift
│   │   └── PlayerSelectionViewController.swift
│   ├── Results/
│   │   ├── DealHistoryViewController.swift
│   │   ├── GameResultsViewController.swift
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
│   ├── BotTrumpSelectionServiceTests.swift
│   ├── BotTuningTests.swift
│   └── BotTurnStrategyServiceTests.swift
├── Flow/
│   ├── AutoPlayFlowTests.swift
│   ├── GameFlowIntegrationTests.swift
│   ├── GameScenePlayingFlowTests.swift
│   └── GameStateTests.swift
├── History/
│   ├── DealHistoryExportServiceTests.swift
│   └── DealHistoryStoreTests.swift
├── Players/
│   └── GamePlayersSettingsStoreTests.swift
├── Results/
│   └── GameResultsPresentationIntegrationTests.swift
├── Rules/
│   └── TrickTakingResolverTests.swift
├── Scoring/
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
