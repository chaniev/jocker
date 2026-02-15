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
    private var suitSymbolNode: SKLabelNode?
    private let labelNode: SKLabelNode
    private let backgroundNode: SKShapeNode
    
    // MARK: - Initialization
    
    override init() {
        let width: CGFloat = 180
        let height: CGFloat = 230
        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        self.backgroundNode = SKShapeNode(rect: rect, cornerRadius: 14)
        self.labelNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        super.init()
        setupBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupBackground() {
        backgroundNode.fillColor = GameColors.trumpBackground
        backgroundNode.strokeColor = GameColors.goldTranslucent
        backgroundNode.lineWidth = 2
        backgroundNode.zPosition = 0
        addChild(backgroundNode)
        
        // Надпись "Козырь"
        labelNode.text = "Козырь"
        labelNode.fontSize = 20
        labelNode.fontColor = GameColors.textPrimary
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: 0, y: 86)
        labelNode.zPosition = 1
        addChild(labelNode)
    }
    
    // MARK: - Public Methods
    
    /// Установить козырную карту
    func setTrumpCard(_ card: Card?, animated: Bool = true) {
        clearDisplayedTrump(animated: animated)
        
        self.trumpCard = card
        
        guard let card = card else {
            labelNode.text = "Без козыря"
            labelNode.fontColor = GameColors.textSecondary
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
        labelNode.text = "Козырь"
        labelNode.fontColor = GameColors.textPrimary
    }

    /// Установить козырь только по масти (карта не раскрывается).
    func setTrumpSuit(_ suit: Suit?, animated: Bool = true) {
        clearDisplayedTrump(animated: animated)
        trumpCard = nil

        guard let suit else {
            labelNode.text = "Без козыря"
            labelNode.fontColor = GameColors.textSecondary
            return
        }

        let symbolNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        symbolNode.text = suit.rawValue
        symbolNode.fontSize = 84
        symbolNode.fontColor = suit.color == .red ? GameColors.cardRed : GameColors.textPrimary
        symbolNode.horizontalAlignmentMode = .center
        symbolNode.verticalAlignmentMode = .center
        symbolNode.position = CGPoint(x: 0, y: -28)
        symbolNode.zPosition = 2

        if animated {
            symbolNode.alpha = 0
            symbolNode.setScale(0.4)
            addChild(symbolNode)
            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let scale = SKAction.scale(to: 1.0, duration: 0.25)
            symbolNode.run(SKAction.group([fadeIn, scale]))
        } else {
            addChild(symbolNode)
        }

        suitSymbolNode = symbolNode
        labelNode.text = "Козырь: \(suit.name)"
        labelNode.fontColor = GameColors.textPrimary
    }

    /// Переводит индикатор в состояние ожидания выбора козыря игроком.
    func setAwaitingTrumpSelection(animated: Bool = true) {
        clearDisplayedTrump(animated: animated)
        trumpCard = nil
        labelNode.text = "Козырь выбирает игрок"
        labelNode.fontColor = GameColors.textSecondary
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

    private func clearDisplayedTrump(animated: Bool) {
        if let oldCardNode = cardNode {
            if animated {
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let scale = SKAction.scale(to: 0.5, duration: 0.2)
                let remove = SKAction.removeFromParent()
                oldCardNode.run(SKAction.sequence([SKAction.group([fadeOut, scale]), remove]))
            } else {
                oldCardNode.removeFromParent()
            }
            cardNode = nil
        }

        if let oldSuitNode = suitSymbolNode {
            if animated {
                let fadeOut = SKAction.fadeOut(withDuration: 0.15)
                let scale = SKAction.scale(to: 0.6, duration: 0.15)
                let remove = SKAction.removeFromParent()
                oldSuitNode.run(SKAction.sequence([SKAction.group([fadeOut, scale]), remove]))
            } else {
                oldSuitNode.removeFromParent()
            }
            suitSymbolNode = nil
        }
    }
}
