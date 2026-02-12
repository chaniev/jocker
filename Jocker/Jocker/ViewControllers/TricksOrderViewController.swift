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
    private let dealerIndex: Int
    private let onSubmit: ([Int]) -> Void
    
    private var bids: [Int] = []
    private var biddingOrder: [Int] = []
    
    private weak var containerView: UIView?
    private weak var confirmButton: UIButton?
    private weak var summaryLabel: UILabel?
    private weak var errorLabel: UILabel?
    
    private var valueLabelsByPlayerIndex: [Int: UILabel] = [:]
    private var nameLabelsByPlayerIndex: [Int: UILabel] = [:]
    
    init(
        playerNames: [String],
        maxTricks: Int,
        currentBids: [Int],
        dealerIndex: Int,
        onSubmit: @escaping ([Int]) -> Void
    ) {
        self.playerNames = playerNames
        self.maxTricks = max(0, maxTricks)
        self.dealerIndex = min(max(dealerIndex, 0), max(0, playerNames.count - 1))
        self.onSubmit = onSubmit
        
        super.init(nibName: nil, bundle: nil)

        self.bids = playerNames.enumerated().map { index, _ in
            let raw = (index < currentBids.count) ? currentBids[index] : 0
            return min(max(raw, 0), self.maxTricks)
        }
        self.biddingOrder = Self.makeBiddingOrder(playerCount: playerNames.count, dealerIndex: self.dealerIndex)
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

        let playerCount = max(1, playerNames.count)
        let isCompactLayout = playerCount >= 4
        let isUltraCompactLayout = isCompactLayout && view.bounds.height < 420
        let containerWidthMultiplier: CGFloat = isUltraCompactLayout ? 0.92 : (isCompactLayout ? 0.86 : 0.82)
        let containerHeightMultiplier: CGFloat = isUltraCompactLayout ? 0.90 : (isCompactLayout ? 0.84 : 0.75)
        let topPadding: CGFloat = isUltraCompactLayout ? 12 : (isCompactLayout ? 16 : 20)
        let sectionSpacing: CGFloat = isUltraCompactLayout ? 8 : (isCompactLayout ? 10 : 12)
        let scrollTopSpacing: CGFloat = isUltraCompactLayout ? 10 : (isCompactLayout ? 12 : 16)
        let scrollToErrorSpacing: CGFloat = isUltraCompactLayout ? 6 : 12
        let errorToButtonsSpacing: CGFloat = isUltraCompactLayout ? 8 : (isCompactLayout ? 10 : 12)
        let bottomPadding: CGFloat = isUltraCompactLayout ? 12 : 16
        let buttonsHeight: CGFloat = isUltraCompactLayout ? 44 : 50
        let rowHeight: CGFloat = isUltraCompactLayout ? 40 : (isCompactLayout ? 46 : 52)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        self.containerView = containerView

        let preferredHeight = containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: containerHeightMultiplier)
        preferredHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: containerWidthMultiplier),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: isUltraCompactLayout ? 0.92 : 0.88),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 340),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),
            preferredHeight
        ])
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Заказ взяток"
        titleLabel.font = .systemFont(ofSize: isUltraCompactLayout ? 20 : (isCompactLayout ? 22 : 24), weight: .bold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitleText()
        subtitleLabel.font = .systemFont(ofSize: isUltraCompactLayout ? 12 : (isCompactLayout ? 13 : 14), weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = isUltraCompactLayout ? 1 : (isCompactLayout ? 2 : 1)
        containerView.addSubview(subtitleLabel)
        
        let summaryLabel = UILabel()
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = .systemFont(ofSize: isUltraCompactLayout ? 14 : (isCompactLayout ? 15 : 16), weight: .semibold)
        summaryLabel.textAlignment = .center
        summaryLabel.textColor = .black
        summaryLabel.numberOfLines = isUltraCompactLayout ? 2 : 1
        containerView.addSubview(summaryLabel)
        self.summaryLabel = summaryLabel
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = playerCount >= 4
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isScrollEnabled = playerCount >= 4
        containerView.addSubview(scrollView)
        
        let rowsStack = UIStackView()
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = isUltraCompactLayout ? 6 : (isCompactLayout ? 8 : 10)
        rowsStack.distribution = .fill
        scrollView.addSubview(rowsStack)
        
        for (orderPosition, playerIndex) in biddingOrder.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center
            let rowHeightConstraint = row.heightAnchor.constraint(equalToConstant: rowHeight)
            rowHeightConstraint.priority = .required
            rowHeightConstraint.isActive = true
            
            let playerLabel = UILabel()
            playerLabel.numberOfLines = 1
            playerLabel.font = .systemFont(ofSize: isUltraCompactLayout ? 15 : (isCompactLayout ? 16 : 17), weight: .semibold)
            playerLabel.text = rowTitleText(orderPosition: orderPosition, playerIndex: playerIndex, bid: bids[playerIndex])
            playerLabel.textColor = (playerIndex == dealerIndex) ? .systemOrange : .black
            playerLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            nameLabelsByPlayerIndex[playerIndex] = playerLabel
            
            let valueLabel = UILabel()
            valueLabel.font = .monospacedDigitSystemFont(ofSize: isUltraCompactLayout ? 17 : (isCompactLayout ? 18 : 19), weight: .bold)
            valueLabel.textAlignment = .right
            valueLabel.text = "\(bids[playerIndex])"
            valueLabel.setContentHuggingPriority(.required, for: .horizontal)
            valueLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true
            valueLabelsByPlayerIndex[playerIndex] = valueLabel
            
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = Double(maxTricks)
            stepper.stepValue = 1
            stepper.value = Double(bids[playerIndex])
            stepper.tag = playerIndex
            stepper.addTarget(self, action: #selector(handleStepperChanged(_:)), for: .valueChanged)
            
            row.addArrangedSubview(playerLabel)
            row.addArrangedSubview(UIView())
            row.addArrangedSubview(valueLabel)
            row.addArrangedSubview(stepper)
            rowsStack.addArrangedSubview(row)
        }
        
        let errorLabel = UILabel()
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        errorLabel.textAlignment = .center
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        containerView.addSubview(errorLabel)
        self.errorLabel = errorLabel
        
        let buttonsRow = UIStackView()
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually
        containerView.addSubview(buttonsRow)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отмена", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        cancelButton.backgroundColor = UIColor.systemGray5
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(handleCancelButton), for: .touchUpInside)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Подтвердить", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        confirmButton.backgroundColor = UIColor.systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(handleConfirmButton), for: .touchUpInside)
        self.confirmButton = confirmButton
        
        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: isCompactLayout ? 6 : 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            summaryLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: sectionSpacing),
            summaryLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: scrollTopSpacing),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: errorLabel.topAnchor, constant: -scrollToErrorSpacing),
            
            rowsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            rowsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            errorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            buttonsRow.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: errorToButtonsSpacing),
            buttonsRow.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonsRow.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonsRow.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottomPadding),
            buttonsRow.heightAnchor.constraint(equalToConstant: buttonsHeight),
        ])

        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        backgroundTap.cancelsTouchesInView = false
        view.addGestureRecognizer(backgroundTap)

        updateSummaryAndValidation()
    }
    
    private func subtitleText() -> String {
        guard playerNames.indices.contains(dealerIndex) else {
            return "Взяток: \(maxTricks)"
        }
        let firstBidderIndex = (dealerIndex + 1) % max(1, playerNames.count)
        let dealerName = playerNames[dealerIndex]
        let firstBidderName = playerNames[firstBidderIndex]
        return "Взяток: \(maxTricks) • D: \(dealerName) • 1-й: \(firstBidderName)"
    }
    
    private func rowTitleText(orderPosition: Int, playerIndex: Int, bid: Int) -> String {
        let orderNumber = orderPosition + 1
        let name = playerNames.indices.contains(playerIndex) ? playerNames[playerIndex] : "Игрок \(playerIndex + 1)"
        let nameWithBid = "\(name) (\(bid))"
        if playerIndex == dealerIndex {
            return "\(orderNumber). \(nameWithBid) (раздающий)"
        }
        return "\(orderNumber). \(nameWithBid)"
    }

    private func updatePlayerNameLabel(for playerIndex: Int) {
        guard let orderPosition = biddingOrder.firstIndex(of: playerIndex) else { return }
        guard bids.indices.contains(playerIndex) else { return }
        nameLabelsByPlayerIndex[playerIndex]?.text = rowTitleText(
            orderPosition: orderPosition,
            playerIndex: playerIndex,
            bid: bids[playerIndex]
        )
    }

    @objc private func handleStepperChanged(_ stepper: UIStepper) {
        let playerIndex = stepper.tag
        guard bids.indices.contains(playerIndex) else { return }

        let newBid = min(max(Int(stepper.value.rounded()), 0), maxTricks)
        bids[playerIndex] = newBid
        valueLabelsByPlayerIndex[playerIndex]?.text = "\(newBid)"
        updatePlayerNameLabel(for: playerIndex)
        updateSummaryAndValidation()
    }

    @objc private func handleCancelButton() {
        dismiss(animated: true)
    }

    @objc private func handleConfirmButton() {
        guard isValidCurrentState().isValid else { return }
        onSubmit(bids)
        dismiss(animated: true)
    }

    @objc private func handleBackgroundTap(_ recognizer: UITapGestureRecognizer) {
        guard let containerView else { return }
        let point = recognizer.location(in: view)
        if !containerView.frame.contains(point) {
            dismiss(animated: true)
        }
    }

    private func updateSummaryAndValidation() {
        let total = bids.reduce(0, +)
        if let forbidden = forbiddenDealerBid() {
            summaryLabel?.text = "Сумма: \(total) • Нельзя: \(forbidden)"
        } else {
            summaryLabel?.text = "Сумма: \(total)"
        }
        
        let validation = isValidCurrentState()
        errorLabel?.text = validation.message
        confirmButton?.isEnabled = validation.isValid
        confirmButton?.alpha = validation.isValid ? 1.0 : 0.5
    }

    private func isValidCurrentState() -> (isValid: Bool, message: String?) {
        guard !bids.isEmpty else { return (false, "Нет игроков") }
        let dealerBid = bids.indices.contains(dealerIndex) ? bids[dealerIndex] : 0
        
        if let forbiddenForDealer = forbiddenDealerBid(), dealerBid == forbiddenForDealer {
            return (false, "Раздающему нельзя: \(forbiddenForDealer) (сумма станет \(maxTricks)).")
        }
        
        return (true, nil)
    }

    private func forbiddenDealerBid() -> Int? {
        guard playerNames.count > 1 else { return nil }
        let totalWithoutDealer = bids.enumerated().reduce(0) { partial, element in
            let (index, bid) = element
            return partial + ((index == dealerIndex) ? 0 : bid)
        }
        let forbidden = maxTricks - totalWithoutDealer
        guard forbidden >= 0 && forbidden <= maxTricks else { return nil }
        return forbidden
    }

    private static func makeBiddingOrder(playerCount: Int, dealerIndex: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let dealer = min(max(dealerIndex, 0), playerCount - 1)
        let start = (dealer + 1) % playerCount
        var order: [Int] = []
        order.reserveCapacity(playerCount)
        for offset in 0..<playerCount {
            order.append((start + offset) % playerCount)
        }
        return order
    }
}
