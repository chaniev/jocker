//
//  GameSceneNodeFactory.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import SpriteKit

/// Small construction helper for reusable `GameScene` nodes.
struct GameSceneNodeFactory {
    func makePokerTable(sceneSize: CGSize, position: CGPoint) -> PokerTableNode {
        let table = PokerTableNode(sceneSize: sceneSize)
        table.position = position
        return table
    }

    func makeActionButton(
        title: String,
        position: CGPoint,
        onTap: @escaping () -> Void
    ) -> GameButton {
        let button = GameButton(title: title, size: GameSceneLayoutResolver.Metrics.actionButtonSize)
        button.position = position
        button.onTap = onTap
        return button
    }
}
