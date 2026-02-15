//
//  BidSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit
import SpriteKit

final class BidSelectionViewController: UIViewController {
    private enum LayoutMetrics {
        static let maxButtonsPerRow = 3
        static let buttonHeight: CGFloat = 49
        static let minButtonsAreaHeight: CGFloat = 58
        static let minContainerHeight: CGFloat = 300
    }

    private let playerName: String
    private let handCards: [Card]
    private let allowedBids: [Int]
    private let onSelect: (Int) -> Void

    init(
        playerName: String,
        handCards: [Card],
        allowedBids: [Int],
        onSelect: @escaping (Int) -> Void
    ) {
        self.playerName = playerName
        self.handCards = handCards
        self.allowedBids = Array(Set(allowedBids)).sorted()
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
        titleLabel.text = "Ваш заказ взяток"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = titleColor
        containerView.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = handCardsDisplayText()
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.numberOfLines = 3
        containerView.addSubview(subtitleLabel)

        let hintLabel = UILabel()
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 14)
        hintLabel.textAlignment = .center
        hintLabel.textColor = GameColors.gold
        hintLabel.numberOfLines = 2
        hintLabel.text = nil
        hintLabel.isHidden = true
        containerView.addSubview(hintLabel)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        containerView.addSubview(scrollView)

        let gridStack = UIStackView()
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 10
        gridStack.distribution = .fill
        scrollView.addSubview(gridStack)

        let availableBids = allowedBids
        for rowBids in availableBids.chunked(into: LayoutMetrics.maxButtonsPerRow) {
            let rowStack = UIStackView()
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true

            for bid in rowBids {
                let button = UIButton(type: .system)
                button.setTitle("\(bid)", for: .normal)
                button.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
                button.setTitleColor(accentTextColor, for: .normal)
                button.backgroundColor = accentColor
                button.layer.cornerRadius = 12
                button.layer.borderWidth = 1
                button.layer.borderColor = accentBorderColor.cgColor
                button.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true
                button.tag = bid
                button.addTarget(self, action: #selector(handleBidButtonTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
            }

            let placeholdersCount = max(0, LayoutMetrics.maxButtonsPerRow - rowBids.count)
            if placeholdersCount > 0 {
                for _ in 0..<placeholdersCount {
                    let placeholder = UIView()
                    placeholder.backgroundColor = .clear
                    rowStack.addArrangedSubview(placeholder)
                }
            }

            gridStack.addArrangedSubview(rowStack)
        }

        if availableBids.isEmpty {
            let fallbackLabel = UILabel()
            fallbackLabel.text = "Нет доступных ставок"
            fallbackLabel.textAlignment = .center
            fallbackLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 16)
            fallbackLabel.textColor = subtitleColor
            fallbackLabel.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true
            gridStack.addArrangedSubview(fallbackLabel)
        }

        let compactHeightConstraint = containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.72)
        compactHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.82),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minContainerHeight),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.86),
            compactHeightConstraint,

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            hintLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            hintLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minButtonsAreaHeight),

            gridStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            gridStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    @objc private func handleBidButtonTapped(_ sender: UIButton) {
        let selectedBid = sender.tag
        guard allowedBids.contains(selectedBid) else { return }
        onSelect(selectedBid)
        dismiss(animated: true)
    }

    private func handCardsDisplayText() -> String {
        guard !handCards.isEmpty else {
            return "Карт на руках нет"
        }

        let cardTitles = handCards.map { card in
            switch card {
            case .joker:
                return "🃏"
            case .regular(let suit, let rank):
                return "\(rank.symbol)\(suit.rawValue)"
            }
        }

        guard cardTitles.count > 6 else {
            return cardTitles.joined(separator: " ")
        }

        let firstRowCount = Int(ceil(Double(cardTitles.count) / 2.0))
        let firstRow = cardTitles.prefix(firstRowCount).joined(separator: " ")
        let secondRow = cardTitles.dropFirst(firstRowCount).joined(separator: " ")
        return "\(firstRow)\n\(secondRow)"
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        chunks.reserveCapacity((count + size - 1) / size)

        var index = 0
        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index = end
        }

        return chunks
    }
}
