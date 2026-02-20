//
//  PlayerSelectionViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit

class PlayerSelectionViewController: UIViewController, UITextFieldDelegate {
    private enum StorageKey {
        static let firstPlayerName = "Jocker.PlayerSelection.firstPlayerName.v1"
    }
    
    private var selectedPlayerCount: Int = 4
    private var selectedBotDifficulty: BotDifficulty = .hard
    private var isStartingGame = false
    
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
    
    private let playerOneNameField: UITextField = {
        let textField = UITextField()
        textField.text = "Игрок 1"
        textField.placeholder = "Игрок 1"
        textField.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        textField.textColor = .white
        textField.tintColor = .white
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        textField.rightViewMode = .always
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        playerOneNameField.delegate = self
        playerOneNameField.text = loadSavedFirstPlayerName()
        setupUI()
        updateButtonStates()
    }
    
    private func setupUI() {
        view.addSubview(contentContainerView)
        view.addSubview(statisticsButton)
        contentContainerView.addSubview(countButtonsStack)
        contentContainerView.addSubview(playerOneNameField)
        
        countButtonsStack.addArrangedSubview(fourPlayersButton)
        countButtonsStack.addArrangedSubview(threePlayersButton)
        
        threePlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        fourPlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        statisticsButton.addTarget(self, action: #selector(showStatisticsTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            contentContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.92),

            countButtonsStack.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            countButtonsStack.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            countButtonsStack.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            countButtonsStack.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            
            fourPlayersButton.heightAnchor.constraint(equalToConstant: 72),
            threePlayersButton.heightAnchor.constraint(equalToConstant: 72),
            
            playerOneNameField.topAnchor.constraint(equalTo: countButtonsStack.bottomAnchor, constant: 22),
            playerOneNameField.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            playerOneNameField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            playerOneNameField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            playerOneNameField.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),

            statisticsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            statisticsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            statisticsButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    @objc private func playerCountButtonTapped(_ sender: UIButton) {
        guard !isStartingGame else { return }

        view.endEditing(true)
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
    
    private func selectedPlayerNames() -> [String] {
        let firstName = normalizedFirstPlayerName(from: playerOneNameField.text)

        return (0..<selectedPlayerCount).map { index in
            if index == 0 {
                return firstName
            }
            return "Игрок \(index + 1)"
        }
    }

    private func normalizedFirstPlayerName(from rawName: String?) -> String {
        let trimmedName = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Игрок 1" : trimmedName
    }

    private func loadSavedFirstPlayerName() -> String {
        let savedName = UserDefaults.standard.string(forKey: StorageKey.firstPlayerName)
        return normalizedFirstPlayerName(from: savedName)
    }

    private func saveFirstPlayerName() {
        let normalizedName = normalizedFirstPlayerName(from: playerOneNameField.text)
        playerOneNameField.text = normalizedName
        UserDefaults.standard.set(normalizedName, forKey: StorageKey.firstPlayerName)
    }
    
    @objc private func handleBackgroundTap() {
        view.endEditing(true)
    }

    @objc private func showStatisticsTapped() {
        guard !isStartingGame else { return }

        view.endEditing(true)

        let statisticsViewController = GameStatisticsViewController()
        statisticsViewController.modalPresentationStyle = .fullScreen
        statisticsViewController.modalTransitionStyle = .crossDissolve
        present(statisticsViewController, animated: true)
    }
    
    private func startGame() {
        saveFirstPlayerName()
        let names = selectedPlayerNames()
        
        let gameVC = GameViewController()
        gameVC.playerCount = selectedPlayerCount
        gameVC.playerNames = names
        gameVC.playerControlTypes = (0..<selectedPlayerCount).map { index in
            index == 0 ? .human : .bot
        }
        gameVC.botDifficulty = selectedBotDifficulty
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .crossDissolve
        
        present(gameVC, animated: true) { [weak self] in
            self?.isStartingGame = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === playerOneNameField else { return }
        saveFirstPlayerName()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
