//
//  GameParametersViewController.swift
//  Jocker
//
//  Created by Codex on 20.02.2026.
//

import UIKit

final class GameParametersViewController: UIViewController, UITextFieldDelegate {
    private enum Layout {
        static let rowSpacing: CGFloat = 12
        static let footerButtonHeight: CGFloat = 50
    }

    private let settings: GamePlayersSettings
    private let onSave: (GamePlayersSettings) -> Void

    private let containerView = PanelContainerView(surfaceColor: PanelAppearance.screenSurfaceColor)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerView = PanelHeaderView(
        title: "Параметры игры",
        subtitle: "Имена всех игроков и сложность ботов",
        alignment: .left,
        titleFont: PanelTypography.screenTitle,
        subtitleFont: PanelTypography.screenSubtitle
    )

    private var playerRows: [PlayerSettingsRowView] = []
    private var selectedBotDifficulties: [BotDifficulty]

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
        view.backgroundColor = PanelAppearance.screenBackgroundColor

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
        containerView.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
        ])
    }

    private func setupPlayersForm() {
        for row in playerRows {
            contentStack.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        playerRows.removeAll()

        for playerIndex in 0..<GamePlayersSettings.supportedPlayerSlots {
            let row = makePlayerSettingsRowView(playerIndex: playerIndex)
            playerRows.append(row)
            contentStack.addArrangedSubview(row)
        }
    }

    private func makePlayerSettingsRowView(playerIndex: Int) -> PlayerSettingsRowView {
        let row: PlayerSettingsRowView
        if playerIndex == 0 {
            row = PlayerSettingsRowView(
                playerIndex: playerIndex,
                playerName: settings.displayName(for: playerIndex),
                mode: .human
            )
        } else {
            let selectedDifficulty = selectedBotDifficulties.indices.contains(playerIndex)
                ? selectedBotDifficulties[playerIndex]
                : .hard
            row = PlayerSettingsRowView(
                playerIndex: playerIndex,
                playerName: settings.displayName(for: playerIndex),
                mode: .bot(selectedDifficulty: selectedDifficulty),
                onDifficultySelected: { [weak self] difficulty in
                    guard let self,
                          self.selectedBotDifficulties.indices.contains(playerIndex) else { return }
                    self.selectedBotDifficulties[playerIndex] = difficulty
                }
            )
        }

        row.setTextFieldDelegate(self)
        return row
    }

    private func setupFooterButtons() {
        let cancelButton = SecondaryPanelButton(title: "Отмена")
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)

        let saveButton = PrimaryPanelButton(title: "Сохранить")
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

    private func saveSettingsAndDismiss() {
        let names = playerRows.map { $0.resolvedName() }

        let updatedSettings = GamePlayersSettings(
            playerNames: names,
            botDifficulties: selectedBotDifficulties
        )

        onSave(updatedSettings)
        dismiss(animated: true)
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
