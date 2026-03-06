//
//  GameSceneLayoutResolver.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import CoreGraphics
import UIKit

/// Pure geometry/layout helper for `GameScene`.
struct GameSceneLayoutResolver {
    enum Metrics {
        static let roundBidInfoFontScale: CGFloat = 1.1
        static let actionButtonSize = CGSize(width: 300, height: 86)
        static let actionButtonHorizontalInset: CGFloat = 34
        static let actionButtonBottomInset: CGFloat = 24
        static let roundBidInfoWidth: CGFloat = 300
        static let roundBidInfoTopSpacing: CGFloat = 14
        static let roundBidInfoVerticalPadding: CGFloat = 12
        static let roundBidInfoTitleHeight: CGFloat = 24 * roundBidInfoFontScale
        static let roundBidInfoRowHeight: CGFloat = 26 * roundBidInfoFontScale
        static let roundBidInfoRowSpacing: CGFloat = 6
        static let roundBidInfoTitleToRowsSpacing: CGFloat = 10
        static let roundBidInfoTitleFontSize: CGFloat = 21 * roundBidInfoFontScale
        static let roundBidInfoRowFontSize: CGFloat = 20 * roundBidInfoFontScale
        static let gameInfoTopInset: CGFloat = 34
        static let trickCenterYOffset: CGFloat = 20
        static let trumpIndicatorInset: CGFloat = 116
        static let jokerLeadInfoSize = CGSize(width: 264, height: 156)
        static let jokerLeadInfoHorizontalMargin: CGFloat = 18
        static let jokerLeadInfoTopInset: CGFloat = 22
    }

    let sceneSize: CGSize
    let safeAreaInsets: UIEdgeInsets

    func sceneCenter() -> CGPoint {
        CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
    }

    func pokerTablePosition() -> CGPoint {
        sceneCenter()
    }

    func playerSeatPositions(
        playerCount: Int,
        tableWidth: CGFloat,
        tableHeight: CGFloat
    ) -> [CGPoint] {
        guard playerCount > 0 else { return [] }

        let center = sceneCenter()
        let minX = safeAreaInsets.left + 170
        let maxX = sceneSize.width - safeAreaInsets.right - 170
        let minY = safeAreaInsets.bottom + 145
        let maxY = sceneSize.height - safeAreaInsets.top - 195

        let verticalOffset = min(tableHeight / 2 + 20, (maxY - minY) / 2)
        let topY = min(maxY, center.y + verticalOffset)
        let bottomY = max(minY, center.y - verticalOffset)

        return wideSideSeatPositions(
            count: playerCount,
            centerX: center.x,
            minX: minX,
            maxX: maxX,
            topY: topY,
            bottomY: bottomY,
            tableWidth: tableWidth
        )
    }

