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
│   ├── забор карт с кона.txt
│   ├── общие.txt
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
│   │   └── GameScene.swift
│   └── Services/
│       ├── GameAnimationService.swift
│       ├── GameRoundService.swift
│       └── GameTurnService.swift
├── Models/
│   ├── BlockResult.swift
│   ├── Card.swift
│   ├── Deck.swift
│   ├── GameBlock.swift
│   ├── GameBlockFormatter.swift
│   ├── GameConstants.swift
│   ├── GamePhase.swift
│   ├── GameState.swift
│   ├── JokerLeadDeclaration.swift
│   ├── JokerPlayStyle.swift
│   ├── JokerPlayDecision.swift
│   ├── PlayedTrickCard.swift
│   ├── PlayerInfo.swift
│   ├── RoundResult.swift
│   └── TrickTakingResolver.swift
├── Resources/
│   ├── Actions.sks
│   └── GameScene.sks
├── Scoring/
│   ├── ScoreCalculator.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── GameViewController.swift
│   ├── JokerModeSelectionViewController.swift
│   ├── PlayerSelectionViewController.swift
│   ├── ScoreTableView.swift
│   ├── ScoreTableViewController.swift
│   └── TricksOrderViewController.swift
├── Assets.xcassets/
└── Base.lproj/
    ├── LaunchScreen.storyboard
    └── Main.storyboard
```

## Test Targets Layout

```
Jocker/JockerTests/
├── AGENTS.md
├── GameFlowIntegrationTests.swift
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
