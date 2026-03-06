//
//  PrimaryPanelButton.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class PrimaryPanelButton: UIButton {
    init(
        title: String,
        font: UIFont = PanelTypography.primaryButton
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        titleLabel?.font = font
        setTitleColor(PanelAppearance.accentTextColor, for: .normal)
        backgroundColor = PanelAppearance.accentColor
        layer.cornerRadius = PanelAppearance.buttonCornerRadius
        layer.borderWidth = PanelAppearance.borderWidth
        layer.borderColor = PanelAppearance.accentBorderColor.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