    func firstDealerSelectionDeckPosition() -> CGPoint {
        CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 164)
    }

    func firstDealerSelectionTableCardPosition() -> CGPoint {
        CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 28)
    }

    func firstDealerAnnouncementPosition() -> CGPoint {
        sceneCenter()
    }

    func gameInfoLabelPosition() -> CGPoint {
        CGPoint(
            x: sceneSize.width / 2,
            y: sceneSize.height - safeAreaInsets.top - Metrics.gameInfoTopInset
        )
    }

    func scoreButtonPosition() -> CGPoint {
        CGPoint(
            x: actionButtonX(),
            y: sceneSize.height - safeAreaInsets.top - Metrics.actionButtonBottomInset - Metrics.actionButtonSize.height / 2
        )
    }

    func dealButtonPosition() -> CGPoint {
        CGPoint(
            x: actionButtonX(),
            y: safeAreaInsets.bottom + Metrics.actionButtonBottomInset + Metrics.actionButtonSize.height / 2
        )
    }

    func roundBidInfoSize(playerCount: Int) -> CGSize {
        let rowCount = max(playerCount, 1)
        let rowsHeight = CGFloat(rowCount) * Metrics.roundBidInfoRowHeight +
            CGFloat(max(0, rowCount - 1)) * Metrics.roundBidInfoRowSpacing
        let height = Metrics.roundBidInfoVerticalPadding * 2 +
            Metrics.roundBidInfoTitleHeight +
            Metrics.roundBidInfoTitleToRowsSpacing +
            rowsHeight

        return CGSize(width: Metrics.roundBidInfoWidth, height: height)
    }

    func roundBidInfoPosition(playerCount: Int) -> CGPoint {
        let scorePosition = scoreButtonPosition()
        let panelSize = roundBidInfoSize(playerCount: playerCount)
        let offset = Metrics.actionButtonSize.height / 2 +
            Metrics.roundBidInfoTopSpacing +
            panelSize.height / 2

        return CGPoint(
            x: scorePosition.x,
            y: scorePosition.y - offset
        )
    }

    func trickCenterPosition() -> CGPoint {
        CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + Metrics.trickCenterYOffset)
    }

    func trumpIndicatorPosition() -> CGPoint {
        CGPoint(
            x: sceneSize.width - safeAreaInsets.right - Metrics.trumpIndicatorInset,
            y: safeAreaInsets.bottom + Metrics.trumpIndicatorInset
        )
    }

    func jokerLeadInfoPosition() -> CGPoint {
        let centerY = sceneSize.height
            - safeAreaInsets.top
            - Metrics.jokerLeadInfoTopInset
            - Metrics.jokerLeadInfoSize.height / 2

        return CGPoint(
            x: sceneSize.width
                - safeAreaInsets.right
                - Metrics.jokerLeadInfoHorizontalMargin
                - Metrics.jokerLeadInfoSize.width / 2,
            y: centerY
        )
    }

    private func actionButtonX() -> CGFloat {
        safeAreaInsets.left + Metrics.actionButtonHorizontalInset + Metrics.actionButtonSize.width / 2
    }

    private func wideSideSeatPositions(
        count: Int,
        centerX: CGFloat,
        minX: CGFloat,
        maxX: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        tableWidth: CGFloat
    ) -> [CGPoint] {
        guard count > 0 else { return [] }

        let halfSpan = max(80, min(tableWidth * 0.24, (maxX - minX) / 2 - 24))
        let clampedCenterX = min(max(centerX, minX), maxX)
        let clampX: (CGFloat) -> CGFloat = { x in
            min(max(x, minX), maxX)
        }

        switch count {
        case 3:
            let topXs = symmetricXPositions(count: 2, centerX: clampedCenterX, halfSpan: halfSpan)
            return [
                CGPoint(x: clampedCenterX, y: bottomY),
                CGPoint(x: clampX(topXs[0]), y: topY),
                CGPoint(x: clampX(topXs[1]), y: topY)
            ]
        case 4:
            let sideXs = symmetricXPositions(count: 2, centerX: clampedCenterX, halfSpan: halfSpan)
            return [
                CGPoint(x: clampX(sideXs[0]), y: bottomY),
                CGPoint(x: clampX(sideXs[0]), y: topY),
                CGPoint(x: clampX(sideXs[1]), y: topY),
                CGPoint(x: clampX(sideXs[1]), y: bottomY)
            ]
        default:
            let bottomCount = (count + 1) / 2
            let topCount = count - bottomCount
            let bottomXs = symmetricXPositions(count: bottomCount, centerX: clampedCenterX, halfSpan: halfSpan)
            let topXs = symmetricXPositions(count: topCount, centerX: clampedCenterX, halfSpan: halfSpan)

            return bottomXs.map { CGPoint(x: clampX($0), y: bottomY) } +
                topXs.map { CGPoint(x: clampX($0), y: topY) }
        }
    }

    private func symmetricXPositions(count: Int, centerX: CGFloat, halfSpan: CGFloat) -> [CGFloat] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [centerX] }

        let step = (halfSpan * 2) / CGFloat(count - 1)
        return (0..<count).map { index in
            centerX - halfSpan + CGFloat(index) * step
        }
    }
}
