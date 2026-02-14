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
    var playerNames: [String] = []
    private var gameScene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаём SKView программно
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)
        
        // Настройка отладочных параметров
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        
        // Создаём сцену для горизонтальной ориентации
        let scene = GameScene(size: CGSize(width: 2556, height: 1179))
        scene.scaleMode = .aspectFill
        scene.playerCount = playerCount
        scene.playerNames = playerNames
        scene.onScoreButtonTapped = { [weak self] in
            self?.presentScoreTable()
        }
        scene.onTricksButtonTapped = { [weak self, weak scene] playerNames, maxTricks, currentBids, dealerIndex in
            guard let self = self else { return }
            self.presentTricksOrder(
                playerNames: playerNames,
                maxTricks: maxTricks,
                currentBids: currentBids,
                dealerIndex: dealerIndex
            ) { bids in
                scene?.applyOrderedTricks(bids)
            }
        }
        scene.onJokerDecisionRequested = { [weak self] isLeadCard, completion in
            self?.presentJokerModeSelection(isLeadCard: isLeadCard, completion: completion)
        }
        self.gameScene = scene
        
        // Показываем сцену
        skView.presentScene(scene)
    }

    private func presentScoreTable() {
        guard let scene = gameScene else { return }
        let scoreManager = scene.scoreManager
        let scoreVC = ScoreTableViewController(
            scoreManager: scoreManager,
            firstColumnPlayerIndex: scene.scoreTableFirstPlayerIndex,
            playerNames: scene.currentPlayerNames
        )
        scoreVC.modalPresentationStyle = .fullScreen
        scoreVC.modalTransitionStyle = .crossDissolve
        present(scoreVC, animated: true, completion: nil)
    }
    
    private func presentTricksOrder(
        playerNames: [String],
        maxTricks: Int,
        currentBids: [Int],
        dealerIndex: Int,
        onSubmit: @escaping ([Int]) -> Void
    ) {
        let orderVC = TricksOrderViewController(
            playerNames: playerNames,
            maxTricks: maxTricks,
            currentBids: currentBids,
            dealerIndex: dealerIndex,
            onSubmit: onSubmit
        )
        orderVC.modalPresentationStyle = .overFullScreen
        orderVC.modalTransitionStyle = .crossDissolve
        present(orderVC, animated: true)
    }

    private func presentJokerModeSelection(
        isLeadCard: Bool,
        completion: @escaping (JokerPlayDecision?) -> Void
    ) {
        let jokerVC = JokerModeSelectionViewController(
            isLeadCard: isLeadCard,
            onSubmit: { decision in
                completion(decision)
            },
            onCancel: {
                completion(nil)
            }
        )
        jokerVC.modalPresentationStyle = .overFullScreen
        jokerVC.modalTransitionStyle = .crossDissolve
        present(jokerVC, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Только горизонтальная ориентация
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
