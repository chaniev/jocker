//
//  SecondaryPanelButton.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class SecondaryPanelButton: UIButton {
    enum Style {
        case toned
        case neutral
    }

    init(
        title: String,
        style: Style = .toned,
        font: UIFont = PanelTypography.secondaryButton
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        titleLabel?.font = font
        setTitleColor(PanelAppearance.primaryTextColor, for: .normal)
        layer.cornerRadius = PanelAppearance.buttonCornerRadius
        layer.borderWidth = PanelAppearance.borderWidth

        switch style {
        case .toned:
            backgroundColor = PanelAppearance.secondaryButtonBackgroundColor
            layer.borderColor = PanelAppearance.secondaryButtonBorderColor.cgColor
        case .neutral:
            backgroundColor = PanelAppearance.neutralButtonBackgroundColor
            layer.borderColor = PanelAppearance.neutralButtonBorderColor.cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
