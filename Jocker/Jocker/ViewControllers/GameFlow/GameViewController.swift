//
//  GameViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private enum SceneLayout {
        static let referenceWidth: CGFloat = 2556
    }

    private enum UITestLayout {
        static let finishButtonHeight: CGFloat = 44
        static let finishButtonRightInset: CGFloat = 18
        static let finishButtonTopInset: CGFloat = 12
    }
    
    var playerCount: Int = 4
    var playerNames: [String] = []
    var playerControlTypes: [PlayerControlType] = []
    var botDifficulty: BotDifficulty = .hard
    var botDifficultiesByPlayer: [BotDifficulty] = []
    private var gameScene: GameScene?
    private var uiTestFinishButton: UIButton?

    private var isUITestMode: Bool {
        return ProcessInfo.processInfo.arguments.contains("-uiTestMode")
    }

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
        
        // Подбираем размер сцены под текущее соотношение сторон, чтобы на iPad не резались края.
        let scene = GameScene(size: adaptedSceneSize(for: skView.bounds.size))
        scene.scaleMode = .aspectFill
        scene.playerCount = playerCount
        scene.playerNames = playerNames
        scene.playerControlTypes = playerControlTypes
        scene.botDifficulty = botDifficulty
        scene.botDifficultiesByPlayer = botDifficultiesByPlayer
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
        setupUITestControlsIfNeeded()
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
            playerNames: scene.currentPlayerNames,
            playerControlTypes: scene.playerControlTypes
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

    private func setupUITestControlsIfNeeded() {
        guard isUITestMode else { return }
        guard uiTestFinishButton == nil else { return }

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("UITest: финал", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.77, green: 0.21, blue: 0.18, alpha: 0.94)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.accessibilityIdentifier = "ui_test_finish_game_button"
        button.addAction(
            UIAction { [weak self] _ in
                self?.gameScene?.completeGameAndPresentResultsForUITest()
            },
            for: .touchUpInside
        )

        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UITestLayout.finishButtonTopInset),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -UITestLayout.finishButtonRightInset),
            button.heightAnchor.constraint(equalToConstant: UITestLayout.finishButtonHeight)
        ])

        uiTestFinishButton = button
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Только горизонтальная ориентация
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func adaptedSceneSize(for viewSize: CGSize) -> CGSize {
        let width = max(viewSize.width, 1)
        let height = max(viewSize.height, 1)
        let aspectRatio = width / height

        return CGSize(
            width: SceneLayout.referenceWidth,
            height: SceneLayout.referenceWidth / aspectRatio
        )
    }
}
