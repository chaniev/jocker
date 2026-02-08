//
//  ScoreTableView.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

final class ScoreTableView: UIView {
    
    private enum RowKind: Equatable {
        case deal(cards: Int)
        case subtotal
        case cumulative
    }
    
    private struct Layout {
        let rows: [RowKind]
        let blockEndRowIndices: [Int]
    }
    
    private let playerCount: Int
    private let layout: Layout
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let thinGridLayer = CAShapeLayer()
    private let thickGridLayer = CAShapeLayer()
    
    private var leftColumnWidth: CGFloat = 36
    private var trickColumnWidth: CGFloat = 24
    private var pointsColumnWidth: CGFloat = 64
    private let headerHeight: CGFloat = 28
    private let rowHeight: CGFloat = 24
    
    init(playerCount: Int) {
        self.playerCount = playerCount
        self.layout = ScoreTableView.buildLayout(playerCount: playerCount)
        super.init(frame: .zero)
        setupView()
        buildLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateColumnWidths()
        layoutScrollView()
        rebuildLabels()
        updateGridLayers()
    }
    
    private func setupView() {
        backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        contentView.backgroundColor = .white
        scrollView.addSubview(contentView)
        
        thinGridLayer.fillColor = UIColor.clear.cgColor
        thinGridLayer.strokeColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        thinGridLayer.lineWidth = 0.5
        
        thickGridLayer.fillColor = UIColor.clear.cgColor
        thickGridLayer.strokeColor = UIColor(white: 0.45, alpha: 1.0).cgColor
        thickGridLayer.lineWidth = 2.0
        
        contentView.layer.addSublayer(thinGridLayer)
        contentView.layer.addSublayer(thickGridLayer)
    }
    
    private func layoutScrollView() {
        let contentWidth = leftColumnWidth + CGFloat(playerCount) * (trickColumnWidth + pointsColumnWidth)
        let contentHeight = headerHeight + CGFloat(layout.rows.count) * rowHeight
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = contentView.bounds.size
    }
    
