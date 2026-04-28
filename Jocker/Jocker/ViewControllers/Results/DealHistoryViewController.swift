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
    private let presentation: DealHistoryPresentationBuilder.Presentation
    private let exportCoordinator: DealHistoryExportCoordinator

    private let containerView = PanelContainerView(surfaceColor: PanelAppearance.screenSurfaceColor)
    private lazy var headerView = PanelHeaderView(
        title: presentation.title,
        subtitle: presentation.subtitle,
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

    init(
        dealHistory: DealHistory,
        playerNames: [String],
        playerControlTypes: [PlayerControlType] = [],
        gameMode: GameMode = .freeForAll,
        exportService: DealHistoryExportService? = nil
    ) {
        self.dealHistory = dealHistory
        let resolvedExportService = exportService ?? DealHistoryExportService(
            exportRootURL: Self.manualExportDirectoryURL
        )
        self.exportCoordinator = DealHistoryExportCoordinator(exportService: resolvedExportService)
        self.presentation = DealHistoryPresentationBuilder().build(
            dealHistory: dealHistory,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes,
            gameMode: gameMode
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
        trumpLabel.text = presentation.trumpText
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
        let isEmpty = presentation.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return presentation.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard presentation.sections.indices.contains(section) else { return 0 }
        return presentation.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = reuseIdentifier(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        cell.backgroundColor = Appearance.tableSectionBackground
        cell.contentView.backgroundColor = Appearance.tableSectionBackground
        cell.tintColor = PanelAppearance.primaryTextColor
        cell.textLabel?.textColor = PanelAppearance.primaryTextColor
        cell.detailTextLabel?.textColor = PanelAppearance.secondaryTextColor

        guard presentation.sections.indices.contains(indexPath.section),
              presentation.sections[indexPath.section].rows.indices.contains(indexPath.row) else {
            cell.textLabel?.text = ""
            return cell
        }

        let row = presentation.sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .hand:
            cell.textLabel?.font = PanelTypography.compactLabel
            cell.textLabel?.numberOfLines = 1
            cell.detailTextLabel?.font = PanelTypography.body
            cell.detailTextLabel?.numberOfLines = 0
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = row.detail
        case .move:
            cell.textLabel?.font = PanelTypography.screenSubtitle
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
            cell.textLabel?.text = row.title
        }

        return cell
    }

    private func reuseIdentifier(for indexPath: IndexPath) -> String {
        guard presentation.sections.indices.contains(indexPath.section),
              presentation.sections[indexPath.section].rows.indices.contains(indexPath.row) else {
            return "MoveCell"
        }

        let row = presentation.sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .hand:
            return "HandCell"
        case .move:
            return "MoveCell"
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard presentation.sections.indices.contains(section) else { return nil }
        return presentation.sections[section].title
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
        exportCoordinator.export(
            dealHistory: dealHistory,
            exportData: presentation.exportData,
            from: self,
            sourceButton: exportButton
        )
    }

    @objc private func handleCloseTapped() {
        dismiss(animated: true)
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
