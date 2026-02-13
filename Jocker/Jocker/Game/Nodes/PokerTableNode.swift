//
//  PokerTableNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import SpriteKit
import UIKit

/// Визуальное представление покерного стола
///
/// Инкапсулирует создание карточного стола в стиле примера:
/// тёмный борт (rail), зелёное сукно с лёгкой текстурой, внутренние контуры
/// и слоты под карты в центре.
/// Извлечён из `GameScene` для соблюдения Single Responsibility Principle.
final class PokerTableNode: SKNode {
    
    // MARK: - Properties
    
    /// Размеры стола (для расчёта позиций игроков снаружи)
    let tableWidth: CGFloat
    let tableHeight: CGFloat
    
    private let railNode: SKShapeNode
    private let feltNode: SKShapeNode
    
    private static let feltPatternTexture: SKTexture = {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            
            context.setFillColor(UIColor(white: 1.0, alpha: 1.0).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            // Диагональная "ткань" — мягкий паттерн, который затем тонируется цветом сукна.
            context.setStrokeColor(UIColor(white: 0.72, alpha: 0.20).cgColor)
            context.setLineWidth(1.6)
            let step: CGFloat = 18
            
            for offset in stride(from: -size.height, through: size.width + size.height, by: step) {
                context.move(to: CGPoint(x: offset, y: 0))
                context.addLine(to: CGPoint(x: offset - size.height, y: size.height))
            }
            context.strokePath()
            
            context.setStrokeColor(UIColor(white: 0.72, alpha: 0.14).cgColor)
            context.setLineWidth(1.2)
            for offset in stride(from: -size.height, through: size.width + size.height, by: step) {
                context.move(to: CGPoint(x: offset, y: 0))
                context.addLine(to: CGPoint(x: offset + size.height, y: size.height))
            }
            context.strokePath()
            
            // Шум/ворс сукна
            context.setFillColor(UIColor(white: 0.55, alpha: 0.09).cgColor)
            for _ in 0..<900 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let radius = CGFloat.random(in: 0.6...1.8)
                context.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
            }
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }()
    
    // MARK: - Initialization
    
