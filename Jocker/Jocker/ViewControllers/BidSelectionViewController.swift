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
        static let maxButtonsPerRow = 5
        static let buttonHeight: CGFloat = 44
        static let minButtonsAreaHeight: CGFloat = 58
        static let minContainerHeight: CGFloat = 300
    }

    private enum Appearance {
        static let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.62)
        static let surfaceColor = UIColor(red: 0.15, green: 0.21, blue: 0.32, alpha: 0.98)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let subtitleColor = GameColors.textSecondary
        static let accentColor = GameColors.buttonFill
        static let accentBorderColor = GameColors.buttonStroke
        static let accentTextColor = GameColors.buttonText
        static let disabledBidBackground = UIColor(red: 0.19, green: 0.26, blue: 0.39, alpha: 1.0)
        static let disabledBidBorder = GameColors.buttonStroke.withAlphaComponent(0.35)
        static let blindBidBackground = UIColor(red: 0.24, green: 0.36, blue: 0.56, alpha: 1.0)
    }

    private let playerName: String
    private let handCards: [Card]
    private let allowedBids: [Int]
    private let displayedBids: [Int]
    private let forbiddenBid: Int?
    private let isPreDealBlindChoice: Bool
    private let canChooseBlind: Bool
    private let onSelectBid: ((Int) -> Void)?
    private let onSelectBlindChoice: ((Bool, Int?) -> Void)?

    init(
        playerName: String,
        handCards: [Card],
        allowedBids: [Int],
        maxBid: Int,
        forbiddenBid: Int?,
        onSelect: @escaping (Int) -> Void
    ) {
        self.playerName = playerName
        self.handCards = handCards
        self.allowedBids = Array(Set(allowedBids)).sorted()
        let normalizedMaxBid = max(0, maxBid)
        self.displayedBids = Array(0...normalizedMaxBid)
        self.forbiddenBid = forbiddenBid
        self.isPreDealBlindChoice = false
        self.canChooseBlind = false
        self.onSelectBid = onSelect
        self.onSelectBlindChoice = nil
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    init(
        playerName: String,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        onBlindChoice: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        self.playerName = playerName
        self.handCards = []
        self.allowedBids = Array(Set(allowedBlindBids)).sorted()
        self.displayedBids = self.allowedBids
        self.forbiddenBid = nil
        self.isPreDealBlindChoice = true
        self.canChooseBlind = canChooseBlind
        self.onSelectBid = nil
        self.onSelectBlindChoice = onBlindChoice
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if isPreDealBlindChoice {
            setupPreDealBlindChoiceView()
        } else {
            setupPostDealBidView()
        }
    }

    private func setupPostDealBidView() {
        let containerView = makeContainerView()
        let titleLabel = makeLabel(
            text: "Ваш заказ взяток",
            font: UIFont(name: "AvenirNext-Bold", size: 24),
            textColor: Appearance.titleColor
        )
        containerView.addSubview(titleLabel)

        let subtitleLabel = makeLabel(
            text: handCardsDisplayText(),
            font: UIFont(name: "AvenirNext-Medium", size: 14),
            textColor: Appearance.subtitleColor,
            numberOfLines: 3
        )
        containerView.addSubview(subtitleLabel)

        let hintText: String?
        if let forbiddenBid, displayedBids.contains(forbiddenBid) {
            hintText = "Дилеру нельзя выбрать \(forbiddenBid)"
        } else {
            hintText = nil
        }
        let hintLabel = makeLabel(
            text: hintText,
            font: UIFont(name: "AvenirNext-DemiBold", size: 14),
            textColor: GameColors.gold,
            numberOfLines: 2
        )
        hintLabel.isHidden = hintText == nil
        containerView.addSubview(hintLabel)

        let scrollView = makeScrollView(isHidden: false)
        let gridStack = makeGridStack()
        containerView.addSubview(scrollView)
        scrollView.addSubview(gridStack)

        let allowedSet = Set(allowedBids)
        appendBidRows(
            bids: displayedBids,
            enabledBids: allowedSet,
            enabledBackgroundColor: Appearance.accentColor,
            disabledBackgroundColor: Appearance.disabledBidBackground,
            disabledTextColor: Appearance.accentTextColor.withAlphaComponent(0.45),
            enabledBorderColor: Appearance.accentBorderColor,
            disabledBorderColor: Appearance.disabledBidBorder,
            action: #selector(handleBidButtonTapped(_:)),
            fallbackMessage: "Нет доступных ставок",
            fallbackTextColor: Appearance.subtitleColor,
            in: gridStack
        )

        var constraints = containerConstraints(
            for: containerView,
            includeCompactHeight: true
        )
        constraints.append(contentsOf: [
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
        ])
        constraints.append(contentsOf: gridConstraints(for: gridStack, in: scrollView))
        NSLayoutConstraint.activate(constraints)
    }

    private func setupPreDealBlindChoiceView() {
        let containerView = makeContainerView()
        let titleLabel = makeLabel(
            text: "Заказ до раздачи",
            font: UIFont(name: "AvenirNext-Bold", size: 24),
            textColor: Appearance.titleColor
        )
        containerView.addSubview(titleLabel)

        let subtitleLabel = makeLabel(
            text: canChooseBlind
                ? "\(playerName), выберите режим ставки"
                : "\(playerName), можно ставить только после раздачи",
            font: UIFont(name: "AvenirNext-Medium", size: 14),
            textColor: Appearance.subtitleColor,
            numberOfLines: 2
        )
        containerView.addSubview(subtitleLabel)

        let openButton = makePrimaryButton(
            title: "Ставить после раздачи",
            font: UIFont(name: "AvenirNext-DemiBold", size: 18),
            action: #selector(handleOpenChoiceTapped)
        )
        containerView.addSubview(openButton)

        let blindTitle = makeLabel(
            text: "Заказать в темную",
            font: UIFont(name: "AvenirNext-DemiBold", size: 16),
            textColor: GameColors.gold
        )
        blindTitle.isHidden = !canChooseBlind
        containerView.addSubview(blindTitle)

        let scrollView = makeScrollView(isHidden: !canChooseBlind)
        let gridStack = makeGridStack()
        containerView.addSubview(scrollView)
        scrollView.addSubview(gridStack)

        if canChooseBlind {
            appendBidRows(
                bids: allowedBids,
                enabledBids: nil,
                enabledBackgroundColor: Appearance.blindBidBackground,
                disabledBackgroundColor: Appearance.blindBidBackground,
                disabledTextColor: Appearance.accentTextColor,
                enabledBorderColor: Appearance.accentBorderColor,
                disabledBorderColor: Appearance.accentBorderColor,
                action: #selector(handleBlindBidTapped(_:)),
                fallbackMessage: "Нет доступных blind-ставок",
                fallbackTextColor: Appearance.subtitleColor,
                in: gridStack
            )
        }

        var constraints = containerConstraints(
            for: containerView,
            includeCompactHeight: false
        )
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            openButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            openButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            openButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            openButton.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight),

            blindTitle.topAnchor.constraint(equalTo: openButton.bottomAnchor, constant: 14),
            blindTitle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            blindTitle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: blindTitle.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minButtonsAreaHeight),
        ])
        constraints.append(contentsOf: gridConstraints(for: gridStack, in: scrollView))
        NSLayoutConstraint.activate(constraints)
    }

    private func makeContainerView() -> UIView {
        view.backgroundColor = Appearance.overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.surfaceColor
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        return containerView
    }

    private func containerConstraints(for containerView: UIView, includeCompactHeight: Bool) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = [
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.82),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minContainerHeight),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.86),
        ]

        if includeCompactHeight {
            let compact = containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.72)
            compact.priority = .defaultHigh
            constraints.append(compact)
        }

        return constraints
    }

    private func makeLabel(
        text: String?,
        font: UIFont?,
        textColor: UIColor,
        numberOfLines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = font
        label.textAlignment = .center
        label.textColor = textColor
        label.numberOfLines = numberOfLines
        return label
    }

    private func makePrimaryButton(title: String, font: UIFont?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(Appearance.accentTextColor, for: .normal)
        button.backgroundColor = Appearance.accentColor
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = Appearance.accentBorderColor.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeScrollView(isHidden: Bool) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isHidden = isHidden
        return scrollView
    }

    private func makeGridStack() -> UIStackView {
        let gridStack = UIStackView()
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 10
        gridStack.distribution = .fill
        return gridStack
    }

    private func gridConstraints(for gridStack: UIStackView, in scrollView: UIScrollView) -> [NSLayoutConstraint] {
        return [
            gridStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            gridStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ]
    }

    private func appendBidRows(
        bids: [Int],
        enabledBids: Set<Int>?,
        enabledBackgroundColor: UIColor,
        disabledBackgroundColor: UIColor,
        disabledTextColor: UIColor,
        enabledBorderColor: UIColor,
        disabledBorderColor: UIColor,
        action: Selector,
        fallbackMessage: String,
        fallbackTextColor: UIColor,
        in gridStack: UIStackView
    ) {
        for rowBids in bids.chunked(into: LayoutMetrics.maxButtonsPerRow) {
            let rowStack = UIStackView()
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true

            for bid in rowBids {
                let isEnabled = enabledBids?.contains(bid) ?? true
                let button = makeBidButton(
                    bid: bid,
                    isEnabled: isEnabled,
                    enabledBackgroundColor: enabledBackgroundColor,
                    disabledBackgroundColor: disabledBackgroundColor,
                    disabledTextColor: disabledTextColor,
                    enabledBorderColor: enabledBorderColor,
                    disabledBorderColor: disabledBorderColor,
                    action: action
                )
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

        if bids.isEmpty {
            let fallbackLabel = makeLabel(
                text: fallbackMessage,
                font: UIFont(name: "AvenirNext-DemiBold", size: 16),
                textColor: fallbackTextColor
            )
            fallbackLabel.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true
            gridStack.addArrangedSubview(fallbackLabel)
        }
    }

    private func makeBidButton(
        bid: Int,
        isEnabled: Bool,
        enabledBackgroundColor: UIColor,
        disabledBackgroundColor: UIColor,
        disabledTextColor: UIColor,
        enabledBorderColor: UIColor,
        disabledBorderColor: UIColor,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(bid)", for: .normal)
        button.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        button.isEnabled = isEnabled
        button.setTitleColor(
            isEnabled ? Appearance.accentTextColor : disabledTextColor,
            for: .normal
        )
        button.backgroundColor = isEnabled ? enabledBackgroundColor : disabledBackgroundColor
        button.layer.borderColor = (isEnabled ? enabledBorderColor : disabledBorderColor).cgColor
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.heightAnchor.constraint(equalToConstant: LayoutMetrics.buttonHeight).isActive = true
        button.tag = bid
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func handleBidButtonTapped(_ sender: UIButton) {
        let selectedBid = sender.tag
        guard allowedBids.contains(selectedBid) else { return }
        onSelectBid?(selectedBid)
        dismiss(animated: true)
    }

    @objc private func handleOpenChoiceTapped() {
        onSelectBlindChoice?(false, nil)
        dismiss(animated: true)
    }

    @objc private func handleBlindBidTapped(_ sender: UIButton) {
        let selectedBid = sender.tag
        guard allowedBids.contains(selectedBid) else { return }
        onSelectBlindChoice?(true, selectedBid)
        dismiss(animated: true)
    }

    private func handCardsDisplayText() -> String {
        guard !handCards.isEmpty else {
            return "\(playerName), карт на руках нет"
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
