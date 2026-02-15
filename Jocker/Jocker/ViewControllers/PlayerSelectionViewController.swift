//
//  PlayerSelectionViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit

class PlayerSelectionViewController: UIViewController, UITextFieldDelegate {
    
    private var selectedPlayerCount: Int = 4
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Выберите количество игроков"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let namesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Имена игроков"
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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

    private let namesColumnsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 14
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let leftNamesColumnStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let rightNamesColumnStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let startGameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Начать игру", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        button.backgroundColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var nameTextFields: [UITextField] = {
        return (1...4).map { index in
            let textField = UITextField()
            textField.text = "Игрок \(index)"
            textField.placeholder = "Игрок \(index)"
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
            textField.returnKeyType = index < 4 ? .next : .done
            textField.delegate = self
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
            textField.leftViewMode = .always
            textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
            textField.rightViewMode = .always
            return textField
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        setupUI()
        updateButtonStates()
        updateVisibleNameFields()
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(countButtonsStack)
        view.addSubview(namesTitleLabel)
        view.addSubview(namesColumnsStackView)
        view.addSubview(startGameButton)
        
        countButtonsStack.addArrangedSubview(fourPlayersButton)
        countButtonsStack.addArrangedSubview(threePlayersButton)
        
        namesColumnsStackView.addArrangedSubview(leftNamesColumnStackView)
        namesColumnsStackView.addArrangedSubview(rightNamesColumnStackView)

        leftNamesColumnStackView.addArrangedSubview(nameTextFields[0])
        leftNamesColumnStackView.addArrangedSubview(nameTextFields[1])
        rightNamesColumnStackView.addArrangedSubview(nameTextFields[2])
        rightNamesColumnStackView.addArrangedSubview(nameTextFields[3])
        
        threePlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        fourPlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        startGameButton.addTarget(self, action: #selector(startGameButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            countButtonsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            countButtonsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countButtonsStack.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
            countButtonsStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            countButtonsStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            fourPlayersButton.heightAnchor.constraint(equalToConstant: 72),
            threePlayersButton.heightAnchor.constraint(equalToConstant: 72),
            
            namesTitleLabel.topAnchor.constraint(equalTo: countButtonsStack.bottomAnchor, constant: 20),
            namesTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            namesTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            namesTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            namesColumnsStackView.topAnchor.constraint(equalTo: namesTitleLabel.bottomAnchor, constant: 10),
            namesColumnsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            namesColumnsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            namesColumnsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            namesColumnsStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            
            startGameButton.topAnchor.constraint(equalTo: namesColumnsStackView.bottomAnchor, constant: 18),
            startGameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startGameButton.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            startGameButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            startGameButton.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            startGameButton.heightAnchor.constraint(equalToConstant: 66),
            startGameButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func playerCountButtonTapped(_ sender: UIButton) {
        guard selectedPlayerCount != sender.tag else { return }
        view.endEditing(true)
        selectedPlayerCount = sender.tag
        updateButtonStates()
        updateVisibleNameFields()
        
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = .identity
            }) { _ in
                self.updateButtonStates()
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
    
    private func updateVisibleNameFields() {
        for (index, field) in nameTextFields.enumerated() {
            field.isHidden = index >= selectedPlayerCount
            field.returnKeyType = index == selectedPlayerCount - 1 ? .done : .next
        }
    }
    
    private func selectedPlayerNames() -> [String] {
        return (0..<selectedPlayerCount).map { index in
            let fallback = "Игрок \(index + 1)"
            let rawValue = nameTextFields[index].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return rawValue.isEmpty ? fallback : rawValue
        }
    }
    
    @objc private func handleBackgroundTap() {
        view.endEditing(true)
    }
    
    @objc private func startGameButtonTapped() {
        startGame()
    }
    
    private func startGame() {
        let names = selectedPlayerNames()
        
        let gameVC = GameViewController()
        gameVC.playerCount = selectedPlayerCount
        gameVC.playerNames = names
        gameVC.playerControlTypes = (0..<selectedPlayerCount).map { index in
            index == 0 ? .human : .bot
        }
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .crossDissolve
        
        present(gameVC, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let currentIndex = nameTextFields.firstIndex(of: textField) else {
            textField.resignFirstResponder()
            return true
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < selectedPlayerCount {
            nameTextFields[nextIndex].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
