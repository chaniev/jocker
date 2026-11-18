//
//  PlayerSelectionViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit

class PlayerSelectionViewController: UIViewController {
    private var selectedPlayerCount: Int = 4
    private var selectedGameMode: GameMode = .freeForAll
    private var isStartingGame = false
    private var hasRecoveryError = false

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
        GamePersistenceRepository.shared.sessions.recover { [weak self] result in
            guard let self else { return }
            if case .failure = result { self.hasRecoveryError = true; self.presentRecoveryErrorIfNeeded() }
        }
        setupUI()
        updateButtonStates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentRecoveryErrorIfNeeded()
    }

    private func presentRecoveryErrorIfNeeded() {
        guard self.hasRecoveryError, self.view.window != nil, self.presentedViewController == nil, !self.isStartingGame else { return }
        self.hasRecoveryError = false
        let alert = UIAlertController(title: "Запись итогов отложена", message: "Не удалось обновить статистику или историю. Сохранённые итоги остаются в очереди; можно продолжать и начинать новые партии.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        self.present(alert, animated: true)
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
        selectedGameMode = selectedPlayerCount == 4 ? selectedGameMode : .freeForAll
        updateButtonStates()
        isStartingGame = true

        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            }) { _ in
                self.updateButtonStates()
                if self.selectedPlayerCount == 4 {
                    self.presentGameModeSelection()
                } else {
                    self.checkSavedGame()
                }
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

    private func checkSavedGame() {
        let slot = GameSessionSlot(playerCount: self.selectedPlayerCount, gameMode: self.selectedGameMode)
        GamePersistenceRepository.shared.sessions.load(slot) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(nil): self.startGame()
            case .success(let snapshot?):
                let alert = UIAlertController(title: "Сохранённая игра", message: "Начав новую игру, вы безвозвратно удалите прежнюю партию и весь её прогресс. Она не попадёт в статистику и историю.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Продолжить сохранённую игру", style: .default) { [weak self] _ in self?.startGame(restored: snapshot) })
                alert.addAction(UIAlertAction(title: "Начать новую", style: .destructive) { [weak self] _ in self?.discardSavedGame(slot) })
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in self?.isStartingGame = false })
                self.present(alert, animated: true)
            case .failure:
                let alert = UIAlertController(title: "Сохранение недоступно", message: "Не удалось прочитать сохранение. При начале новой игры прежний прогресс будет потерян.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Начать новую", style: .destructive) { [weak self] _ in self?.discardSavedGame(slot) })
                alert.addAction(UIAlertAction(title: "Назад", style: .cancel) { [weak self] _ in self?.isStartingGame = false })
                self.present(alert, animated: true)
            }
        }
    }

    private func discardSavedGame(_ slot: GameSessionSlot) {
        GamePersistenceRepository.shared.sessions.discard(slot) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success: self.startGame()
            case .failure:
                let alert = UIAlertController(title: "Не удалось удалить сохранение", message: "Новая партия ещё не начата. Повторите удаление или вернитесь к выбору варианта.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in self?.discardSavedGame(slot) })
                alert.addAction(UIAlertAction(title: "Назад", style: .cancel) { [weak self] _ in self?.isStartingGame = false })
                self.present(alert, animated: true)
            }
        }
    }

    private func startGame(restored: GameSessionSnapshot? = nil) {
        let activeNames = gamePlayersSettings.activePlayerNames(playerCount: selectedPlayerCount)
        let activeDifficulties = gamePlayersSettings.activeBotDifficulties(playerCount: selectedPlayerCount)

        let gameVC = GameViewController()
        gameVC.restoredSession = restored
        gameVC.playerCount = selectedPlayerCount
        gameVC.gameMode = selectedGameMode.normalized(for: selectedPlayerCount)
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

    private func presentGameModeSelection() {
        let alert = UIAlertController(
            title: "Режим на 4 игроков",
            message: "Выбери вариант партии. В режиме пар игроки 1 и 3 играют против игроков 2 и 4.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: GameMode.freeForAll.title, style: .default) { [weak self] _ in
            guard let self else { return }
            self.selectedGameMode = .freeForAll
            self.checkSavedGame()
        })
        alert.addAction(UIAlertAction(title: GameMode.pairs.title, style: .default) { [weak self] _ in
            guard let self else { return }
            self.selectedGameMode = .pairs
            self.checkSavedGame()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.isStartingGame = false
        })

        if let popover = alert.popoverPresentationController {
            popover.sourceView = fourPlayersButton
            popover.sourceRect = fourPlayersButton.bounds
        }

        present(alert, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
