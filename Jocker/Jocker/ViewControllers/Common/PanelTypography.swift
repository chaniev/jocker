//
//  PanelTypography.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

enum PanelTypography {
    static let screenTitle = font(name: "AvenirNext-Bold", size: 30, fallbackWeight: .bold)
    static let resultsTitle = font(name: "AvenirNext-Bold", size: 28, fallbackWeight: .bold)
    static let modalTitle = font(name: "AvenirNext-Bold", size: 24, fallbackWeight: .bold)
    static let emphasis = font(name: "AvenirNext-DemiBold", size: 22, fallbackWeight: .semibold)
    static let sectionTitle = font(name: "AvenirNext-DemiBold", size: 18, fallbackWeight: .semibold)
    static let screenSubtitle = font(name: "AvenirNext-Medium", size: 16, fallbackWeight: .medium)
    static let modalSubtitle = font(name: "AvenirNext-Medium", size: 14, fallbackWeight: .medium)
    static let body = font(name: "AvenirNext-Medium", size: 15, fallbackWeight: .medium)
    static let bodyLarge = font(name: "AvenirNext-Medium", size: 18, fallbackWeight: .medium)
    static let caption = font(name: "AvenirNext-Medium", size: 12, fallbackWeight: .medium)
    static let captionStrong = font(name: "AvenirNext-DemiBold", size: 14, fallbackWeight: .semibold)
    static let compactLabel = font(name: "AvenirNext-DemiBold", size: 17, fallbackWeight: .semibold)
    static let primaryButton = font(name: "AvenirNext-Bold", size: 20, fallbackWeight: .bold)
    static let secondaryButton = font(name: "AvenirNext-DemiBold", size: 18, fallbackWeight: .semibold)
    static let headerCell = font(name: "AvenirNext-Bold", size: 14, fallbackWeight: .bold)
    static let cell = font(name: "AvenirNext-Medium", size: 12, fallbackWeight: .medium)
    static let summaryCell = font(name: "AvenirNext-DemiBold", size: 12, fallbackWeight: .semibold)

    private static func font(
        name: String,
        size: CGFloat,
        fallbackWeight: UIFont.Weight
    ) -> UIFont {
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallbackWeight)
    }
}
