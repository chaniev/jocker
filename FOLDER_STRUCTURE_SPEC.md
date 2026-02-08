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
│   └── PlayerSelectionViewController.swift
├── Actions.sks
├── GameScene.sks
├── Assets.xcassets/
└── Base.lproj/
```

## File Moves (old -> new)

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
```

## Xcode Project Updates

- Added groups: App, Models, Game/Scenes, Game/Nodes, Scoring, ViewControllers.
- File references updated by group placement (relative paths).

## Unit Tests

- No test file moves were performed.
- `JockerTests` and `JockerUITests` stay in place and remain referenced in the project.

## Notes

- `Actions.sks` and `GameScene.sks` remain at `Jocker/Jocker/` (resource files).
- Assets and storyboards remain under `Assets.xcassets` and `Base.lproj`.

## Future Conventions

- New domain models go in `Models/`.
- New SpriteKit scenes go in `Game/Scenes/`.
- New SpriteKit nodes go in `Game/Nodes/`.
- View controllers go in `ViewControllers/`.
- Scoring logic stays in `Scoring/`.

