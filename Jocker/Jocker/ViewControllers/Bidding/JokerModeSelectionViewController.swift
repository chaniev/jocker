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
        let overlayColor = UIColor(red: 0.04, green: 0.07, blue: 0.12, alpha: 0.58)
        let surfaceColor = UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 0.98)
        let borderColor = UIColor(red: 0.31, green: 0.40, blue: 0.55, alpha: 0.85)
        let titleColor = UIColor(red: 0.95, green: 0.97, blue: 1.00, alpha: 1.0)
        let accentColor = UIColor(red: 0.16, green: 0.39, blue: 0.77, alpha: 1.0)

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
        titleLabel.text = "Выберите как положить джокер"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = titleColor
        containerView.addSubview(titleLabel)

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
            suitTitle.font = UIFont(name: "AvenirNext-DemiBold", size: 15)
            suitTitle.textColor = titleColor
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

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отмена", for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        cancelButton.backgroundColor = UIColor(red: 0.22, green: 0.28, blue: 0.38, alpha: 1.0)
        cancelButton.setTitleColor(titleColor, for: .normal)
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(handleCancelButton), for: .touchUpInside)

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Подтвердить", for: .normal)
        confirmButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        confirmButton.backgroundColor = accentColor
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(handleConfirmButton), for: .touchUpInside)

        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(confirmButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.78),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 420),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
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
