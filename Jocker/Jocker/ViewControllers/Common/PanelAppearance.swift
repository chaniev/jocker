//
//  PanelAppearance.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

enum PanelAppearance {
    static let screenBackgroundColor = UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1.0)
    static let overlayBackgroundColor = GameColors.sceneBackground.withAlphaComponent(0.62)
    static let resultsOverlayColor = GameColors.sceneBackground.withAlphaComponent(0.72)

    static let screenSurfaceColor = UIColor(red: 0.14, green: 0.18, blue: 0.27, alpha: 1.0)
    static let overlaySurfaceColor = UIColor(red: 0.15, green: 0.21, blue: 0.32, alpha: 0.98)
    static let resultsSurfaceColor = UIColor(red: 0.12, green: 0.17, blue: 0.27, alpha: 0.97)

    static let borderColor = GameColors.goldTranslucent
    static let primaryTextColor = GameColors.textPrimary
    static let secondaryTextColor = GameColors.textSecondary
    static let goldTextColor = GameColors.gold

    static let accentColor = GameColors.buttonFill
    static let accentBorderColor = GameColors.buttonStroke
    static let accentTextColor = GameColors.buttonText

    static let secondaryButtonBackgroundColor = UIColor(red: 0.20, green: 0.30, blue: 0.46, alpha: 0.55)
    static let secondaryButtonBorderColor = UIColor(red: 0.30, green: 0.41, blue: 0.60, alpha: 0.56)
    static let neutralButtonBackgroundColor = UIColor(red: 0.31, green: 0.36, blue: 0.45, alpha: 1.0)
    static let neutralButtonBorderColor = UIColor(red: 0.22, green: 0.27, blue: 0.35, alpha: 1.0)

    static let panelCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
}
