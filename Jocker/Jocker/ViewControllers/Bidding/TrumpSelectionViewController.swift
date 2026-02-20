//
//  TrumpSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit
import SpriteKit

final class TrumpSelectionViewController: UIViewController {
    private enum LayoutMetrics {
        static let buttonHeight: CGFloat = 50
        static let minContainerHeight: CGFloat = 320
    }

    private let playerName: String
    private let handCards: [Card]
    private let onSelect: (Suit?) -> Void

    init(
        playerName: String,
        handCards: [Card],
        onSelect: @escaping (Suit?) -> Void
    ) {
        self.playerName = playerName
        self.handCards = handCards
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.62)
        let surfaceColor = UIColor(red: 0.15, green: 0.21, blue: 0.32, alpha: 0.98)
        let borderColor = GameColors.goldTranslucent
        let titleColor = GameColors.textPrimary
        let subtitleColor = GameColors.textSecondary
        let accentColor = GameColors.buttonFill
        let accentBorderColor = GameColors.buttonStroke
        let accentTextColor = GameColors.buttonText

        view.backgroundColor = overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = surfaceColor
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = borderColor.cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Выбор козыря"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = titleColor
        containerView.addSubview(titleLabel)

        let chooserLabel = UILabel()
        chooserLabel.translatesAutoresizingMaskIntoConstraints = false
        chooserLabel.text = "Выбирает: \(playerName)"
        chooserLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 15)
        chooserLabel.textAlignment = .center
        chooserLabel.textColor = GameColors.gold
        containerView.addSubview(chooserLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = handCardsDisplayText()
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.numberOfLines = 3
        containerView.addSubview(subtitleLabel)

        let suitGrid = UIStackView()
        suitGrid.translatesAutoresizingMaskIntoConstraints = false
        suitGrid.axis = .vertical
        suitGrid.spacing = 10
        suitGrid.distribution = .fillEqually
        containerView.addSubview(suitGrid)

        let firstRow = UIStackView()
        firstRow.translatesAutoresizingMaskIntoConstraints = false
        firstRow.axis = .horizontal
        firstRow.spacing = 10
        firstRow.distribution = .fillEqually
        suitGrid.addArrangedSubview(firstRow)

        let secondRow = UIStackView()
        secondRow.translatesAutoresizingMaskIntoConstraints = false
        secondRow.axis = .horizontal
        secondRow.spacing = 10
        secondRow.distribution = .fillEqually
        suitGrid.addArrangedSubview(secondRow)

        let suitButtons = Suit.allCases.map { suit in
            makeSuitButton(
                title: "\(suit.rawValue) \(suit.name)",
                backgroundColor: accentColor,
                borderColor: accentBorderColor,
                textColor: accentTextColor
            ) { [weak self] in
                self?.onSelect(suit)
                self?.dismiss(animated: true)
            }
        }

        for (index, button) in suitButtons.enumerated() {
            if index < 2 {
                firstRow.addArrangedSubview(button)
            } else {
                secondRow.addArrangedSubview(button)
            }
        }

        let noTrumpButton = makeSuitButton(
            title: "Без козыря",
            backgroundColor: UIColor(red: 0.31, green: 0.36, blue: 0.45, alpha: 1.0),
            borderColor: UIColor(red: 0.22, green: 0.27, blue: 0.35, alpha: 1.0),
            textColor: titleColor
        ) { [weak self] in
            self?.onSelect(nil)
            self?.dismiss(animated: true)
        }
        containerView.addSubview(noTrumpButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.82),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 360),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minContainerHeight),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.86),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            chooserLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            chooserLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            chooserLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: chooserLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            suitGrid.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            suitGrid.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            suitGrid.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            suitGrid.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight * 2 + 10),

            noTrumpButton.topAnchor.constraint(equalTo: suitGrid.bottomAnchor, constant: 12),
            noTrumpButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            noTrumpButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            noTrumpButton.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight),
            noTrumpButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    private func makeSuitButton(
        title: String,
        backgroundColor: UIColor,
        borderColor: UIColor,
        textColor: UIColor,
        onTap: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        button.setTitleColor(textColor, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = borderColor.cgColor
        button.addAction(
            UIAction { _ in
                onTap()
            },
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true
        return button
    }

    private func handCardsDisplayText() -> String {
        guard !handCards.isEmpty else {
            return "Карт для выбора козыря нет"
        }

        let cardTitles = handCards.map { card in
            switch card {
            case .joker:
                return "🃏"
            case .regular(let suit, let rank):
                return "\(rank.symbol)\(suit.rawValue)"
            }
        }

        return cardTitles.joined(separator: " ")
    }
}
