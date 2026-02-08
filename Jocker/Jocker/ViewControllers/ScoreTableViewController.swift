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
    
    init(scoreManager: ScoreManager) {
        self.scoreManager = scoreManager
        self.tableView = ScoreTableView(playerCount: scoreManager.playerCount)
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
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
