//
//  GameStatisticsViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class GameStatisticsViewController: UIViewController {
    private enum Appearance {
        static let segmentedTint = UIColor(red: 0.20, green: 0.30, blue: 0.46, alpha: 1.0)
    }

    private let statisticsStore: GameStatisticsStore
    private let playersSettingsStore: GamePlayersSettingsStore
    private let presentationProvider = GameStatisticsPresentationProvider()
    private var snapshot: GameStatisticsSnapshot
    private var playersSettings: GamePlayersSettings
    private var selectedScope: GameStatisticsScope = .allGames

    private let containerView = PanelContainerView(surfaceColor: PanelAppearance.screenSurfaceColor)
    private let headerView = PanelHeaderView(
        title: "Статистика игр",
        subtitle: "Таблица метрик по всем игрокам",
        alignment: .left,
        titleFont: PanelTypography.screenTitle,
        subtitleFont: PanelTypography.screenSubtitle
    )
    private let scopeSegmentedControl = UISegmentedControl(items: GameStatisticsScope.allCases.map(\.title))
    private let statisticsTableView = GameStatisticsTableView()
    private let closeButton = PrimaryPanelButton(title: "Назад")

    init(
        statisticsStore: GameStatisticsStore = UserDefaultsGameStatisticsStore(),
        playersSettingsStore: GamePlayersSettingsStore = GamePlayersSettingsStore()
    ) {
        self.statisticsStore = statisticsStore
        self.playersSettingsStore = playersSettingsStore
        self.snapshot = statisticsStore.loadSnapshot()
        self.playersSettings = playersSettingsStore.loadSettings()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupHeader()
        setupStatisticsTable()
        setupCloseButton()
        applySelectedScope(index: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        snapshot = statisticsStore.loadSnapshot()
        playersSettings = playersSettingsStore.loadSettings()
        refreshStatisticsTable()
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
        containerView.addSubview(headerView)

        scopeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        scopeSegmentedControl.selectedSegmentIndex = 0
        scopeSegmentedControl.backgroundColor = Appearance.segmentedTint.withAlphaComponent(0.55)
        scopeSegmentedControl.selectedSegmentTintColor = Appearance.segmentedTint
        scopeSegmentedControl.setTitleTextAttributes([
            .font: PanelTypography.body as Any,
            .foregroundColor: PanelAppearance.primaryTextColor
        ], for: .selected)
        scopeSegmentedControl.setTitleTextAttributes([
            .font: PanelTypography.modalSubtitle as Any,
            .foregroundColor: PanelAppearance.secondaryTextColor
        ], for: .normal)
        scopeSegmentedControl.addTarget(self, action: #selector(handleScopeChanged), for: .valueChanged)
        containerView.addSubview(scopeSegmentedControl)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scopeSegmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            scopeSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scopeSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scopeSegmentedControl.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    private func setupStatisticsTable() {
        statisticsTableView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statisticsTableView)

        NSLayoutConstraint.activate([
            statisticsTableView.topAnchor.constraint(equalTo: scopeSegmentedControl.bottomAnchor, constant: 10),
            statisticsTableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            statisticsTableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            statisticsTableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -78)
        ])
    }

    private func setupCloseButton() {
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc
    private func handleScopeChanged() {
        applySelectedScope(index: scopeSegmentedControl.selectedSegmentIndex)
    }

    @objc
    private func handleCloseTapped() {
        dismiss(animated: true)
    }

    private func applySelectedScope(index: Int) {
        let clampedIndex = min(max(index, 0), GameStatisticsScope.allCases.count - 1)
        selectedScope = GameStatisticsScope.allCases[clampedIndex]
        refreshStatisticsTable()
    }

    private func refreshStatisticsTable() {
        let presentation = presentationProvider.makePresentation(
            records: snapshot.records(for: selectedScope),
            visiblePlayerCount: selectedScope.visiblePlayerCount,
            playerNames: playersSettings.playerNames
        )
        statisticsTableView.update(presentation: presentation)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
