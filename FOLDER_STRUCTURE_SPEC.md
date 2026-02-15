# Folder Structure Spec (Jocker)

## Scope

This document is the source of truth for repository structure and file placement.

## Repository Layout (actual)

```
/
├── AGENTS.md
├── FOLDER_STRUCTURE_SPEC.md
├── CARDS_DOCUMENTATION.md
├── README.md
├── README_CARDS.md
├── XCODE_INTEGRATION.md
├── правила игры/
│   ├── выбор козыря.txt
│   ├── выбор первого раздающего.txt
│   ├── забор карт с кона.txt
│   ├── общие.txt
│   ├── особенности игры с джокером.txt
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
- `Jocker/Jocker/Game/Services/GameRoundService.swift`: transitions between rounds/blocks, one-time block finalization recording, and round recording guards against inconsistent player snapshots.
- `Jocker/Jocker/Game/Services/GameTurnService.swift`: entrypoint for automatic bot turn decision and trick winner resolution.
- `Jocker/Jocker/Game/Services/BotTurnStrategyService.swift`: bot move strategy (target bid tracking, card selection priority, joker mode declaration).
- `Jocker/Jocker/Game/Services/BotBiddingService.swift`: bot bidding heuristic that projects expected tricks and selects bid with best projected score.
- `Jocker/Jocker/Game/Services/BotTrumpSelectionService.swift`: bot trump chooser for blocks 2 and 4 based on the pre-deal subset of cards.
- `Jocker/Jocker/Game/Services/GameAnimationService.swift`: deal and delayed trick-resolution animation scheduling/cancellation.
- `Jocker/Jocker/Game/Nodes/TrickNode.swift`: current trick state and move legality checks (including joker lead modes).
- `Jocker/Jocker/Models/TrickTakingResolver.swift`: pure winner algorithm for a trick with joker semantics.
- `Jocker/Jocker/Models/TrumpSelectionRules.swift`: round-level rules for trump selection mode (automatic vs player-chosen), chooser seat, and staged-deal size.
- `Jocker/Jocker/Models/GameFinalPlayerSummary.swift`: computes final standings payload per player (place, total score, block-by-block scores, premiums per block, total premiums, and fourth-block blind count).
- `Jocker/Jocker/Models/PlayerControlType.swift`: player control mode (`human` / `bot`) used by the scene/controller flow.
- `Jocker/Jocker/Models/BotDifficulty.swift`: bot difficulty presets (`easy` / `normal` / `hard`) used to select AI behavior profile.
- `Jocker/Jocker/Models/BotTuning.swift`: centralized coefficients and timing presets consumed by bot services and gameplay flow delays.
- `Jocker/Jocker/Scoring/ScoreCalculator.swift`: pure scoring formulas (round score, premium bonus, premium penalty, zero premium).
- `Jocker/Jocker/Scoring/ScoreManager.swift`: score persistence through blocks and premium application.
- `Jocker/Jocker/ViewControllers/ScoreTableView.swift`: render-only score grid that maps rounds/blocks to table rows and summary lines, with defensive summary/cumulative rendering for partial score arrays.
- `Jocker/Jocker/ViewControllers/JokerModeSelectionViewController.swift`: modal joker play-mode picker (lead and non-lead cases).
- `Jocker/Jocker/ViewControllers/BidSelectionViewController.swift`: modal selector of human bid amount and pre-deal blind choice, built from shared UI factories (container, labels, scroll grid, and bid-button rows).
- `Jocker/Jocker/ViewControllers/TrumpSelectionViewController.swift`: modal selector of trump suit (or no-trump) for the chooser in blocks 2 and 4.
- `Jocker/Jocker/ViewControllers/GameResultsViewController.swift`: end-of-game modal showing final placements and per-player summary metrics across all blocks.

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
│       ├── GameAnimationService.swift
│       ├── BotBiddingService.swift
│       ├── BotTrumpSelectionService.swift
│       ├── BotTurnStrategyService.swift
│       ├── GameRoundService.swift
│       └── GameTurnService.swift
├── Models/
│   ├── BlockResult.swift
│   ├── BotDifficulty.swift
│   ├── BotTuning.swift
│   ├── Card.swift
│   ├── Deck.swift
│   ├── GameBlock.swift
│   ├── GameBlockFormatter.swift
│   ├── GameConstants.swift
│   ├── GameFinalPlayerSummary.swift
│   ├── GamePhase.swift
│   ├── GameState.swift
│   ├── JokerLeadDeclaration.swift
│   ├── JokerPlayStyle.swift
│   ├── JokerPlayDecision.swift
│   ├── PlayedTrickCard.swift
│   ├── PlayerControlType.swift
│   ├── PlayerInfo.swift
│   ├── RoundResult.swift
│   ├── TrumpSelectionRules.swift
│   └── TrickTakingResolver.swift
├── Resources/
│   ├── Actions.sks
│   └── GameScene.sks
├── Scoring/
│   ├── ScoreCalculator.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── BidSelectionViewController.swift
│   ├── GameViewController.swift
│   ├── GameResultsViewController.swift
│   ├── JokerModeSelectionViewController.swift
│   ├── PlayerSelectionViewController.swift
│   ├── ScoreTableView.swift
│   ├── ScoreTableViewController.swift
│   └── TrumpSelectionViewController.swift
├── Assets.xcassets/
└── Base.lproj/
    ├── LaunchScreen.storyboard
    └── Main.storyboard
```

## Test Targets Layout

```
Jocker/JockerTests/
├── AGENTS.md
├── AutoPlayFlowTests.swift
├── BotBiddingServiceTests.swift
├── BotTuningTests.swift
├── BotTrumpSelectionServiceTests.swift
├── BotTurnStrategyServiceTests.swift
├── GameFlowIntegrationTests.swift
├── GameFinalPlayerSummaryTests.swift
├── GameScenePlayingFlowTests.swift
├── GameStateTests.swift
├── JockerTests.swift
├── ScoreCalculatorTests.swift
├── ScoreManagerTests.swift
└── TrickTakingResolverTests.swift

Jocker/JockerUITests/
├── AGENTS.md
├── JockerUITests.swift
└── JockerUITestsLaunchTests.swift
```

## Placement Conventions

- Scene classes are placed in `Jocker/Jocker/Game/Scenes/`.
- Scene coordinators are placed in `Jocker/Jocker/Game/Coordinator/`.
- SpriteKit node classes are placed in `Jocker/Jocker/Game/Nodes/`.
- Game flow services are placed in `Jocker/Jocker/Game/Services/`.
- Domain and state models are placed in `Jocker/Jocker/Models/`.
- Scoring logic is placed in `Jocker/Jocker/Scoring/`.
- UIKit controllers and views are placed in `Jocker/Jocker/ViewControllers/`.
- Shared core primitives are placed in `Jocker/Jocker/Core/`.
- Resource files (`.sks`, assets, storyboards) stay under `Jocker/Jocker/Resources/`, `Jocker/Jocker/Assets.xcassets/`, and `Jocker/Jocker/Base.lproj/`.

## Type/File Rule

- For new entities, keep one top-level type per file and match file name to type name.
- Current legacy exception: `Jocker/Jocker/Models/Card.swift` intentionally contains related card types (`Suit`, `CardColor`, `Rank`, `Card`).
