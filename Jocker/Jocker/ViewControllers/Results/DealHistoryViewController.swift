//
//  DealHistoryViewController.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import UIKit

final class DealHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    private enum Appearance {
        static let backgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1.0)
        static let containerColor = UIColor(red: 0.14, green: 0.18, blue: 0.27, alpha: 1.0)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let subtitleColor = GameColors.textSecondary
        static let buttonColor = GameColors.buttonFill
        static let buttonTextColor = GameColors.buttonText
        static let secondaryButtonBackground = UIColor(red: 0.20, green: 0.30, blue: 0.46, alpha: 0.55)
        static let tableSectionBackground = UIColor(red: 0.11, green: 0.15, blue: 0.24, alpha: 0.95)
        static let tableSeparatorColor = UIColor(red: 0.30, green: 0.41, blue: 0.60, alpha: 0.56)
        static let primaryRowTextColor = GameColors.textPrimary
        static let secondaryRowTextColor = GameColors.textSecondary
    }

    private enum Layout {
        static let containerCornerRadius: CGFloat = 16
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

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let trumpLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
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
        view.backgroundColor = Appearance.backgroundColor

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.containerColor
        containerView.layer.cornerRadius = Layout.containerCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupHeader() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18)
        closeButton.setTitleColor(Appearance.buttonTextColor, for: .normal)
        closeButton.backgroundColor = Appearance.buttonColor
        closeButton.layer.cornerRadius = 12
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = GameColors.buttonStroke.cgColor
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.setTitle("Экспорт JSON", for: .normal)
        exportButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        exportButton.setTitleColor(Appearance.primaryRowTextColor, for: .normal)
        exportButton.backgroundColor = Appearance.secondaryButtonBackground
        exportButton.layer.cornerRadius = 12
        exportButton.layer.borderWidth = 1
        exportButton.layer.borderColor = Appearance.tableSeparatorColor.cgColor
        exportButton.addTarget(self, action: #selector(handleExportTapped), for: .touchUpInside)
        containerView.addSubview(exportButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 29)
        titleLabel.textColor = Appearance.titleColor
        titleLabel.textAlignment = .left
        titleLabel.text = "Раздача \(dealHistory.key.roundIndex + 1), блок \(dealHistory.key.blockIndex + 1)"
        containerView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16)
        subtitleLabel.textColor = Appearance.subtitleColor
        subtitleLabel.textAlignment = .left
        subtitleLabel.text = "Подробная история хода и стартовых рук игроков"
        containerView.addSubview(subtitleLabel)

        trumpLabel.translatesAutoresizingMaskIntoConstraints = false
        trumpLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        trumpLabel.textColor = Appearance.subtitleColor
        trumpLabel.textAlignment = .left
        trumpLabel.text = trumpDisplayText()
        containerView.addSubview(trumpLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        ])

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            trumpLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),
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
        emptyStateLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 20)
        emptyStateLabel.textColor = Appearance.secondaryRowTextColor
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
        guard playerNames.indices.contains(index) else {
            return "Игрок \(index + 1)"
        }

        let trimmed = playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Игрок \(index + 1)" : trimmed
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
        return (0..<playerCount).map { index in
            if playerNames.indices.contains(index) {
                let trimmed = playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "Игрок \(index + 1)" : trimmed
            }
            return "Игрок \(index + 1)"
        }
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
        cell.tintColor = Appearance.primaryRowTextColor
        cell.textLabel?.textColor = Appearance.primaryRowTextColor
        cell.detailTextLabel?.textColor = Appearance.secondaryRowTextColor

        if hasHandsSection, indexPath.section == 0 {
            let playerIndex = indexPath.row
            let playerName = playerDisplayName(at: playerIndex)
            let role = playerRoleDisplayName(at: playerIndex)
            cell.textLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
            cell.textLabel?.numberOfLines = 1
            cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Medium", size: 15)
            cell.detailTextLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(playerName) (\(role))"
            cell.detailTextLabel?.text = handDisplayText(for: playerIndex)
            return cell
        }

        cell.textLabel?.font = UIFont(name: "AvenirNext-Medium", size: 16)
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
        header.tintColor = Appearance.containerColor
        header.contentView.backgroundColor = Appearance.containerColor
        header.textLabel?.textColor = Appearance.subtitleColor
        header.textLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 15)
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
