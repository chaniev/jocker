//
//  PlayerSettingsRowView.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class PlayerSettingsRowView: UIView {
    enum Mode {
        case human
        case bot(selectedDifficulty: BotDifficulty)
    }

    private enum Appearance {
        static let rowBackground = UIColor.white.withAlphaComponent(0.04)
        static let rowBorder = UIColor.white.withAlphaComponent(0.12)
        static let textFieldBackground = UIColor.white.withAlphaComponent(0.10)
        static let textFieldBorder = UIColor.white.withAlphaComponent(0.28)
        static let radioSelectedBackground = UIColor(red: 0.25, green: 0.35, blue: 0.52, alpha: 0.98)
        static let radioUnselectedBackground = UIColor.white.withAlphaComponent(0.03)
        static let radioBorder = UIColor.white.withAlphaComponent(0.24)
        static let radioSelectedBorder = UIColor(red: 0.90, green: 0.72, blue: 0.22, alpha: 0.98)
        static let radioSelectedIcon = UIColor(red: 0.92, green: 0.76, blue: 0.24, alpha: 1.0)
        static let radioUnselectedIcon = UIColor.white.withAlphaComponent(0.66)
    }

    private enum Layout {
        static let textFieldHeight: CGFloat = 44
        static let difficultyRadioButtonHeight: CGFloat = 42
    }

    private let playerIndex: Int
    private let mode: Mode
    private let onDifficultySelected: ((BotDifficulty) -> Void)?

    private let nameField = UITextField()
    private var selectedDifficulty: BotDifficulty?
    private var difficultyButtons: [BotDifficulty: UIButton] = [:]
    private let difficultyDisplayOrder: [BotDifficulty] = [.hard, .normal, .easy]

    init(
        playerIndex: Int,
        playerName: String,
        mode: Mode,
        onDifficultySelected: ((BotDifficulty) -> Void)? = nil
    ) {
        self.playerIndex = playerIndex
        self.mode = mode
        self.onDifficultySelected = onDifficultySelected
        if case .bot(let selectedDifficulty) = mode {
            self.selectedDifficulty = selectedDifficulty
        }
        super.init(frame: .zero)
        setupView(playerName: playerName)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTextFieldDelegate(_ delegate: UITextFieldDelegate?) {
        nameField.delegate = delegate
    }

    func resolvedName() -> String {
        return PlayerDisplayNameFormatter.normalizedName(
            nameField.text,
            playerIndex: playerIndex
        )
    }

    private func setupView(playerName: String) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Appearance.rowBackground
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = Appearance.rowBorder.cgColor

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Игрок \(playerIndex + 1)"
        titleLabel.font = PanelTypography.sectionTitle
        titleLabel.textColor = PanelAppearance.primaryTextColor
        titleLabel.textAlignment = .left
        stack.addArrangedSubview(titleLabel)

        configureNameField(playerName: playerName)
        stack.addArrangedSubview(nameField)

        switch mode {
        case .human:
            let hintLabel = UILabel()
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            hintLabel.text = "Уровень зависит от самого игрока"
            hintLabel.font = PanelTypography.modalSubtitle
            hintLabel.textColor = PanelAppearance.secondaryTextColor
            hintLabel.numberOfLines = 2
            hintLabel.textAlignment = .left
            stack.addArrangedSubview(hintLabel)
        case .bot:
            let difficultyLabel = UILabel()
            difficultyLabel.translatesAutoresizingMaskIntoConstraints = false
            difficultyLabel.text = "Уровень"
            difficultyLabel.font = PanelTypography.modalSubtitle
            difficultyLabel.textColor = PanelAppearance.secondaryTextColor
            difficultyLabel.textAlignment = .left
            stack.addArrangedSubview(difficultyLabel)

            let radioStack = UIStackView()
            radioStack.translatesAutoresizingMaskIntoConstraints = false
            radioStack.axis = .horizontal
            radioStack.spacing = 6
            radioStack.alignment = .fill
            radioStack.distribution = .fillEqually
            stack.addArrangedSubview(radioStack)

            for difficulty in difficultyDisplayOrder {
                let button = makeDifficultyButton(difficulty: difficulty)
                difficultyButtons[difficulty] = button
                radioStack.addArrangedSubview(button)
            }

            updateDifficultyButtons()
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    private func configureNameField(playerName: String) {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.text = playerName
        nameField.placeholder = "Игрок \(playerIndex + 1)"
        nameField.font = PanelTypography.bodyLarge
        nameField.textColor = PanelAppearance.primaryTextColor
        nameField.tintColor = .white
        nameField.backgroundColor = Appearance.textFieldBackground
        nameField.layer.cornerRadius = 10
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = Appearance.textFieldBorder.cgColor
        nameField.autocapitalizationType = .words
        nameField.autocorrectionType = .no
        nameField.returnKeyType = .done
        nameField.clearButtonMode = .whileEditing
        nameField.setLeftPadding(12)
        nameField.setRightPadding(12)
        nameField.heightAnchor.constraint(equalToConstant: Layout.textFieldHeight).isActive = true
        nameField.accessibilityIdentifier = "game_parameters_name_field_\(playerIndex + 1)"
    }

    private func makeDifficultyButton(difficulty: BotDifficulty) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = PanelTypography.caption
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.setTitle("   \(difficulty.settingsDisplayTitle)", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.heightAnchor.constraint(equalToConstant: Layout.difficultyRadioButtonHeight).isActive = true
        button.semanticContentAttribute = .forceLeftToRight
        button.accessibilityIdentifier = "game_parameters_difficulty_radio_\(playerIndex + 1)_\(difficulty.rawValue)"
        button.addAction(
            UIAction { [weak self] _ in
                self?.handleDifficultySelection(difficulty)
            },
            for: .touchUpInside
        )
        return button
    }

    private func handleDifficultySelection(_ difficulty: BotDifficulty) {
        selectedDifficulty = difficulty
        updateDifficultyButtons()
        onDifficultySelected?(difficulty)
    }

    private func updateDifficultyButtons() {
        for difficulty in difficultyDisplayOrder {
            guard let button = difficultyButtons[difficulty] else { continue }
            let isSelected = difficulty == selectedDifficulty
            let iconName = isSelected ? "largecircle.fill.circle" : "circle"
            let iconConfig = UIImage.SymbolConfiguration(
                pointSize: isSelected ? 21 : 20,
                weight: isSelected ? .bold : .regular
            )
            let iconImage = UIImage(systemName: iconName, withConfiguration: iconConfig)
            button.setImage(iconImage, for: .normal)
            button.tintColor = isSelected ? Appearance.radioSelectedIcon : Appearance.radioUnselectedIcon
            button.setTitleColor(
                isSelected ? PanelAppearance.primaryTextColor : PanelAppearance.secondaryTextColor,
                for: .normal
            )
            button.backgroundColor = isSelected
                ? Appearance.radioSelectedBackground
                : Appearance.radioUnselectedBackground
            button.layer.borderWidth = isSelected ? 2 : 1
            button.layer.borderColor = isSelected
                ? Appearance.radioSelectedBorder.cgColor
                : Appearance.radioBorder.cgColor
        }
    }
}

private extension UITextField {
    func setLeftPadding(_ value: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        leftViewMode = .always
    }

    func setRightPadding(_ value: CGFloat) {
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: value, height: 1))
        rightViewMode = .always
    }
}
