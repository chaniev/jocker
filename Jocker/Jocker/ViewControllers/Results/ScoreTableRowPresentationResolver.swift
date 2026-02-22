//
//  ScoreTableRowPresentationResolver.swift
//  Jocker
//
//  Created by Codex on 22.02.2026.
//

import Foundation

struct ScoreTableRowPresentationResolver {
    enum PointsLabelStyle: Equatable {
        case regular
        case summary
    }

    func cardsLabelText(for rowKind: ScoreTableView.RowKind) -> String {
        if case let .deal(cards) = rowKind {
            return "\(cards)"
        }
        return ""
    }

    func pointsLabelStyle(for rowKind: ScoreTableView.RowKind) -> PointsLabelStyle {
        switch rowKind {
        case .deal:
            return .regular
        case .subtotal, .cumulative:
            return .summary
        }
    }
}
