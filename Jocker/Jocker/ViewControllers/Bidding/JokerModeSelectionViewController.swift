//
//  JokerModeSelectionViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class JokerModeSelectionViewController: UIViewController {
    private enum LeadMode: Int, CaseIterable {
        case wish
        case above
        case takes
    }

    private enum NonLeadMode: Int, CaseIterable {
        case faceUp
        case faceDown
    }

    private let isLeadCard: Bool
    private let onSubmit: (JokerPlayDecision) -> Void
    private let onCancel: (() -> Void)?

    private weak var leadModeControl: UISegmentedControl?
    private weak var suitControl: UISegmentedControl?
    private weak var nonLeadModeControl: UISegmentedControl?
    private weak var suitTitleLabel: UILabel?

    init(
        isLeadCard: Bool,
        onSubmit: @escaping (JokerPlayDecision) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.isLeadCard = isLeadCard
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
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
            title: "Выберите как положить джокер",
            alignment: .center,
            titleFont: PanelTypography.modalTitle
        )
        containerView.addSubview(headerView)

        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        containerView.addSubview(contentStack)

        if isLeadCard {
            let modeControl = UISegmentedControl(items: ["Хочу", "Выше", "Забирает"])
            modeControl.selectedSegmentIndex = LeadMode.wish.rawValue
            modeControl.addTarget(self, action: #selector(handleLeadModeChanged), for: .valueChanged)
            leadModeControl = modeControl
            contentStack.addArrangedSubview(modeControl)

            let suitTitle = UILabel()
            suitTitle.text = "Выберите масть"
            suitTitle.font = PanelTypography.body
            suitTitle.textColor = PanelAppearance.primaryTextColor
            suitTitle.textAlignment = .left
            suitTitleLabel = suitTitle
            contentStack.addArrangedSubview(suitTitle)

            let suitControl = UISegmentedControl(items: suitSegmentTitles())
            suitControl.selectedSegmentIndex = 0
            self.suitControl = suitControl
            contentStack.addArrangedSubview(suitControl)
        } else {
            let modeControl = UISegmentedControl(items: ["Лицом вверх", "Подпихнуть"])
            modeControl.selectedSegmentIndex = NonLeadMode.faceUp.rawValue
            nonLeadModeControl = modeControl
            contentStack.addArrangedSubview(modeControl)
        }

        let buttonsRow = UIStackView()
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually
        containerView.addSubview(buttonsRow)

        let cancelButton = SecondaryPanelButton(title: "Отмена", style: .neutral)
        cancelButton.addTarget(self, action: #selector(handleCancelButton), for: .touchUpInside)

        let confirmButton = PrimaryPanelButton(
            title: "Подтвердить",
            font: PanelTypography.secondaryButton
        )
        confirmButton.addTarget(self, action: #selector(handleConfirmButton), for: .touchUpInside)

        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(confirmButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.78),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 420),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            contentStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            buttonsRow.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 18),
            buttonsRow.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonsRow.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonsRow.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonsRow.heightAnchor.constraint(equalToConstant: 50)
        ])

        updateSuitVisibility()
    }

    @objc private func handleLeadModeChanged() {
        updateSuitVisibility()
    }

    @objc private func handleCancelButton() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func handleConfirmButton() {
        onSubmit(buildDecision())
        dismiss(animated: true)
    }

    private func buildDecision() -> JokerPlayDecision {
        if isLeadCard {
            let mode = LeadMode(rawValue: leadModeControl?.selectedSegmentIndex ?? 0) ?? .wish
            switch mode {
            case .wish:
                return JokerPlayDecision(style: .faceUp, leadDeclaration: .wish)
            case .above:
                return JokerPlayDecision(style: .faceUp, leadDeclaration: .above(suit: selectedSuit()))
            case .takes:
                return JokerPlayDecision(style: .faceUp, leadDeclaration: .takes(suit: selectedSuit()))
            }
        }

        let mode = NonLeadMode(rawValue: nonLeadModeControl?.selectedSegmentIndex ?? 0) ?? .faceUp
        switch mode {
        case .faceUp:
            return JokerPlayDecision(style: .faceUp, leadDeclaration: nil)
        case .faceDown:
            return JokerPlayDecision(style: .faceDown, leadDeclaration: nil)
        }
    }

    private func selectedSuit() -> Suit {
        let selectedIndex = suitControl?.selectedSegmentIndex ?? 0
        let suits = Suit.allCases
        guard suits.indices.contains(selectedIndex) else { return .hearts }
        return suits[selectedIndex]
    }

    private func suitSegmentTitles() -> [String] {
        return Suit.allCases.map { suit in
            "\(suit.rawValue) \(suit.name)"
        }
    }

    private func updateSuitVisibility() {
        guard isLeadCard else { return }
        let mode = LeadMode(rawValue: leadModeControl?.selectedSegmentIndex ?? 0) ?? .wish
        let needsSuit = mode != .wish
        suitTitleLabel?.isHidden = !needsSuit
        suitControl?.isHidden = !needsSuit
    }
}
