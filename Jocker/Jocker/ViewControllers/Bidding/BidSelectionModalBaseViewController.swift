//
//  BidSelectionModalBaseViewController.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import UIKit

class BidSelectionModalBaseViewController: UIViewController {
    enum LayoutMetrics {
        static let maxButtonsPerRow = 5
        static let buttonHeight: CGFloat = 44
        static let minButtonsAreaHeight: CGFloat = 58
        static let minContainerHeight: CGFloat = 300
        static let bidSummaryPanelWidth: CGFloat = 200
        static let bidSummaryRowHeight: CGFloat = 26
    }

    enum Appearance {
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
        static let bidSummaryPanelBackground = UIColor(red: 0.11, green: 0.17, blue: 0.27, alpha: 0.78)
        static let bidSummaryPanelBorder = GameColors.buttonStroke.withAlphaComponent(0.6)
        static let bidSummaryValueColor = UIColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 0.95)
        static let bidSummaryPendingColor = GameColors.textSecondary
    }

    func makeContainerView() -> UIView {
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

    func containerConstraints(for containerView: UIView, includeCompactHeight: Bool) -> [NSLayoutConstraint] {
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

    func makeLabel(
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

    func makePrimaryButton(title: String, font: UIFont?, action: Selector) -> UIButton {
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

    func makeScrollView(isHidden: Bool) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isHidden = isHidden
        return scrollView
    }

    func makeGridStack() -> UIStackView {
        let gridStack = UIStackView()
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 10
        gridStack.distribution = .fill
        return gridStack
    }

    func gridConstraints(for gridStack: UIStackView, in scrollView: UIScrollView) -> [NSLayoutConstraint] {
        return [
            gridStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            gridStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ]
    }

    func appendBidRows(
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

    func makeBidButton(
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
}

extension Array {
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
