//
//  TrumpSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

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
        view.backgroundColor = PanelAppearance.overlayBackgroundColor

        let containerView = PanelContainerView(surfaceColor: PanelAppearance.overlaySurfaceColor)
        view.addSubview(containerView)

        let headerView = PanelHeaderView(
            title: "Выбор козыря",
            subtitle: "Выбирает: \(playerName)",
            alignment: .center,
            titleFont: PanelTypography.modalTitle,
            subtitleFont: PanelTypography.body,
            subtitleColor: PanelAppearance.goldTextColor
        )
        containerView.addSubview(headerView)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = handCardsDisplayText()
        subtitleLabel.font = PanelTypography.modalSubtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = PanelAppearance.secondaryTextColor
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
                isPrimary: true
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
            isPrimary: false
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

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
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
        isPrimary: Bool,
        onTap: @escaping () -> Void
    ) -> UIButton {
        let button: UIButton = isPrimary
            ? PrimaryPanelButton(title: title, font: PanelTypography.secondaryButton)
            : SecondaryPanelButton(
                title: title,
                style: .neutral,
                font: PanelTypography.secondaryButton
            )
        button.addAction(
            UIAction { _ in
                onTap()
            },
            for: .touchUpInside
        )
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
