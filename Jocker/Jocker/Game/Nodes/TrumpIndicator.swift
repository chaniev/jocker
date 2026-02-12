//
//  TrumpIndicator.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit

/// Индикатор козырной карты
class TrumpIndicator: SKNode {
    
    private var trumpCard: Card?
    private var cardNode: CardNode?
    private var labelNode: SKLabelNode?
    private var backgroundNode: SKShapeNode?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupBackground() {
        // Фон для индикатора
        let width: CGFloat = 180
        let height: CGFloat = 230
        
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        backgroundNode = SKShapeNode(rect: rect, cornerRadius: 14)
        backgroundNode?.fillColor = GameColors.trumpBackground
        backgroundNode?.strokeColor = GameColors.goldTranslucent
        backgroundNode?.lineWidth = 2
        backgroundNode?.zPosition = 0
        addChild(backgroundNode!)
        
        // Надпись "Козырь"
        labelNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        labelNode?.text = "Козырь"
        labelNode?.fontSize = 20
        labelNode?.fontColor = GameColors.textPrimary
        labelNode?.horizontalAlignmentMode = .center
        labelNode?.verticalAlignmentMode = .center
        labelNode?.position = CGPoint(x: 0, y: 86)
        labelNode?.zPosition = 1
        addChild(labelNode!)
    }
    
    // MARK: - Public Methods
    
    /// Установить козырную карту
    func setTrumpCard(_ card: Card?, animated: Bool = true) {
        // Удаляем старую карту
        if let oldCardNode = cardNode {
            if animated {
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let scale = SKAction.scale(to: 0.5, duration: 0.2)
                let remove = SKAction.removeFromParent()
                oldCardNode.run(SKAction.sequence([SKAction.group([fadeOut, scale]), remove]))
            } else {
                oldCardNode.removeFromParent()
            }
        }
        
        self.trumpCard = card
        
        guard let card = card else {
            // Нет козыря
            labelNode?.text = "Козырь выбирает игрок"
            labelNode?.fontColor = GameColors.textSecondary
            return
        }
        
        // Создаём новую карту
        let targetScale: CGFloat = 0.52
        let newCardNode = CardNode(card: card, faceUp: true)
        newCardNode.position = CGPoint(x: 0, y: -24)
        newCardNode.setScale(targetScale)
        newCardNode.zPosition = 2
        
        if animated {
            newCardNode.alpha = 0
            newCardNode.setScale(0.4)
            addChild(newCardNode)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let scale = SKAction.scale(to: targetScale, duration: 0.3)
            newCardNode.run(SKAction.group([fadeIn, scale]))
        } else {
            addChild(newCardNode)
        }
        
        self.cardNode = newCardNode
        
        // Обновляем текст - всегда "Козырь" когда есть карта (включая джокера)
        labelNode?.text = "Козырь"
        labelNode?.fontColor = GameColors.textPrimary
    }
    
    /// Скрыть индикатор
    func hide(animated: Bool = true) {
        if animated {
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            run(fadeOut)
        } else {
            alpha = 0
        }
    }
    
    /// Показать индикатор
    func show(animated: Bool = true) {
        if animated {
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            run(fadeIn)
        } else {
            alpha = 1
        }
    }
}
