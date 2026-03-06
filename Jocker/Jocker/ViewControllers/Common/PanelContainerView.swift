//
//  PanelContainerView.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class PanelContainerView: UIView {
    init(surfaceColor: UIColor = PanelAppearance.screenSurfaceColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = surfaceColor
        layer.cornerRadius = PanelAppearance.panelCornerRadius
        layer.borderWidth = PanelAppearance.borderWidth
        layer.borderColor = PanelAppearance.borderColor.cgColor
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
