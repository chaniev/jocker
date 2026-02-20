//
//  ScoreTableViewController.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

final class ScoreTableViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let tableView: ScoreTableView
    private let scoreManager: ScoreManager
    private let currentBlockIndex: Int
    private let currentRoundIndex: Int
    private let focusOnBlockSummary: Bool
    private var didApplyInitialDealScroll = false
    var onDealSelected: ((Int, Int) -> Void)?
    
    init(
        scoreManager: ScoreManager,
        firstColumnPlayerIndex: Int = 0,
        playerNames: [String] = [],
        currentBlockIndex: Int = 0,
        currentRoundIndex: Int = 0,
        focusOnBlockSummary: Bool = false
    ) {
        self.scoreManager = scoreManager
        self.currentBlockIndex = currentBlockIndex
        self.currentRoundIndex = currentRoundIndex
        self.focusOnBlockSummary = focusOnBlockSummary
        self.tableView = ScoreTableView(
            playerCount: scoreManager.playerCount,
            displayStartPlayerIndex: firstColumnPlayerIndex,
            playerNames: playerNames
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupTableView()
        setupSwipeToDismiss()
        tableView.update(with: scoreManager)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.update(with: scoreManager)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyInitialDealScrollIfNeeded()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.onDealRowTapped = { [weak self] blockIndex, roundIndex in
            self?.onDealSelected?(blockIndex, roundIndex)
        }
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupSwipeToDismiss() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeBack))
        swipe.direction = .right
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }

    private func applyInitialDealScrollIfNeeded() {
        guard !didApplyInitialDealScroll else { return }
        guard tableView.bounds.height > 0 else { return }

        if focusOnBlockSummary {
            tableView.scrollToBlockSummary(blockIndex: currentBlockIndex, animated: false)
        } else {
            tableView.scrollToDeal(
                blockIndex: currentBlockIndex,
                roundIndex: currentRoundIndex,
                animated: false
            )
        }
        didApplyInitialDealScroll = true
    }
    
    @objc private func handleSwipeBack() {
        dismiss(animated: true, completion: nil)
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
