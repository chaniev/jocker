//
//  GameResultsViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class GameResultsViewController: UIViewController {
    private enum Appearance {
        static let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.72)
        static let containerColor = UIColor(red: 0.12, green: 0.17, blue: 0.27, alpha: 0.97)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let secondaryTextColor = GameColors.textSecondary
        static let cardColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.95)
        static let cardBorderColor = UIColor(red: 0.28, green: 0.37, blue: 0.54, alpha: 0.82)
        static let accentColor = GameColors.gold
        static let buttonColor = GameColors.buttonFill
        static let buttonTextColor = GameColors.buttonText
    }

    private enum Layout {
        static let cardSpacing: CGFloat = 10
        static let containerCornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let closeButtonHeight: CGFloat = 50
    }

    private let playerSummaries: [GameFinalPlayerSummary]

    init(playerSummaries: [GameFinalPlayerSummary]) {
        self.playerSummaries = playerSummaries
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
        view.backgroundColor = Appearance.overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.containerColor
        containerView.layer.cornerRadius = Layout.containerCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        let titleLabel = makeLabel(
            text: "Итоги игры",
            font: UIFont(name: "AvenirNext-Bold", size: 28),
            color: Appearance.titleColor
        )
        containerView.addSubview(titleLabel)

        let subtitleLabel = makeLabel(
            text: "Места, очки, премии и темные заказы",
            font: UIFont(name: "AvenirNext-Medium", size: 15),
            color: Appearance.secondaryTextColor
        )
        subtitleLabel.numberOfLines = 2
        containerView.addSubview(subtitleLabel)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        containerView.addSubview(scrollView)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Layout.cardSpacing
        stackView.alignment = .fill
        scrollView.addSubview(stackView)

        for summary in playerSummaries {
            stackView.addArrangedSubview(makePlayerCard(for: summary))
        }

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        closeButton.setTitleColor(Appearance.buttonTextColor, for: .normal)
        closeButton.backgroundColor = Appearance.buttonColor
        closeButton.layer.cornerRadius = 12
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = GameColors.buttonStroke.cgColor
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.90),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 480),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.90),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            closeButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 14),
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.closeButtonHeight),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func makePlayerCard(for summary: GameFinalPlayerSummary) -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = Appearance.cardColor
        cardView.layer.cornerRadius = Layout.cardCornerRadius
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Appearance.cardBorderColor.cgColor

        let rankLabel = makeLabel(
            text: "\(summary.place) место - \(summary.playerName)",
            font: UIFont(name: "AvenirNext-Bold", size: 22),
            color: Appearance.accentColor
        )
        rankLabel.textAlignment = .left
        cardView.addSubview(rankLabel)

        let totalLabel = makeLabel(
            text: "Итого очков: \(summary.totalScore)",
            font: UIFont(name: "AvenirNext-DemiBold", size: 17),
            color: Appearance.titleColor
        )
        totalLabel.textAlignment = .left
        cardView.addSubview(totalLabel)

        let blockDetailsText = summary.blockScores.enumerated().map { index, score in
            let premiumTaken = summary.premiumTakenByBlock.indices.contains(index)
                ? summary.premiumTakenByBlock[index]
                : false
            let premiumLabel = premiumTaken ? "Да" : "Нет"
            return "Блок \(index + 1): \(score) очк. | Премия: \(premiumLabel)"
        }.joined(separator: "\n")

        let blockDetailsLabel = makeLabel(
            text: blockDetailsText,
            font: UIFont(name: "AvenirNext-Medium", size: 15),
            color: Appearance.secondaryTextColor
        )
        blockDetailsLabel.numberOfLines = 0
        blockDetailsLabel.textAlignment = .left
        cardView.addSubview(blockDetailsLabel)

        let premiumCountLabel = makeLabel(
            text: "Премий всего: \(summary.totalPremiumsTaken)",
            font: UIFont(name: "AvenirNext-DemiBold", size: 15),
            color: Appearance.titleColor
        )
        premiumCountLabel.textAlignment = .left
        cardView.addSubview(premiumCountLabel)

        let blindCountLabel = makeLabel(
            text: "Темнил в 4 блоке: \(summary.fourthBlockBlindCount)",
            font: UIFont(name: "AvenirNext-DemiBold", size: 15),
            color: Appearance.titleColor
        )
        blindCountLabel.textAlignment = .left
        cardView.addSubview(blindCountLabel)

        NSLayoutConstraint.activate([
            rankLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            rankLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            rankLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            totalLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 6),
            totalLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            totalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            blockDetailsLabel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8),
            blockDetailsLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            blockDetailsLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            premiumCountLabel.topAnchor.constraint(equalTo: blockDetailsLabel.bottomAnchor, constant: 8),
            premiumCountLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            premiumCountLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            blindCountLabel.topAnchor.constraint(equalTo: premiumCountLabel.bottomAnchor, constant: 4),
            blindCountLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            blindCountLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            blindCountLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])

        return cardView
    }

    private func makeLabel(
        text: String,
        font: UIFont?,
        color: UIColor
    ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        return label
    }

    @objc
    private func handleCloseTapped() {
        dismiss(animated: true)
    }
}
