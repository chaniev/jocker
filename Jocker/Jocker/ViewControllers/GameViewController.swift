//
//  GameViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var playerCount: Int = 4
    private var gameScene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаём SKView программно
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)
        
        // Настройка отладочных параметров
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        
        // Создаём сцену для горизонтальной ориентации
        let scene = GameScene(size: CGSize(width: 2556, height: 1179))
        scene.scaleMode = .aspectFill
        scene.playerCount = playerCount
        scene.onScoreButtonTapped = { [weak self] in
            self?.presentScoreTable()
        }
        scene.onTricksButtonTapped = { [weak self, weak scene] playerNames, maxTricks, currentBids in
            guard let self = self else { return }
            self.presentTricksOrder(
                playerNames: playerNames,
                maxTricks: maxTricks,
                currentBids: currentBids
            ) { bids in
                scene?.applyOrderedTricks(bids)
            }
        }
        self.gameScene = scene
        
        // Показываем сцену
        skView.presentScene(scene)
    }

    private func presentScoreTable() {
        guard let scoreManager = gameScene?.scoreManager else { return }
        let scoreVC = ScoreTableViewController(scoreManager: scoreManager)
        scoreVC.modalPresentationStyle = .fullScreen
        scoreVC.modalTransitionStyle = .crossDissolve
        present(scoreVC, animated: true, completion: nil)
    }
    
    private func presentTricksOrder(
        playerNames: [String],
        maxTricks: Int,
        currentBids: [Int],
        onSubmit: @escaping ([Int]) -> Void
    ) {
        let orderVC = TricksOrderViewController(
            playerNames: playerNames,
            maxTricks: maxTricks,
            currentBids: currentBids,
            onSubmit: onSubmit
        )
        orderVC.modalPresentationStyle = .overFullScreen
        orderVC.modalTransitionStyle = .crossDissolve
        present(orderVC, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Только горизонтальная ориентация
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
