//
//  FirstPlayerAnnouncementViewController.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import UIKit

final class FirstPlayerAnnouncementViewController: UIViewController {
    private enum Layout {
        static let modalMaxWidthFactor: CGFloat = 0.74
        static let modalMinWidth: CGFloat = 360
        static let containerTopInset: CGFloat = 22
        static let horizontalInset: CGFloat = 20
        static let buttonTopInset: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let containerBottomInset: CGFloat = 18
    }

    private let firstPlayerName: String

    init(firstPlayerName: String) {
        self.firstPlayerName = firstPlayerName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        isModalInPresentation = true
        view.backgroundColor = PanelAppearance.overlayBackgroundColor

        let containerView = PanelContainerView(surfaceColor: PanelAppearance.overlaySurfaceColor)
        view.addSubview(containerView)

        let headerView = PanelHeaderView(
            title: "Первый по списку",
            subtitle: firstPlayerName,
            alignment: .center,
            titleFont: PanelTypography.modalTitle,
            subtitleFont: PanelTypography.emphasis
        )
        containerView.addSubview(headerView)

        let confirmButton = PrimaryPanelButton(title: "ОК")
        confirmButton.addAction(
            UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            },
            for: .touchUpInside
        )
        containerView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: Layout.modalMaxWidthFactor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: Layout.modalMinWidth),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.containerTopInset),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),

            confirmButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Layout.buttonTopInset),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),
            confirmButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.containerBottomInset)
        ])
    }
}
