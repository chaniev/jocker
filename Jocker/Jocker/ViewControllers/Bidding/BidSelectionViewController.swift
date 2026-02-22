//
//  BidSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class BidSelectionViewController: BidSelectionModalBaseViewController {
    private typealias LayoutMetrics = BidSelectionModalBaseViewController.LayoutMetrics
    private typealias Appearance = BidSelectionModalBaseViewController.Appearance

    private let playerName: String
    private let handCards: [Card]
    private let allowedBids: [Int]
    private let displayedBids: [Int]
    private let playerNames: [String]
    private let displayedBidsByPlayer: [Int?]
    private let biddingOrder: [Int]
    private let currentPlayerIndex: Int?
    private let forbiddenBid: Int?
    private let trumpSuit: Suit?
    private let onSelectBid: (Int) -> Void

    init(
        playerName: String,
        handCards: [Card],
        allowedBids: [Int],
        maxBid: Int,
        playerNames: [String],
        displayedBidsByPlayer: [Int?],
        biddingOrder: [Int],
        currentPlayerIndex: Int?,
        forbiddenBid: Int?,
        trumpSuit: Suit?,
        onSelect: @escaping (Int) -> Void
    ) {
        self.playerName = playerName
        self.handCards = handCards
        self.allowedBids = Array(Set(allowedBids)).sorted()
        let normalizedMaxBid = max(0, maxBid)
        self.displayedBids = Array(0...normalizedMaxBid)
        self.playerNames = playerNames
        self.displayedBidsByPlayer = displayedBidsByPlayer
        self.biddingOrder = biddingOrder
        self.currentPlayerIndex = currentPlayerIndex
        self.forbiddenBid = forbiddenBid
        self.trumpSuit = trumpSuit
        self.onSelectBid = onSelect
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPostDealBidView()
    }

    private func setupPostDealBidView() {
        let containerView = makeContainerView()
        let turnLabel = makeLabel(
            text: "Ваше слово",
            font: UIFont(name: "AvenirNext-Bold", size: 24),
            textColor: Appearance.titleColor
        )
        turnLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        turnLabel.setContentHuggingPriority(.required, for: .vertical)
        containerView.addSubview(turnLabel)

        let subtitleLabel = makeLabel(
            text: handCardsDisplayText(),
            font: UIFont(name: "AvenirNext-Medium", size: 14),
            textColor: Appearance.subtitleColor,
            numberOfLines: 2
        )
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        containerView.addSubview(subtitleLabel)

        let trumpLabel = makeLabel(
            text: trumpDisplayText(),
            font: UIFont(name: "AvenirNext-DemiBold", size: 14),
            textColor: GameColors.gold
        )
        trumpLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        trumpLabel.setContentHuggingPriority(.required, for: .vertical)
        containerView.addSubview(trumpLabel)

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
        let bidSelectionColumn = UIView()
        bidSelectionColumn.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bidSelectionColumn)
        bidSelectionColumn.addSubview(scrollView)
        scrollView.addSubview(gridStack)

        let bidSummaryPanel = makeBidSummaryPanel()
        if let bidSummaryPanel {
            containerView.addSubview(bidSummaryPanel)
        }

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
            turnLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            turnLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            turnLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            turnLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),

            subtitleLabel.topAnchor.constraint(equalTo: turnLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            subtitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            trumpLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            trumpLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            trumpLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            trumpLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),

            hintLabel.topAnchor.constraint(equalTo: trumpLabel.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])

        let contentTop = bidSelectionColumn.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 14)
        let contentBottom = bidSelectionColumn.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18)
        let contentTrailing = bidSelectionColumn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        constraints.append(contentsOf: [contentTop, contentBottom, contentTrailing])

        if let bidSummaryPanel {
            constraints.append(contentsOf: [
                bidSummaryPanel.topAnchor.constraint(equalTo: bidSelectionColumn.topAnchor),
                bidSummaryPanel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                bidSummaryPanel.bottomAnchor.constraint(equalTo: bidSelectionColumn.bottomAnchor),
                bidSummaryPanel.widthAnchor.constraint(equalToConstant: LayoutMetrics.bidSummaryPanelWidth),
                bidSelectionColumn.leadingAnchor.constraint(equalTo: bidSummaryPanel.trailingAnchor, constant: 14)
            ])
        } else {
            constraints.append(
                bidSelectionColumn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
            )
        }

        constraints.append(contentsOf: [
            scrollView.topAnchor.constraint(equalTo: bidSelectionColumn.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: bidSelectionColumn.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: bidSelectionColumn.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bidSelectionColumn.bottomAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutMetrics.minButtonsAreaHeight),
        ])
        constraints.append(contentsOf: gridConstraints(for: gridStack, in: scrollView))
        NSLayoutConstraint.activate(constraints)
    }

    private func makeBidSummaryPanel() -> UIView? {
        let summaryRows = bidSummaryRows()
        guard !summaryRows.isEmpty else { return nil }

        let panel = UIView()
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = Appearance.bidSummaryPanelBackground
        panel.layer.cornerRadius = 12
        panel.layer.borderWidth = 1
        panel.layer.borderColor = Appearance.bidSummaryPanelBorder.cgColor

        let titleLabel = makeLabel(
            text: "Заказы игроков",
            font: UIFont(name: "AvenirNext-DemiBold", size: 14),
            textColor: Appearance.titleColor
        )
        panel.addSubview(titleLabel)

        let rowsStack = UIStackView()
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = 6
        panel.addSubview(rowsStack)

        for row in summaryRows {
            let rowView = makeBidSummaryRow(
                playerName: row.name,
                bid: row.bid,
                isCurrentPlayer: row.isCurrentPlayer
            )
            rowsStack.addArrangedSubview(rowView)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -12),

            rowsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            rowsStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 10),
            rowsStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -10),
            rowsStack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor, constant: -10),
        ])

        return panel
    }

    private func makeBidSummaryRow(playerName: String, bid: Int?, isCurrentPlayer: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: LayoutMetrics.bidSummaryRowHeight).isActive = true

        let playerLabel = makeLabel(
            text: isCurrentPlayer ? "\(playerName) (вы)" : playerName,
            font: UIFont(name: isCurrentPlayer ? "AvenirNext-DemiBold" : "AvenirNext-Medium", size: 13),
            textColor: isCurrentPlayer ? GameColors.gold : Appearance.subtitleColor
        )
        playerLabel.textAlignment = .left

        let valueLabel = makeLabel(
            text: bid.map(String.init) ?? "—",
            font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
            textColor: bid == nil ? Appearance.bidSummaryPendingColor : Appearance.bidSummaryValueColor
        )
        valueLabel.textAlignment = .right

        row.addSubview(playerLabel)
        row.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            playerLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            playerLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        return row
    }

    private func bidSummaryRows() -> [(name: String, bid: Int?, isCurrentPlayer: Bool)] {
        guard !playerNames.isEmpty else { return [] }

        let order = normalizedBiddingOrder()
        return order.map { playerIndex in
            let playerName = playerNames[playerIndex]
            let bid = displayedBidsByPlayer.indices.contains(playerIndex)
                ? displayedBidsByPlayer[playerIndex]
                : nil
            let isCurrent = playerIndex == currentPlayerIndex
            return (playerName, bid, isCurrent)
        }
    }

    private func normalizedBiddingOrder() -> [Int] {
        guard !playerNames.isEmpty else { return [] }
        let fallbackOrder = Array(playerNames.indices)

        var seen = Set<Int>()
        let uniqueOrder = biddingOrder.filter { seen.insert($0).inserted }
        guard uniqueOrder.count == playerNames.count else { return fallbackOrder }
        guard uniqueOrder.allSatisfy({ playerNames.indices.contains($0) }) else { return fallbackOrder }

        return uniqueOrder
    }

    @objc private func handleBidButtonTapped(_ sender: UIButton) {
        let selectedBid = sender.tag
        guard allowedBids.contains(selectedBid) else { return }
        onSelectBid(selectedBid)
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

        let cardRows = cardTitles.chunked(into: LayoutMetrics.maxButtonsPerRow)
        return cardRows.map { $0.joined(separator: " ") }.joined(separator: "\n")
    }

    func trumpDisplayText() -> String {
        guard let trumpSuit else { return "Козырь: без козыря" }
        return "Козырь: \(trumpSuit.rawValue) \(trumpSuit.name)"
    }
}
