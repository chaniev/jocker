//
//  GameStatisticsViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class GameStatisticsViewController: UIViewController {
    private enum Appearance {
        static let backgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1.0)
        static let panelColor = UIColor(red: 0.14, green: 0.18, blue: 0.27, alpha: 1.0)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let subtitleColor = GameColors.textSecondary
        static let buttonColor = GameColors.buttonFill
        static let buttonTextColor = GameColors.buttonText
        static let segmentedTint = UIColor(red: 0.20, green: 0.30, blue: 0.46, alpha: 1.0)
    }

    private let statisticsStore: GameStatisticsStore
    private var snapshot: GameStatisticsSnapshot
    private var selectedScope: GameStatisticsScope = .allGames

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scopeSegmentedControl = UISegmentedControl(items: GameStatisticsScope.allCases.map(\.title))
    private let statisticsTableView = GameStatisticsTableView()
    private let closeButton = UIButton(type: .system)

    init(statisticsStore: GameStatisticsStore = UserDefaultsGameStatisticsStore()) {
        self.statisticsStore = statisticsStore
        self.snapshot = statisticsStore.loadSnapshot()
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
        refreshStatisticsTable()
    }

    private func setupView() {
        view.backgroundColor = Appearance.backgroundColor

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.panelColor
        containerView.layer.cornerRadius = 16
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
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Статистика игр"
        titleLabel.textColor = Appearance.titleColor
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30)
        titleLabel.textAlignment = .left
        containerView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Таблица метрик по всем игрокам"
        subtitleLabel.textColor = Appearance.subtitleColor
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16)
        subtitleLabel.textAlignment = .left
        containerView.addSubview(subtitleLabel)

        scopeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        scopeSegmentedControl.selectedSegmentIndex = 0
        scopeSegmentedControl.backgroundColor = Appearance.segmentedTint.withAlphaComponent(0.55)
        scopeSegmentedControl.selectedSegmentTintColor = Appearance.segmentedTint
        scopeSegmentedControl.setTitleTextAttributes([
            .font: UIFont(name: "AvenirNext-DemiBold", size: 15) as Any,
            .foregroundColor: GameColors.textPrimary
        ], for: .selected)
        scopeSegmentedControl.setTitleTextAttributes([
            .font: UIFont(name: "AvenirNext-Medium", size: 14) as Any,
            .foregroundColor: Appearance.subtitleColor
        ], for: .normal)
        scopeSegmentedControl.addTarget(self, action: #selector(handleScopeChanged), for: .valueChanged)
        containerView.addSubview(scopeSegmentedControl)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scopeSegmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
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
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Назад", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        closeButton.setTitleColor(Appearance.buttonTextColor, for: .normal)
        closeButton.backgroundColor = Appearance.buttonColor
        closeButton.layer.cornerRadius = 12
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = GameColors.buttonStroke.cgColor
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
        statisticsTableView.update(
            records: displayedRecords,
            visiblePlayerCount: selectedScope.visiblePlayerCount
        )
    }

    private var displayedRecords: [GameStatisticsPlayerRecord] {
        let records = snapshot.records(for: selectedScope)
            .sorted { $0.playerIndex < $1.playerIndex }
        let visibleCount = selectedScope.visiblePlayerCount

        if records.count >= visibleCount {
            return Array(records.prefix(visibleCount))
        }

        var filled = records
        let missingStart = records.count
        for index in missingStart..<visibleCount {
            filled.append(GameStatisticsPlayerRecord.empty(playerIndex: index))
        }
        return filled
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
