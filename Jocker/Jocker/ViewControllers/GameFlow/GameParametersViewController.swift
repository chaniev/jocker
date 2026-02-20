//
//  GameParametersViewController.swift
//  Jocker
//
//  Created by Codex on 20.02.2026.
//

import UIKit

final class GameParametersViewController: UIViewController, UITextFieldDelegate {
    private enum Appearance {
        static let backgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1.0)
        static let panelColor = UIColor(red: 0.14, green: 0.18, blue: 0.27, alpha: 1.0)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let subtitleColor = GameColors.textSecondary
        static let textFieldBackground = UIColor.white.withAlphaComponent(0.10)
        static let textFieldBorder = UIColor.white.withAlphaComponent(0.28)
        static let radioSelectedBackground = UIColor(red: 0.25, green: 0.35, blue: 0.52, alpha: 0.98)
        static let radioUnselectedBackground = UIColor.white.withAlphaComponent(0.03)
        static let radioBorder = UIColor.white.withAlphaComponent(0.24)
        static let radioSelectedBorder = UIColor(red: 0.90, green: 0.72, blue: 0.22, alpha: 0.98)
        static let radioSelectedIcon = UIColor(red: 0.92, green: 0.76, blue: 0.24, alpha: 1.0)
        static let radioUnselectedIcon = UIColor.white.withAlphaComponent(0.66)
        static let buttonFill = GameColors.buttonFill
        static let buttonText = GameColors.buttonText
    }

    private enum Layout {
        static let rowSpacing: CGFloat = 12
        static let panelCornerRadius: CGFloat = 16
        static let textFieldHeight: CGFloat = 44
        static let difficultyRadioButtonHeight: CGFloat = 42
        static let footerButtonHeight: CGFloat = 50
    }

    private var settings: GamePlayersSettings
    private let onSave: (GamePlayersSettings) -> Void

    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var nameFields: [UITextField] = []
    private var difficultyOptionButtonsByPlayerIndex: [Int: [BotDifficulty: UIButton]] = [:]
    private var selectedBotDifficulties: [BotDifficulty]
    private let difficultyDisplayOrder: [BotDifficulty] = [.hard, .normal, .easy]

    init(
        settings: GamePlayersSettings,
        onSave: @escaping (GamePlayersSettings) -> Void
    ) {
        self.settings = settings
        self.onSave = onSave
        self.selectedBotDifficulties = settings.botDifficulties
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupHeader()
        setupPlayersForm()
        setupFooterButtons()
    }

    private func setupView() {
        view.backgroundColor = Appearance.backgroundColor

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.panelColor
        containerView.layer.cornerRadius = Layout.panelCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        view.addSubview(containerView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        containerView.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = Layout.rowSpacing
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 86),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -80),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Параметры игры"
        titleLabel.textColor = Appearance.titleColor
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30)
        titleLabel.textAlignment = .left
        containerView.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Имена всех игроков и сложность ботов"
        subtitleLabel.textColor = Appearance.subtitleColor
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16)
        subtitleLabel.textAlignment = .left
        containerView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
    }

    private func setupPlayersForm() {
        nameFields.removeAll()
        difficultyOptionButtonsByPlayerIndex.removeAll()

        for playerIndex in 0..<GamePlayersSettings.supportedPlayerSlots {
            contentStack.addArrangedSubview(makePlayerRow(playerIndex: playerIndex))
        }
    }

    private func makePlayerRow(playerIndex: Int) -> UIView {
        let rowContainer = UIView()
        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        rowContainer.layer.cornerRadius = 10
        rowContainer.layer.borderWidth = 1
        rowContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        rowContainer.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Игрок \(playerIndex + 1)"
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        titleLabel.textColor = Appearance.titleColor
        titleLabel.textAlignment = .left
        stack.addArrangedSubview(titleLabel)

        let nameField = UITextField()
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.text = settings.displayName(for: playerIndex)
        nameField.placeholder = "Игрок \(playerIndex + 1)"
        nameField.font = UIFont(name: "AvenirNext-Medium", size: 18)
        nameField.textColor = Appearance.titleColor
        nameField.tintColor = .white
        nameField.backgroundColor = Appearance.textFieldBackground
        nameField.layer.cornerRadius = 10
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = Appearance.textFieldBorder.cgColor
        nameField.autocapitalizationType = .words
        nameField.autocorrectionType = .no
        nameField.returnKeyType = .done
        nameField.clearButtonMode = .whileEditing
        nameField.delegate = self
        nameField.setLeftPadding(12)
        nameField.setRightPadding(12)
        nameField.heightAnchor.constraint(equalToConstant: Layout.textFieldHeight).isActive = true
        nameField.accessibilityIdentifier = "game_parameters_name_field_\(playerIndex + 1)"
        stack.addArrangedSubview(nameField)
        nameFields.append(nameField)

        if playerIndex == 0 {
            let hintLabel = UILabel()
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            hintLabel.text = "Сложность не задается для игрока 1"
            hintLabel.font = UIFont(name: "AvenirNext-Medium", size: 14)
            hintLabel.textColor = Appearance.subtitleColor
            hintLabel.numberOfLines = 2
            hintLabel.textAlignment = .left
            stack.addArrangedSubview(hintLabel)
        } else {
            let difficultyLabel = UILabel()
            difficultyLabel.translatesAutoresizingMaskIntoConstraints = false
            difficultyLabel.text = "Сложность бота"
            difficultyLabel.font = UIFont(name: "AvenirNext-Medium", size: 14)
            difficultyLabel.textColor = Appearance.subtitleColor
            difficultyLabel.textAlignment = .left
            stack.addArrangedSubview(difficultyLabel)

            let radioStack = UIStackView()
            radioStack.translatesAutoresizingMaskIntoConstraints = false
            radioStack.axis = .horizontal
            radioStack.spacing = 6
            radioStack.alignment = .fill
            radioStack.distribution = .fillEqually
            stack.addArrangedSubview(radioStack)

            var buttonsByDifficulty: [BotDifficulty: UIButton] = [:]
            for difficulty in difficultyDisplayOrder {
                let button = makeDifficultyRadioButton(
                    playerIndex: playerIndex,
                    difficulty: difficulty
                )
                buttonsByDifficulty[difficulty] = button
                radioStack.addArrangedSubview(button)
            }

            difficultyOptionButtonsByPlayerIndex[playerIndex] = buttonsByDifficulty
            updateDifficultyOptions(for: playerIndex)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: rowContainer.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor, constant: -12),
        ])

        return rowContainer
    }

    private func setupFooterButtons() {
        let cancelButton = makeFooterButton(title: "Отмена")
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)

        let saveButton = makeFooterButton(title: "Сохранить")
        saveButton.addTarget(self, action: #selector(handleSaveTapped), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually
        containerView.addSubview(buttonsStack)

        NSLayoutConstraint.activate([
            buttonsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            buttonsStack.heightAnchor.constraint(equalToConstant: Layout.footerButtonHeight)
        ])
    }

    private func makeFooterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        button.setTitleColor(Appearance.buttonText, for: .normal)
        button.backgroundColor = Appearance.buttonFill
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = GameColors.buttonStroke.cgColor
        return button
    }

    private func makeDifficultyRadioButton(
        playerIndex: Int,
        difficulty: BotDifficulty
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 12)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.setTitle("   \(difficulty.settingsDisplayTitle)", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.heightAnchor.constraint(equalToConstant: Layout.difficultyRadioButtonHeight).isActive = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.semanticContentAttribute = .forceLeftToRight
        button.tag = (playerIndex * 10) + difficultyTagValue(for: difficulty)
        button.accessibilityIdentifier = "game_parameters_difficulty_radio_\(playerIndex + 1)_\(difficulty.rawValue)"
        button.addTarget(self, action: #selector(handleDifficultyRadioTapped(_:)), for: .touchUpInside)
        return button
    }

    private func updateDifficultyOptions(for playerIndex: Int) {
        guard let buttons = difficultyOptionButtonsByPlayerIndex[playerIndex] else { return }
        let selected = selectedDifficulty(for: playerIndex)

        for difficulty in difficultyDisplayOrder {
            guard let button = buttons[difficulty] else { continue }
            let isSelected = difficulty == selected
            let iconName = isSelected ? "largecircle.fill.circle" : "circle"
            let iconConfig = UIImage.SymbolConfiguration(
                pointSize: isSelected ? 21 : 20,
                weight: isSelected ? .bold : .regular
            )
            let iconImage = UIImage(systemName: iconName, withConfiguration: iconConfig)
            button.setImage(iconImage, for: .normal)
            button.tintColor = isSelected ? Appearance.radioSelectedIcon : Appearance.radioUnselectedIcon
            button.setTitleColor(
                isSelected ? Appearance.titleColor : Appearance.subtitleColor,
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

    private func selectedDifficulty(for playerIndex: Int) -> BotDifficulty {
        guard selectedBotDifficulties.indices.contains(playerIndex) else {
            return .hard
        }
        return selectedBotDifficulties[playerIndex]
    }

    private func saveSettingsAndDismiss() {
        let names = (0..<GamePlayersSettings.supportedPlayerSlots).map { index in
            let rawName = nameFields.indices.contains(index) ? nameFields[index].text : nil
            return normalizedName(rawName, playerIndex: index)
        }

        let updatedSettings = GamePlayersSettings(
            playerNames: names,
            botDifficulties: selectedBotDifficulties
        )

        onSave(updatedSettings)
        dismiss(animated: true)
    }

    private func normalizedName(_ rawName: String?, playerIndex: Int) -> String {
        let trimmed = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Игрок \(playerIndex + 1)" : trimmed
    }

    private func difficultyTagValue(for difficulty: BotDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 0
        case .normal:
            return 1
        case .hard:
            return 2
        }
    }

    private func difficultyFromTagValue(_ value: Int) -> BotDifficulty? {
        switch value {
        case 0:
            return .easy
        case 1:
            return .normal
        case 2:
            return .hard
        default:
            return nil
        }
    }

    @objc
    private func handleDifficultyRadioTapped(_ sender: UIButton) {
        let playerIndex = sender.tag / 10
        let difficultyTag = sender.tag % 10

        guard playerIndex > 0 else { return }
        guard selectedBotDifficulties.indices.contains(playerIndex) else { return }
        guard let difficulty = difficultyFromTagValue(difficultyTag) else { return }

        selectedBotDifficulties[playerIndex] = difficulty
        updateDifficultyOptions(for: playerIndex)
    }

    @objc
    private func handleCancelTapped() {
        dismiss(animated: true)
    }

    @objc
    private func handleSaveTapped() {
        view.endEditing(true)
        saveSettingsAndDismiss()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
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
