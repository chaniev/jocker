//
//  GameViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var playerCount: Int = 4
    var playerNames: [String] = []
    var playerControlTypes: [PlayerControlType] = []
    var botDifficulty: BotDifficulty = .hard
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
        scene.playerControlTypes = playerControlTypes
        scene.botDifficulty = botDifficulty
        scene.onScoreButtonTapped = { [weak self] in
            self?.presentScoreTable()
        }
        scene.onJokerDecisionRequested = { [weak self] isLeadCard, completion in
            guard let self = self else {
                completion(nil)
                return
            }
            self.presentJokerModeSelection(isLeadCard: isLeadCard, completion: completion)
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
            playerNames: scene.currentPlayerNames,
            currentBlockIndex: scene.scoreTableCurrentBlockIndex,
            currentRoundIndex: scene.scoreTableCurrentRoundIndex
        )
        scoreVC.onDealSelected = { [weak self, weak scoreVC] blockIndex, roundIndex in
            guard let self, let scoreVC else { return }
            self.presentDealHistory(
                from: scoreVC,
                blockIndex: blockIndex,
                roundIndex: roundIndex
            )
        }
        scoreVC.modalPresentationStyle = .fullScreen
        scoreVC.modalTransitionStyle = .crossDissolve
        present(scoreVC, animated: true, completion: nil)
    }

    private func presentDealHistory(from presenter: UIViewController, blockIndex: Int, roundIndex: Int) {
        guard let scene = gameScene else { return }
        guard let dealHistory = scene.dealHistory(forBlockIndex: blockIndex, roundIndex: roundIndex) else {
            showMissingDealHistoryAlert(
                from: presenter,
                blockIndex: blockIndex,
                roundIndex: roundIndex
            )
            return
        }

        let historyViewController = DealHistoryViewController(
            dealHistory: dealHistory,
            playerNames: scene.currentPlayerNames
        )
        historyViewController.modalPresentationStyle = .fullScreen
        historyViewController.modalTransitionStyle = .crossDissolve
        presenter.present(historyViewController, animated: true)
    }

    private func showMissingDealHistoryAlert(from presenter: UIViewController, blockIndex: Int, roundIndex: Int) {
        let alert = UIAlertController(
            title: "История недоступна",
            message: "Для блока \(blockIndex + 1), раздачи \(roundIndex + 1) ещё нет сохранённых ходов.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        presenter.present(alert, animated: true)
    }
    
    private func presentJokerModeSelection(
        isLeadCard: Bool,
        completion: @escaping (JokerPlayDecision?) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                completion(nil)
                return
            }

            let presenter = self.topPresenter()
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
            presenter.present(jokerVC, animated: true)
        }
    }

    private func topPresenter() -> UIViewController {
        var presenter: UIViewController = self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Только горизонтальная ориентация
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
