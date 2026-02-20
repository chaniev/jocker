//
//  DealHistoryViewController.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import UIKit

final class DealHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    private enum Appearance {
        static let background = UIColor.white
        static let titleColor = UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 1.0)
        static let subtitleColor = UIColor(red: 0.35, green: 0.42, blue: 0.52, alpha: 1.0)
        static let accentColor = UIColor(red: 0.20, green: 0.31, blue: 0.50, alpha: 0.95)
    }

    private let dealHistory: DealHistory
    private let playerNames: [String]
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()

    init(dealHistory: DealHistory, playerNames: [String]) {
        self.dealHistory = dealHistory
        self.playerNames = playerNames
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Appearance.background
        setupHeader()
        setupTableView()
        setupEmptyState()
        setupDismissControls()
        updateEmptyStateVisibility()
    }

    private func setupHeader() {
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = Appearance.accentColor
        closeButton.layer.cornerRadius = 10
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textColor = Appearance.titleColor
        titleLabel.textAlignment = .left
        titleLabel.text = "Раздача \(dealHistory.key.roundIndex + 1), блок \(dealHistory.key.blockIndex + 1)"
        view.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        subtitleLabel.textColor = Appearance.subtitleColor
        subtitleLabel.textAlignment = .left
        subtitleLabel.text = trumpDisplayText()
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MoveCell")
        tableView.rowHeight = 52
        tableView.estimatedRowHeight = 52
        tableView.backgroundColor = Appearance.background
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 20)
        emptyStateLabel.textColor = Appearance.subtitleColor
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.text = "По этой раздаче пока нет сыгранных взяток."
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func setupDismissControls() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleCloseTapped))
        swipe.direction = .right
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }

    private func updateEmptyStateVisibility() {
        let isEmpty = dealHistory.tricks.isEmpty
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
        return dealHistory.tricks.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard dealHistory.tricks.indices.contains(section) else { return 0 }
        return dealHistory.tricks[section].moves.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MoveCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17)
        cell.textLabel?.numberOfLines = 1

        guard dealHistory.tricks.indices.contains(indexPath.section) else {
            cell.textLabel?.text = ""
            return cell
        }

        let trick = dealHistory.tricks[indexPath.section]
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
        guard dealHistory.tricks.indices.contains(section) else { return nil }
        let trick = dealHistory.tricks[section]
        let winnerName = playerDisplayName(at: trick.winnerPlayerIndex)
        return "Взятка \(section + 1) • Забрал: \(winnerName)"
    }

    // MARK: - Actions

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