    private func rebuildLabels() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        buildLabels()
    }
    
    private func buildLabels() {
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let cellFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let summaryFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        
        for playerIndex in 0..<playerCount {
            let headerLabel = UILabel()
            headerLabel.text = "Игрок \(playerIndex + 1)"
            headerLabel.font = headerFont
            headerLabel.textAlignment = .center
            headerLabel.textColor = .black
            headerLabel.frame = CGRect(
                x: leftColumnWidth + CGFloat(playerIndex) * (trickColumnWidth + pointsColumnWidth),
                y: 0,
                width: trickColumnWidth + pointsColumnWidth,
                height: headerHeight
            )
            contentView.addSubview(headerLabel)
        }
        
        for (rowIndex, rowKind) in layout.rows.enumerated() {
            let rowY = headerHeight + CGFloat(rowIndex) * rowHeight
            let isSummary = rowKind == .subtotal || rowKind == .cumulative
            
            let cardsLabel = UILabel()
            cardsLabel.font = cellFont
            cardsLabel.textAlignment = .center
            cardsLabel.textColor = .black
            cardsLabel.frame = CGRect(x: 0, y: rowY, width: leftColumnWidth, height: rowHeight)
            if case let .deal(cards) = rowKind {
                cardsLabel.text = "\(cards)"
            } else {
                cardsLabel.text = ""
            }
            contentView.addSubview(cardsLabel)
            
            for playerIndex in 0..<playerCount {
                let baseX = leftColumnWidth + CGFloat(playerIndex) * (trickColumnWidth + pointsColumnWidth)
                
                let tricksLabel = UILabel()
                tricksLabel.font = cellFont
                tricksLabel.textAlignment = .center
                tricksLabel.textColor = .black
                tricksLabel.frame = CGRect(x: baseX, y: rowY, width: trickColumnWidth, height: rowHeight)
                tricksLabel.text = ""
                contentView.addSubview(tricksLabel)
                
                let pointsLabel = UILabel()
                pointsLabel.font = isSummary ? summaryFont : cellFont
                pointsLabel.textAlignment = .right
                pointsLabel.textColor = .black
                pointsLabel.frame = CGRect(
                    x: baseX + trickColumnWidth,
                    y: rowY,
                    width: pointsColumnWidth - 4,
                    height: rowHeight
                )
                pointsLabel.text = ""
                contentView.addSubview(pointsLabel)
            }
        }
    }
    
    private func updateGridLayers() {
        let contentWidth = contentView.bounds.width
        let contentHeight = contentView.bounds.height
        
        let columnWidths: [CGFloat] = {
            var widths = [leftColumnWidth]
            for _ in 0..<playerCount {
                widths.append(trickColumnWidth)
                widths.append(pointsColumnWidth)
            }
            return widths
        }()
        
        var xPositions: [CGFloat] = [0]
        for width in columnWidths {
            xPositions.append(xPositions.last! + width)
        }
        
        var yPositions: [CGFloat] = [0, headerHeight]
        for rowIndex in 0..<layout.rows.count {
            let y = headerHeight + CGFloat(rowIndex + 1) * rowHeight
            yPositions.append(y)
        }
        
        let thinPath = UIBezierPath()
        for x in xPositions {
            thinPath.move(to: CGPoint(x: x, y: 0))
            thinPath.addLine(to: CGPoint(x: x, y: contentHeight))
        }
        for y in yPositions {
            thinPath.move(to: CGPoint(x: 0, y: y))
            thinPath.addLine(to: CGPoint(x: contentWidth, y: y))
        }
        thinGridLayer.path = thinPath.cgPath
        
        let thickPath = UIBezierPath()
        
        for blockEndIndex in layout.blockEndRowIndices.dropLast() {
            let y = headerHeight + CGFloat(blockEndIndex + 1) * rowHeight
            thickPath.move(to: CGPoint(x: 0, y: y))
            thickPath.addLine(to: CGPoint(x: contentWidth, y: y))
        }
        
        for playerIndex in 0..<playerCount {
            let x = leftColumnWidth + CGFloat(playerIndex + 1) * (trickColumnWidth + pointsColumnWidth)
            thickPath.move(to: CGPoint(x: x, y: 0))
            thickPath.addLine(to: CGPoint(x: x, y: contentHeight))
        }
        
        thickGridLayer.path = thickPath.cgPath
    }
    
    private func updateColumnWidths() {
        let minLeft: CGFloat = 36
        let minTricks: CGFloat = 24
        let minPoints: CGFloat = 64
        
        let availableWidth = max(bounds.width, 1)
        let minTotal = minLeft + CGFloat(playerCount) * (minTricks + minPoints)
        
        if availableWidth <= minTotal {
            leftColumnWidth = minLeft
            trickColumnWidth = minTricks
            pointsColumnWidth = minPoints
            return
        }
        
        leftColumnWidth = minLeft
        trickColumnWidth = minTricks
        let extra = availableWidth - (leftColumnWidth + CGFloat(playerCount) * trickColumnWidth)
        pointsColumnWidth = extra / CGFloat(playerCount)
    }
    
    private static func buildLayout(playerCount: Int) -> Layout {
        let blockDeals: [[Int]]
        
        if playerCount == 3 {
            blockDeals = [
                Array(1...11),
                Array(repeating: 12, count: 3),
                Array((1...11).reversed()),
                Array(repeating: 12, count: 3)
            ]
        } else {
            blockDeals = [
                Array(1...8),
                Array(repeating: 9, count: 4),
                Array((1...8).reversed()),
                Array(repeating: 9, count: 4)
            ]
        }
        
        var rows: [RowKind] = []
        var blockEndRowIndices: [Int] = []
        
        for blockIndex in 0..<blockDeals.count {
            for cards in blockDeals[blockIndex] {
                rows.append(.deal(cards: cards))
            }
            
            rows.append(.subtotal)
            if blockIndex >= 1 {
                rows.append(.cumulative)
            }
            
            blockEndRowIndices.append(rows.count - 1)
        }
        
        return Layout(rows: rows, blockEndRowIndices: blockEndRowIndices)
    }
}
