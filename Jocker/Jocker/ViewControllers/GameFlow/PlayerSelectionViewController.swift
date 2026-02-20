//
//  PlayerSelectionViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit

class PlayerSelectionViewController: UIViewController {
    private var selectedPlayerCount: Int = 4
    private var isStartingGame = false

    private let playersSettingsStore = GamePlayersSettingsStore()
    private var gamePlayersSettings: GamePlayersSettings = .default

    private let threePlayersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("3 игрока", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 3
        button.accessibilityIdentifier = "player_count_3_button"
        return button
    }()

    private let fourPlayersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("4 игрока", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 4
        button.accessibilityIdentifier = "player_count_4_button"
        return button
    }()

    private let countButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let statisticsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Статистика", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 22)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.20, green: 0.31, blue: 0.50, alpha: 0.95)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.95).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "statistics_button"
        return button
    }()

    private let gameParametersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Параметры игры", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 22)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.25, green: 0.37, blue: 0.24, alpha: 0.95)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.95).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "game_parameters_button"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        gamePlayersSettings = playersSettingsStore.loadSettings()

        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        setupUI()
        updateButtonStates()
    }

    private func setupUI() {
        view.addSubview(contentContainerView)
        view.addSubview(statisticsButton)
        view.addSubview(gameParametersButton)
        contentContainerView.addSubview(countButtonsStack)

        countButtonsStack.addArrangedSubview(fourPlayersButton)
        countButtonsStack.addArrangedSubview(threePlayersButton)

        threePlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        fourPlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        statisticsButton.addTarget(self, action: #selector(showStatisticsTapped), for: .touchUpInside)
        gameParametersButton.addTarget(self, action: #selector(showGameParametersTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            contentContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.92),

            countButtonsStack.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            countButtonsStack.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            countButtonsStack.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            countButtonsStack.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            countButtonsStack.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),

            fourPlayersButton.heightAnchor.constraint(equalToConstant: 72),
            threePlayersButton.heightAnchor.constraint(equalToConstant: 72),

            statisticsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            statisticsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            statisticsButton.heightAnchor.constraint(equalToConstant: 54),

            gameParametersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            gameParametersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            gameParametersButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func playerCountButtonTapped(_ sender: UIButton) {
        guard !isStartingGame else { return }

        selectedPlayerCount = sender.tag
        updateButtonStates()
        isStartingGame = true

        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            }) { _ in
                self.updateButtonStates()
                self.startGame()
            }
        }
    }

    private func updateButtonStates() {
        let buttons = [threePlayersButton, fourPlayersButton]

        for button in buttons {
            if button.tag == selectedPlayerCount {
                button.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0)
                button.layer.borderWidth = 3
                button.layer.borderColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0).cgColor
                button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else {
                button.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 0.7)
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
                button.transform = .identity
            }
        }
    }

    @objc private func showStatisticsTapped() {
        guard !isStartingGame else { return }

        let statisticsViewController = GameStatisticsViewController()
        statisticsViewController.modalPresentationStyle = .fullScreen
        statisticsViewController.modalTransitionStyle = .crossDissolve
        present(statisticsViewController, animated: true)
    }

    @objc private func showGameParametersTapped() {
        guard !isStartingGame else { return }

        let parametersViewController = GameParametersViewController(
            settings: gamePlayersSettings,
            onSave: { [weak self] updatedSettings in
                guard let self else { return }
                self.gamePlayersSettings = updatedSettings
                self.playersSettingsStore.saveSettings(updatedSettings)
            }
        )
        parametersViewController.modalPresentationStyle = .fullScreen
        parametersViewController.modalTransitionStyle = .crossDissolve
        present(parametersViewController, animated: true)
    }

    private func startGame() {
        let activeNames = gamePlayersSettings.activePlayerNames(playerCount: selectedPlayerCount)
        let activeDifficulties = gamePlayersSettings.activeBotDifficulties(playerCount: selectedPlayerCount)

        let gameVC = GameViewController()
        gameVC.playerCount = selectedPlayerCount
        gameVC.playerNames = activeNames
        gameVC.playerControlTypes = (0..<selectedPlayerCount).map { index in
            index == 0 ? .human : .bot
        }
        gameVC.botDifficultiesByPlayer = activeDifficulties
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .crossDissolve

        present(gameVC, animated: true) { [weak self] in
            self?.isStartingGame = false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
