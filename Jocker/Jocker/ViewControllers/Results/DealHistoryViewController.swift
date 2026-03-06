//
//  DealHistoryViewController.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import UIKit

final class DealHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    private enum Appearance {
        static let tableSectionBackground = UIColor(red: 0.11, green: 0.15, blue: 0.24, alpha: 0.95)
        static let tableSeparatorColor = UIColor(red: 0.30, green: 0.41, blue: 0.60, alpha: 0.56)
    }

    private enum Layout {
        static let buttonHeight: CGFloat = 46
    }

    private static let manualExportDirectoryURL: URL = {
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("Jocker", isDirectory: true)
            .appendingPathComponent("DealExports", isDirectory: true)
    }()

    private let dealHistory: DealHistory
    private let playerNames: [String]
    private let playerControlTypes: [PlayerControlType]
    private let exportService: DealHistoryExportService

    private let containerView = PanelContainerView(surfaceColor: PanelAppearance.screenSurfaceColor)
    private lazy var headerView = PanelHeaderView(
        title: "Раздача \(dealHistory.key.roundIndex + 1), блок \(dealHistory.key.blockIndex + 1)",
        subtitle: "Подробная история хода и стартовых рук игроков",
        alignment: .left,
        titleFont: PanelTypography.resultsTitle,
        subtitleFont: PanelTypography.screenSubtitle
    )
    private let trumpLabel = UILabel()
    private let closeButton = PrimaryPanelButton(
        title: "Закрыть",
        font: PanelTypography.secondaryButton
    )
    private let exportButton = SecondaryPanelButton(
        title: "Экспорт JSON",
        font: PanelTypography.compactLabel
    )
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()
    private var isExportInProgress = false

    init(
        dealHistory: DealHistory,
        playerNames: [String],
        playerControlTypes: [PlayerControlType] = [],
        exportService: DealHistoryExportService? = nil
    ) {
        self.dealHistory = dealHistory
        self.playerNames = playerNames
        self.playerControlTypes = playerControlTypes
        self.exportService = exportService ?? DealHistoryExportService(
            exportRootURL: Self.manualExportDirectoryURL
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupHeader()
        setupTableView()
        setupEmptyState()
        setupDismissControls()
        updateEmptyStateVisibility()
    }

    private func setupView() {
        view.backgroundColor = PanelAppearance.screenBackgroundColor
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupHeader() {
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        exportButton.addTarget(self, action: #selector(handleExportTapped), for: .touchUpInside)
        containerView.addSubview(exportButton)

        containerView.addSubview(headerView)

        trumpLabel.translatesAutoresizingMaskIntoConstraints = false
        trumpLabel.font = PanelTypography.compactLabel
        trumpLabel.textColor = PanelAppearance.secondaryTextColor
        trumpLabel.textAlignment = .left
        trumpLabel.text = trumpDisplayText()
        containerView.addSubview(trumpLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            trumpLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            trumpLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            trumpLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            exportButton.topAnchor.constraint(equalTo: trumpLabel.bottomAnchor, constant: 12),
            exportButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            exportButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            closeButton.leadingAnchor.constraint(equalTo: exportButton.trailingAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.topAnchor.constraint(equalTo: exportButton.topAnchor),
            closeButton.widthAnchor.constraint(equalTo: exportButton.widthAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.backgroundColor = .clear
        tableView.separatorColor = Appearance.tableSeparatorColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.showsVerticalScrollIndicator = true
        containerView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }

    private func setupEmptyState() {
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.font = PanelTypography.primaryButton
        emptyStateLabel.textColor = PanelAppearance.secondaryTextColor
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.text = "По этой раздаче нет сохранённых данных."
        containerView.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tableView.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor, constant: -24)
        ])
    }

    private func setupDismissControls() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleCloseTapped))
        swipe.direction = .right
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }

    private func updateEmptyStateVisibility() {
        let isEmpty = !hasHandsSection && dealHistory.tricks.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    private func trumpDisplayText() -> String {
        guard let trump = dealHistory.trump else {
            return "Козырь: без козыря"
        }
        return "Козырь: \(trump.name)"
    }

    private func playerDisplayName(at index: Int) -> String {
        return PlayerDisplayNameFormatter.displayName(for: index, in: playerNames)
    }

    private func playerRoleDisplayName(at index: Int) -> String {
        guard playerControlTypes.indices.contains(index) else {
            return "Бот"
        }

        switch playerControlTypes[index] {
        case .human:
            return "Человек"
        case .bot:
            return "Бот"
        }
    }

    private var resolvedPlayerCount: Int {
        let maxPlayerIndexFromMoves = dealHistory.tricks
            .flatMap(\.moves)
            .map(\.playerIndex)
            .max() ?? -1
        return max(
            playerNames.count,
            playerControlTypes.count,
            dealHistory.initialHands.count,
            maxPlayerIndexFromMoves + 1
        )
    }

    private var hasHandsSection: Bool {
        return resolvedPlayerCount > 0
    }

    private func cardDisplayText(for card: Card) -> String {
        switch card {
        case .joker:
            return "🃏"
        case .regular(let suit, let rank):
            return "\(rank.symbol)\(suit.rawValue)"
        }
    }

    private func handDisplayText(for playerIndex: Int) -> String {
        guard dealHistory.initialHands.indices.contains(playerIndex) else {
            return "Нет данных"
        }

        let hand = dealHistory.initialHands[playerIndex].sorted()
        guard !hand.isEmpty else {
            return "Пусто"
        }

        return hand.map(cardDisplayText(for:)).joined(separator: "  ")
    }

    private var trickSectionOffset: Int {
        return hasHandsSection ? 1 : 0
    }

    private func normalizedPlayerNames(for playerCount: Int) -> [String] {
        return PlayerDisplayNameFormatter.normalizedNames(
            playerNames,
            playerCount: playerCount
        )
    }

    private func normalizedPlayerControlTypes(for playerCount: Int) -> [PlayerControlType] {
        return (0..<playerCount).map { index in
            if playerControlTypes.indices.contains(index) {
                return playerControlTypes[index]
            }
            return .bot
        }
    }

    private func cardDisplayText(for move: DealTrickMove) -> String {
        switch move.card {
        case .regular(let suit, let rank):
            return "\(rank.symbol)\(suit.rawValue)"
        case .joker:
            let styleSuffix = move.jokerPlayStyle == .faceDown ? "рубашкой вверх" : "лицом вверх"
            guard let declaration = move.jokerLeadDeclaration else {
                return "🃏 (\(styleSuffix))"
            }
            return "🃏 (\(styleSuffix), \(declarationDisplayText(declaration)))"
        }
    }

    private func declarationDisplayText(_ declaration: JokerLeadDeclaration) -> String {
        switch declaration {
        case .wish:
            return "хочу"
        case .above(let suit):
            return "выше \(suit.name.lowercased())"
        case .takes(let suit):
            return "забирает \(suit.name.lowercased())"
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        let handSectionsCount = hasHandsSection ? 1 : 0
        return handSectionsCount + dealHistory.tricks.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasHandsSection, section == 0 {
            return resolvedPlayerCount
        }

        let trickSection = section - trickSectionOffset
        guard dealHistory.tricks.indices.contains(trickSection) else { return 0 }
        return dealHistory.tricks[trickSection].moves.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = hasHandsSection && indexPath.section == 0 ? "HandCell" : "MoveCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        cell.backgroundColor = Appearance.tableSectionBackground
        cell.contentView.backgroundColor = Appearance.tableSectionBackground
        cell.tintColor = PanelAppearance.primaryTextColor
        cell.textLabel?.textColor = PanelAppearance.primaryTextColor
        cell.detailTextLabel?.textColor = PanelAppearance.secondaryTextColor

        if hasHandsSection, indexPath.section == 0 {
            let playerIndex = indexPath.row
            let playerName = playerDisplayName(at: playerIndex)
            let role = playerRoleDisplayName(at: playerIndex)
            cell.textLabel?.font = PanelTypography.compactLabel
            cell.textLabel?.numberOfLines = 1
            cell.detailTextLabel?.font = PanelTypography.body
            cell.detailTextLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(playerName) (\(role))"
            cell.detailTextLabel?.text = handDisplayText(for: playerIndex)
            return cell
        }

        cell.textLabel?.font = PanelTypography.screenSubtitle
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = nil

        let trickSection = indexPath.section - trickSectionOffset
        guard dealHistory.tricks.indices.contains(trickSection) else {
            cell.textLabel?.text = ""
            return cell
        }

        let trick = dealHistory.tricks[trickSection]
        guard trick.moves.indices.contains(indexPath.row) else {
            cell.textLabel?.text = ""
            return cell
        }

        let move = trick.moves[indexPath.row]
        let playerName = playerDisplayName(at: move.playerIndex)
        let moveText = cardDisplayText(for: move)
        cell.textLabel?.text = "\(indexPath.row + 1). \(playerName): \(moveText)"

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hasHandsSection, section == 0 {
            return "Карты на руках после раздачи"
        }

        let trickSection = section - trickSectionOffset
        guard dealHistory.tricks.indices.contains(trickSection) else { return nil }
        let trick = dealHistory.tricks[trickSection]
        let winnerName = playerDisplayName(at: trick.winnerPlayerIndex)
        return "Взятка \(trickSection + 1) • Забрал: \(winnerName)"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.tintColor = PanelAppearance.screenSurfaceColor
        header.contentView.backgroundColor = PanelAppearance.screenSurfaceColor
        header.textLabel?.textColor = PanelAppearance.secondaryTextColor
        header.textLabel?.font = PanelTypography.body
    }

    // MARK: - Actions

    @objc
    private func handleExportTapped() {
        guard !isExportInProgress else { return }

        let playerCount = resolvedPlayerCount
        guard playerCount > 0 else {
            showExportErrorAlert(message: "Не удалось определить состав игроков для экспорта.")
            return
        }

        isExportInProgress = true
        exportButton.isEnabled = false

        let result = exportService.export(
            histories: [dealHistory],
            playerCount: playerCount,
            playerNames: normalizedPlayerNames(for: playerCount),
            playerControlTypes: normalizedPlayerControlTypes(for: playerCount),
            reason: .deal(
                blockIndex: dealHistory.key.blockIndex,
                roundIndex: dealHistory.key.roundIndex
            )
        )

        guard let result else {
            finishExport()
            showExportErrorAlert(message: "Не удалось подготовить JSON-файл с историей раздачи.")
            return
        }

        let shareController = UIActivityViewController(
            activityItems: [result.fileURL],
            applicationActivities: nil
        )
        shareController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.finishExport()
        }

        if let popover = shareController.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }

        present(shareController, animated: true)
    }

    @objc private func handleCloseTapped() {
        dismiss(animated: true)
    }

    private func finishExport() {
        isExportInProgress = false
        exportButton.isEnabled = true
    }

    private func showExportErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Экспорт не выполнен",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
