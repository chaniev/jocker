//
//  PokerTableNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import SpriteKit

/// Визуальное представление покерного стола
///
/// Инкапсулирует создание овального стола с деревянной окантовкой,
/// зелёным сукном, декоративной золотистой границей и текстурой.
/// Извлечён из `GameScene` для соблюдения Single Responsibility Principle.
class PokerTableNode: SKNode {
    
    // MARK: - Properties
    
    /// Размеры стола (для расчёта позиций игроков снаружи)
    let tableWidth: CGFloat
    let tableHeight: CGFloat
    
    private let outerTable: SKShapeNode
    private let innerTable: SKShapeNode
    
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
        let innerSize = CGSize(width: tableWidth * 0.92, height: tableHeight * 0.92)
        
        // Внешний овал (деревянная окантовка)
        outerTable = SKShapeNode(ellipseOf: outerSize)
        outerTable.fillColor = GameColors.tableBorder
        outerTable.strokeColor = GameColors.tableBorderStroke
        outerTable.lineWidth = 3
        outerTable.zPosition = 1
        
        // Внутренний овал (зелёное сукно)
        innerTable = SKShapeNode(ellipseOf: innerSize)
        innerTable.fillColor = GameColors.tableFelt
        innerTable.strokeColor = GameColors.tableFeltStroke
        innerTable.lineWidth = 2
        innerTable.zPosition = 2
        
        super.init()
        
        addChild(outerTable)
        addChild(innerTable)
        
        // Декоративная золотистая граница
        let decorativeSize = CGSize(width: innerSize.width - 10, height: innerSize.height - 10)
        let decorativeBorder = SKShapeNode(ellipseOf: decorativeSize)
        decorativeBorder.strokeColor = GameColors.goldTranslucent
        decorativeBorder.lineWidth = 1.5
        decorativeBorder.fillColor = .clear
        decorativeBorder.zPosition = 3
        addChild(decorativeBorder)
        
        // Текстура сукна
        addTableTexture(size: innerSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func addTableTexture(size: CGSize) {
        let maxWidth = size.width * 0.35
        let maxHeight = size.height * 0.35
        
        for _ in 0..<15 {
            let x = CGFloat.random(in: -maxWidth...maxWidth)
            let y = CGFloat.random(in: -maxHeight...maxHeight)
            
            let textureSpot = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...15))
            textureSpot.position = CGPoint(x: x, y: y)
            textureSpot.fillColor = GameColors.tableTexture
            textureSpot.strokeColor = .clear
            textureSpot.zPosition = 2.5
            textureSpot.alpha = 0.3
            addChild(textureSpot)
        }
    }
}
