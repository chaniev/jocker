//
//  PanelHeaderView.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class PanelHeaderView: UIView {
    enum Alignment {
        case left
        case center

        fileprivate var textAlignment: NSTextAlignment {
            switch self {
            case .left:
                return .left
            case .center:
                return .center
            }
        }
    }

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    private let stackView = UIStackView()

    init(
        title: String,
        subtitle: String? = nil,
        alignment: Alignment = .center,
        titleFont: UIFont = PanelTypography.modalTitle,
        subtitleFont: UIFont = PanelTypography.modalSubtitle,
        titleColor: UIColor = PanelAppearance.primaryTextColor,
        subtitleColor: UIColor = PanelAppearance.secondaryTextColor,
        spacing: CGFloat = 6
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = spacing
        addSubview(stackView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = alignment.textAlignment
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        stackView.addArrangedSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = subtitleFont
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.textAlignment = alignment.textAlignment
        subtitleLabel.numberOfLines = 0
        stackView.addArrangedSubview(subtitleLabel)

        setSubtitle(subtitle)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setSubtitle(_ subtitle: String?) {
        let resolvedSubtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = resolvedSubtitle
        subtitleLabel.isHidden = resolvedSubtitle?.isEmpty ?? true
    }
}
