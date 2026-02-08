# Folder Structure Spec (Jocker)

## Scope

This spec describes the source folder grouping applied to the iOS project and how files are organized for future updates.

## Current Layout (source-only)

```
Jocker/Jocker/
├── App/
│   └── AppDelegate.swift
├── Game/
│   ├── Scenes/
│   │   ├── GameScene.swift
│   │   └── CardDemoScene.swift
│   └── Nodes/
│       ├── CardNode.swift
│       ├── CardHandNode.swift
│       ├── PlayerNode.swift
│       ├── TrickNode.swift
│       └── TrumpIndicator.swift
├── Models/
│   ├── Card.swift
│   ├── Deck.swift
│   ├── GameState.swift
│   ├── RoundResult.swift
│   └── BlockResult.swift
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
GameScene.swift -> Game/Scenes/GameScene.swift
CardDemoScene.swift -> Game/Scenes/CardDemoScene.swift
CardNode.swift -> Game/Nodes/CardNode.swift
CardHandNode.swift -> Game/Nodes/CardHandNode.swift
PlayerNode.swift -> Game/Nodes/PlayerNode.swift
TrickNode.swift -> Game/Nodes/TrickNode.swift
TrumpIndicator.swift -> Game/Nodes/TrumpIndicator.swift
Card.swift -> Models/Card.swift
Deck.swift -> Models/Deck.swift
GameState.swift -> Models/GameState.swift
RoundResult.swift -> Models/RoundResult.swift
BlockResult.swift -> Models/BlockResult.swift
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

- Added groups: App, Models, Game/Scenes, Game/Nodes, Scoring, ViewControllers, Resources.
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
- View controllers go in `ViewControllers/`.
- Scoring logic stays in `Scoring/`.

