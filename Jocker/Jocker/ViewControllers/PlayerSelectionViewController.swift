//
//  PlayerSelectionViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import UIKit

class PlayerSelectionViewController: UIViewController {
    
    private var selectedPlayerCount: Int = 4
    
    // UI элементы
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Выберите количество игроков"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let threePlayersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("3 игрока", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
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
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = 4
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Устанавливаем фон как у игрового стола
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        setupUI()
        updateButtonStates()
    }
    
    private func setupUI() {
        // Добавляем элементы на view
        view.addSubview(titleLabel)
        view.addSubview(threePlayersButton)
        view.addSubview(fourPlayersButton)
        
        // Добавляем действия на кнопки
        threePlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        fourPlayersButton.addTarget(self, action: #selector(playerCountButtonTapped(_:)), for: .touchUpInside)
        
        // Настраиваем constraints - кнопки расположены горизонтально
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // 4 Players Button - слева
            fourPlayersButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            fourPlayersButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            fourPlayersButton.widthAnchor.constraint(equalToConstant: 200),
            fourPlayersButton.heightAnchor.constraint(equalToConstant: 80),
            
            // 3 Players Button - справа
            threePlayersButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            threePlayersButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            threePlayersButton.widthAnchor.constraint(equalToConstant: 200),
            threePlayersButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func playerCountButtonTapped(_ sender: UIButton) {
        selectedPlayerCount = sender.tag
        updateButtonStates()
        
        // Добавляем анимацию нажатия
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        startGame()
    }
    
    private func updateButtonStates() {
        // Обновляем внешний вид кнопок в зависимости от выбора
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
    
    private func startGame() {
        // Переход к игровому экрану
        let gameVC = GameViewController()
        gameVC.playerCount = selectedPlayerCount
        gameVC.modalPresentationStyle = .fullScreen
        gameVC.modalTransitionStyle = .crossDissolve
        
        present(gameVC, animated: true, completion: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

