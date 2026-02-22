//
//  PreDealBlindSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import UIKit

final class PreDealBlindSelectionViewController: BidSelectionModalBaseViewController {
    private typealias LayoutMetrics = BidSelectionModalBaseViewController.LayoutMetrics
    private typealias Appearance = BidSelectionModalBaseViewController.Appearance

    private let playerName: String
    private let allowedBlindBids: [Int]
    private let canChooseBlind: Bool
    private let onBlindChoice: (_ isBlind: Bool, _ bid: Int?) -> Void

    init(
        playerName: String,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        onBlindChoice: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        self.playerName = playerName
        self.allowedBlindBids = Array(Set(allowedBlindBids)).sorted()
        self.canChooseBlind = canChooseBlind
        self.onBlindChoice = onBlindChoice
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreDealBlindChoiceView()
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
                bids: allowedBlindBids,
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

    @objc private func handleOpenChoiceTapped() {
        onBlindChoice(false, nil)
        dismiss(animated: true)
    }

    @objc private func handleBlindBidTapped(_ sender: UIButton) {
        let selectedBid = sender.tag
        guard allowedBlindBids.contains(selectedBid) else { return }
        onBlindChoice(true, selectedBid)
        dismiss(animated: true)
    }
}
