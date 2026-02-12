# Folder Structure Spec (Jocker)

## Scope

This document is the source of truth for repository structure and file placement.

## Repository Layout (high level)

```
/
├── AGENTS.md
├── FOLDER_STRUCTURE_SPEC.md
├── CARDS_DOCUMENTATION.md
├── README.md
├── README_CARDS.md
├── XCODE_INTEGRATION.md
├── правила игры/
│   ├── раздача карт.txt
│   ├── правила раздачи карт на 4 игроков.txt
│   └── подсчет очков.txt
└── Jocker/
    ├── Jocker/           (main app target sources)
    ├── JockerTests/      (unit tests)
    └── JockerUITests/    (UI tests)
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
│   ├── Nodes/
│   │   ├── CardHandNode.swift
│   │   ├── CardNode.swift
│   │   ├── GameButton.swift
│   │   ├── PlayerNode.swift
│   │   ├── PokerTableNode.swift
│   │   ├── TurnIndicatorNode.swift
│   │   ├── TrickNode.swift
│   │   └── TrumpIndicator.swift
│   └── Scenes/
│       ├── CardDemoScene.swift
│       └── GameScene.swift
├── Models/
│   ├── BlockResult.swift
│   ├── Card.swift
│   ├── Deck.swift
│   ├── GameBlock.swift
│   ├── GameConstants.swift
│   ├── GamePhase.swift
│   ├── GameState.swift
│   ├── PlayerInfo.swift
│   └── RoundResult.swift
├── Resources/
│   ├── Actions.sks
│   └── GameScene.sks
├── Scoring/
│   ├── ScoreCalculator.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── GameViewController.swift
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
├── JockerTests.swift
├── ScoreCalculatorTests.swift
└── ScoreManagerTests.swift

Jocker/JockerUITests/
├── AGENTS.md
├── JockerUITests.swift
└── JockerUITestsLaunchTests.swift
```

## Canonical Paths

Use repository-relative paths in docs and reviews:

- `Jocker/Jocker/App/AppDelegate.swift`
- `Jocker/Jocker/Core/GameColors.swift`
- `Jocker/Jocker/Game/Scenes/GameScene.swift`
- `Jocker/Jocker/Game/Scenes/CardDemoScene.swift`
- `Jocker/Jocker/Game/Nodes/CardNode.swift`
- `Jocker/Jocker/Game/Nodes/CardHandNode.swift`
- `Jocker/Jocker/Game/Nodes/GameButton.swift`
- `Jocker/Jocker/Game/Nodes/PlayerNode.swift`
- `Jocker/Jocker/Game/Nodes/PokerTableNode.swift`
- `Jocker/Jocker/Game/Nodes/TurnIndicatorNode.swift`
- `Jocker/Jocker/Game/Nodes/TrickNode.swift`
- `Jocker/Jocker/Game/Nodes/TrumpIndicator.swift`
- `Jocker/Jocker/Models/BlockResult.swift`
- `Jocker/Jocker/Models/Card.swift`
- `Jocker/Jocker/Models/Deck.swift`
- `Jocker/Jocker/Models/GameBlock.swift`
- `Jocker/Jocker/Models/GameConstants.swift`
- `Jocker/Jocker/Models/GamePhase.swift`
- `Jocker/Jocker/Models/GameState.swift`
- `Jocker/Jocker/Models/PlayerInfo.swift`
- `Jocker/Jocker/Models/RoundResult.swift`
- `Jocker/Jocker/Scoring/ScoreCalculator.swift`
- `Jocker/Jocker/Scoring/ScoreManager.swift`
- `Jocker/Jocker/ViewControllers/GameViewController.swift`
- `Jocker/Jocker/ViewControllers/PlayerSelectionViewController.swift`
- `Jocker/Jocker/ViewControllers/ScoreTableView.swift`
- `Jocker/Jocker/ViewControllers/ScoreTableViewController.swift`
- `Jocker/Jocker/ViewControllers/TricksOrderViewController.swift`
- `Jocker/Jocker/Resources/Actions.sks`
- `Jocker/Jocker/Resources/GameScene.sks`

## Placement Conventions

- One type per file: each new class/enum/protocol/struct is created in a separate file with matching name.
- Scene classes are placed in `Jocker/Jocker/Game/Scenes/`.
- SpriteKit node classes are placed in `Jocker/Jocker/Game/Nodes/`.
- Domain and state models are placed in `Jocker/Jocker/Models/`.
- Scoring logic is placed in `Jocker/Jocker/Scoring/`.
- UIKit controllers and views are placed in `Jocker/Jocker/ViewControllers/`.
- Shared core primitives (colors, global helpers, shared extensions) are placed in `Jocker/Jocker/Core/`.
- Resource files (`.sks`, assets, storyboards) stay under `Jocker/Jocker/Resources/`, `Jocker/Jocker/Assets.xcassets/`, and `Jocker/Jocker/Base.lproj/`.
