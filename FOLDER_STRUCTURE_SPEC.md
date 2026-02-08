# Folder Structure Spec (Jocker)

## Scope

This spec describes the source folder grouping applied to the iOS project and how files are organized for future updates.

## Current Layout (source-only)

```
Jocker/Jocker/
├── App/
│   └── AppDelegate.swift
├── Core/
│   └── GameColors.swift
├── Game/
│   ├── Scenes/
│   │   ├── GameScene.swift
│   │   └── CardDemoScene.swift
│   └── Nodes/
│       ├── CardNode.swift
│       ├── CardHandNode.swift
│       ├── GameButton.swift
│       ├── PlayerNode.swift
│       ├── PokerTableNode.swift
│       ├── TrickNode.swift
│       └── TrumpIndicator.swift
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
├── Scoring/
│   ├── ScoreCalculator.swift
│   └── ScoreManager.swift
├── ViewControllers/
│   ├── GameViewController.swift
│   ├── PlayerSelectionViewController.swift
│   ├── ScoreTableView.swift
│   └── ScoreTableViewController.swift
├── Resources/
│   ├── Actions.sks
│   └── GameScene.sks
├── Assets.xcassets/
└── Base.lproj/
    ├── LaunchScreen.storyboard
    └── Main.storyboard
```

## Canonical File Paths

```
AppDelegate.swift -> App/AppDelegate.swift
GameColors.swift -> Core/GameColors.swift
GameScene.swift -> Game/Scenes/GameScene.swift
CardDemoScene.swift -> Game/Scenes/CardDemoScene.swift
CardNode.swift -> Game/Nodes/CardNode.swift
CardHandNode.swift -> Game/Nodes/CardHandNode.swift
GameButton.swift -> Game/Nodes/GameButton.swift
PlayerNode.swift -> Game/Nodes/PlayerNode.swift
PokerTableNode.swift -> Game/Nodes/PokerTableNode.swift
TrickNode.swift -> Game/Nodes/TrickNode.swift
TrumpIndicator.swift -> Game/Nodes/TrumpIndicator.swift
BlockResult.swift -> Models/BlockResult.swift
Card.swift -> Models/Card.swift
Deck.swift -> Models/Deck.swift
GameBlock.swift -> Models/GameBlock.swift
GameConstants.swift -> Models/GameConstants.swift
GamePhase.swift -> Models/GamePhase.swift
GameState.swift -> Models/GameState.swift
PlayerInfo.swift -> Models/PlayerInfo.swift
RoundResult.swift -> Models/RoundResult.swift
ScoreCalculator.swift -> Scoring/ScoreCalculator.swift
ScoreManager.swift -> Scoring/ScoreManager.swift
GameViewController.swift -> ViewControllers/GameViewController.swift
PlayerSelectionViewController.swift -> ViewControllers/PlayerSelectionViewController.swift
ScoreTableView.swift -> ViewControllers/ScoreTableView.swift
ScoreTableViewController.swift -> ViewControllers/ScoreTableViewController.swift
Actions.sks -> Resources/Actions.sks
GameScene.sks -> Resources/GameScene.sks
```

## Xcode Project Updates

- Added groups: App, Core, Models, Game/Scenes, Game/Nodes, Scoring, ViewControllers, Resources.
- File references updated by group placement (relative paths).

## Unit Tests

- `JockerTests` contains:
  - `JockerTests.swift`
  - `ScoreCalculatorTests.swift`
  - `ScoreManagerTests.swift`
- `JockerUITests` contains:
  - `JockerUITests.swift`
  - `JockerUITestsLaunchTests.swift`

## Notes

- `Actions.sks` and `GameScene.sks` are stored under `Jocker/Jocker/Resources`.
- Assets and storyboards remain under `Assets.xcassets` and `Base.lproj`.

## Future Conventions

- One type per file: when creating a new class/enum/interface, create a new file with the same name.
- New domain models go in `Models/`.
- New SpriteKit scenes go in `Game/Scenes/`.
- New SpriteKit nodes go in `Game/Nodes/`.
- Core utilities (colors, constants, extensions) go in `Core/`.
- View controllers go in `ViewControllers/`.
- Scoring logic stays in `Scoring/`.