    /// Создать покерный стол
    /// - Parameters:
    ///   - sceneSize: размер сцены (для расчёта пропорций)
    ///   - widthRatio: доля ширины сцены (по умолчанию 0.70)
    ///   - heightRatio: доля высоты сцены (по умолчанию 0.70)
    init(sceneSize: CGSize, widthRatio: CGFloat = 0.70, heightRatio: CGFloat = 0.70) {
        tableWidth = sceneSize.width * widthRatio
        tableHeight = sceneSize.height * heightRatio
        
        let outerSize = CGSize(width: tableWidth, height: tableHeight)
        let rimThickness = max(22, min(min(outerSize.width, outerSize.height) * 0.06, 44))
        
        let outerRect = CGRect(
            x: -outerSize.width / 2,
            y: -outerSize.height / 2,
            width: outerSize.width,
            height: outerSize.height
        )
        let outerCornerRadius = min(outerSize.height * 0.48, outerSize.width * 0.28)
        let outerPath = CGPath(
            roundedRect: outerRect,
            cornerWidth: outerCornerRadius,
            cornerHeight: outerCornerRadius,
            transform: nil
        )
        
        let feltRect = outerRect.insetBy(dx: rimThickness, dy: rimThickness)
        let feltCornerRadius = max(12, outerCornerRadius - rimThickness)
        let feltPath = CGPath(
            roundedRect: feltRect,
            cornerWidth: feltCornerRadius,
            cornerHeight: feltCornerRadius,
            transform: nil
        )
        
        // Борт (rail)
        railNode = SKShapeNode(path: outerPath)
        railNode.fillColor = GameColors.tableBorder
        railNode.strokeColor = GameColors.tableBorderStroke
        railNode.lineWidth = 4
        railNode.zPosition = 1
        
        // Сукно (felt)
        feltNode = SKShapeNode(path: feltPath)
        feltNode.fillColor = GameColors.tableFelt
        feltNode.fillTexture = Self.feltPatternTexture
        feltNode.strokeColor = GameColors.tableFeltStroke.withAlphaComponent(0.32)
        feltNode.lineWidth = 2
        feltNode.zPosition = 3
        
        super.init()
        
        // Тень под столом
        let shadowNode = SKShapeNode(path: outerPath)
        shadowNode.fillColor = .black
        shadowNode.strokeColor = .clear
        shadowNode.alpha = 0.34
        shadowNode.position = CGPoint(x: 0, y: -12)
        shadowNode.zPosition = 0
        addChild(shadowNode)
        
        addChild(railNode)
        
        // Лёгкий блик по борту
        let railHighlight = SKShapeNode(path: outerPath)
        railHighlight.fillColor = .clear
        railHighlight.strokeColor = SKColor(white: 1.0, alpha: 0.08)
        railHighlight.lineWidth = 2
        railHighlight.zPosition = 2
        addChild(railHighlight)
        
        addChild(feltNode)
        
        // Внутренний контур сукна
        let innerBorderInset = max(18, min(min(feltRect.width, feltRect.height) * 0.06, 36))
        let innerBorderRect = feltRect.insetBy(dx: innerBorderInset, dy: innerBorderInset)
        let innerBorderCornerRadius = max(10, feltCornerRadius - innerBorderInset)
        let innerBorderPath = CGPath(
            roundedRect: innerBorderRect,
            cornerWidth: innerBorderCornerRadius,
            cornerHeight: innerBorderCornerRadius,
            transform: nil
        )
        
        let innerBorderNode = SKShapeNode(path: innerBorderPath)
        innerBorderNode.fillColor = .clear
        innerBorderNode.strokeColor = GameColors.tableFeltStroke.withAlphaComponent(0.22)
        innerBorderNode.lineWidth = 3
        innerBorderNode.zPosition = 4
        addChild(innerBorderNode)
        
        addCenterCardSlots(feltRect: feltRect, zPosition: 5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func addCenterCardSlots(feltRect: CGRect, zPosition: CGFloat) {
        let containerNode = SKNode()
        containerNode.zPosition = zPosition
        
        let slotCount = 5
        let maxSlotsWidth = feltRect.width * 0.68
        
        var slotHeight = min(feltRect.height * 0.20, 150)
        var slotWidth = slotHeight * 0.666
        var slotSpacing = slotWidth * 0.20
        
        var totalSlotsWidth = CGFloat(slotCount) * slotWidth + CGFloat(slotCount - 1) * slotSpacing
        if totalSlotsWidth > maxSlotsWidth {
            let scale = maxSlotsWidth / max(1, totalSlotsWidth)
            slotHeight *= scale
            slotWidth *= scale
            slotSpacing *= scale
            totalSlotsWidth = maxSlotsWidth
        }
        
        // Общий контур зоны под карты
        let containerPaddingX = slotWidth * 0.28
        let containerPaddingY = slotHeight * 0.28
        let containerRect = CGRect(
            x: -totalSlotsWidth / 2 - containerPaddingX,
            y: -slotHeight / 2 - containerPaddingY,
            width: totalSlotsWidth + containerPaddingX * 2,
            height: slotHeight + containerPaddingY * 2
        )
        let containerPath = CGPath(
            roundedRect: containerRect,
            cornerWidth: 22,
            cornerHeight: 22,
            transform: nil
        )
        
        let outlineNode = SKShapeNode(path: containerPath)
        outlineNode.fillColor = .clear
        outlineNode.strokeColor = GameColors.tableFeltStroke.withAlphaComponent(0.16)
        outlineNode.lineWidth = 2
        outlineNode.zPosition = -1
        containerNode.addChild(outlineNode)
        
        let startX = -totalSlotsWidth / 2 + slotWidth / 2
        let slotRect = CGRect(x: -slotWidth / 2, y: -slotHeight / 2, width: slotWidth, height: slotHeight)
        let slotPath = CGPath(roundedRect: slotRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        
        for index in 0..<slotCount {
            let slotNode = SKShapeNode(path: slotPath)
            slotNode.fillColor = .clear
            slotNode.strokeColor = GameColors.tableFeltStroke.withAlphaComponent(0.20)
            slotNode.lineWidth = 2
            slotNode.position = CGPoint(x: startX + CGFloat(index) * (slotWidth + slotSpacing), y: 0)
            slotNode.zPosition = CGFloat(index)
            containerNode.addChild(slotNode)
        }
        
        addChild(containerNode)
    }
}
