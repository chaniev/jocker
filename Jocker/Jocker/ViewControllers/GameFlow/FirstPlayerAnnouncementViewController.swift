//
//  FirstPlayerAnnouncementViewController.swift
//  Jocker
//
//  Created by Codex on 04.03.2026.
//

import UIKit

final class FirstPlayerAnnouncementViewController: UIViewController {
    private enum Appearance {
        static let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.62)
        static let surfaceColor = UIColor(red: 0.15, green: 0.21, blue: 0.32, alpha: 0.98)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let subtitleColor = GameColors.textSecondary
        static let accentColor = GameColors.buttonFill
        static let accentBorderColor = GameColors.buttonStroke
        static let accentTextColor = GameColors.buttonText
    }

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let modalMaxWidthFactor: CGFloat = 0.74
        static let modalMinWidth: CGFloat = 360
        static let containerTopInset: CGFloat = 22
        static let horizontalInset: CGFloat = 20
        static let labelsSpacing: CGFloat = 12
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
        view.backgroundColor = Appearance.overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.surfaceColor
        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.borderWidth = Layout.borderWidth
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Первый по списку"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textColor = Appearance.titleColor
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = firstPlayerName
        nameLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 22)
        nameLabel.textColor = Appearance.subtitleColor
        nameLabel.textAlignment = .center
        containerView.addSubview(nameLabel)

        let confirmButton = UIButton(type: .system)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("ОК", for: .normal)
        confirmButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        confirmButton.setTitleColor(Appearance.accentTextColor, for: .normal)
        confirmButton.backgroundColor = Appearance.accentColor
        confirmButton.layer.cornerRadius = Layout.buttonCornerRadius
        confirmButton.layer.borderWidth = Layout.borderWidth
        confirmButton.layer.borderColor = Appearance.accentBorderColor.cgColor
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

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.containerTopInset),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),

            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.labelsSpacing),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),

            confirmButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Layout.buttonTopInset),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),
            confirmButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.containerBottomInset)
        ])
    }
}
