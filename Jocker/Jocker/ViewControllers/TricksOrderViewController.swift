//
//  TricksOrderViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 12.02.2026.
//

import UIKit

final class TricksOrderViewController: UIViewController {
    
    private let playerNames: [String]
    private let maxTricks: Int
    private let onSubmit: ([Int]) -> Void
    private var trickFields: [UITextField] = []
    
    init(
        playerNames: [String],
        maxTricks: Int,
        currentBids: [Int],
        onSubmit: @escaping ([Int]) -> Void
    ) {
        self.playerNames = playerNames
        self.maxTricks = max(0, maxTricks)
        self.onSubmit = onSubmit
        
        super.init(nibName: nil, bundle: nil)
        
        buildInputFields(with: currentBids)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Заказ взяток"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        let maxLabel = UILabel()
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.text = "Максимум на игрока: \(maxTricks)"
        maxLabel.font = .systemFont(ofSize: 16, weight: .medium)
        maxLabel.textAlignment = .center
        maxLabel.textColor = .darkGray
        containerView.addSubview(maxLabel)
        
        let rowsStack = UIStackView()
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = 12
        rowsStack.distribution = .fillEqually
        containerView.addSubview(rowsStack)
        
        for (index, playerName) in playerNames.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center
            
            let playerLabel = UILabel()
            playerLabel.text = playerName
            playerLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            playerLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            let inputField = trickFields[index]
            inputField.widthAnchor.constraint(equalToConstant: 90).isActive = true
            
            row.addArrangedSubview(playerLabel)
            row.addArrangedSubview(inputField)
            rowsStack.addArrangedSubview(row)
        }
        
        let orderButton = UIButton(type: .system)
        orderButton.translatesAutoresizingMaskIntoConstraints = false
        orderButton.setTitle("Заказать", for: .normal)
        orderButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        orderButton.backgroundColor = UIColor.systemBlue
        orderButton.setTitleColor(.white, for: .normal)
        orderButton.layer.cornerRadius = 12
        orderButton.addTarget(self, action: #selector(handleOrderButton), for: .touchUpInside)
        containerView.addSubview(orderButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            maxLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            maxLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            maxLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            rowsStack.topAnchor.constraint(equalTo: maxLabel.bottomAnchor, constant: 16),
            rowsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            rowsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            orderButton.topAnchor.constraint(equalTo: rowsStack.bottomAnchor, constant: 16),
            orderButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            orderButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            orderButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            orderButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func buildInputFields(with currentBids: [Int]) {
        trickFields = playerNames.enumerated().map { index, _ in
            let inputField = UITextField()
            inputField.borderStyle = .roundedRect
            inputField.keyboardType = .numberPad
            inputField.textAlignment = .center
            inputField.font = .systemFont(ofSize: 18, weight: .medium)
            if index < currentBids.count {
                inputField.text = "\(currentBids[index])"
            } else {
                inputField.text = "0"
            }
            return inputField
        }
    }
    
    @objc private func handleOrderButton() {
        let bids = trickFields.map { field in
            let rawValue = Int(field.text ?? "") ?? 0
            return min(max(rawValue, 0), maxTricks)
        }
        
        onSubmit(bids)
        dismiss(animated: true)
    }
}
