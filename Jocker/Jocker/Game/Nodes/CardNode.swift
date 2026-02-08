//
//  CardNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit

/// SpriteKit нода для отображения карты
class CardNode: SKNode {
    
    // MARK: - Properties
    
    let card: Card
    private(set) var isFaceUp: Bool = true
    
    private var cardBackground: SKShapeNode!
    private var cardBorder: SKShapeNode!
    private var suitLabel: SKLabelNode!
    private var rankLabel: SKLabelNode!
    private var centerSuitLabel: SKLabelNode!
    private var backPattern: SKNode!
    
    // Размеры карты (уменьшены на 20% от предыдущих)
    static let cardWidth: CGFloat = 192
    static let cardHeight: CGFloat = 288
    static let cornerRadius: CGFloat = 19.2
    
    // MARK: - Initialization
    
    init(card: Card, faceUp: Bool = true) {
        self.card = card
        self.isFaceUp = faceUp
        
        super.init()
        
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupVisuals() {
        // Создаём фон карты
        let rect = CGRect(
            x: -CardNode.cardWidth / 2,
            y: -CardNode.cardHeight / 2,
            width: CardNode.cardWidth,
            height: CardNode.cardHeight
        )
        
        cardBackground = SKShapeNode(rect: rect, cornerRadius: CardNode.cornerRadius)
        cardBackground.fillColor = .white
        cardBackground.strokeColor = .clear
        cardBackground.zPosition = 0
        addChild(cardBackground)
        
        // Создаём рамку карты (толщина уменьшена на 20%)
        cardBorder = SKShapeNode(rect: rect, cornerRadius: CardNode.cornerRadius)
        cardBorder.fillColor = .clear
        cardBorder.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        cardBorder.lineWidth = 4.8
        cardBorder.zPosition = 1
        addChild(cardBorder)
        
        // Создаём элементы лицевой стороны
        if isFaceUp {
            setupFaceUpVisuals()
        } else {
            setupBackVisuals()
        }
        
        // Добавляем тень (смещение уменьшено на 20%)
        let shadow = SKShapeNode(rect: rect, cornerRadius: CardNode.cornerRadius)
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: 4.8, y: -4.8)
        shadow.zPosition = -1
        addChild(shadow)
    }
    
    private func setupFaceUpVisuals() {
        if card.isJoker {
            setupJokerVisuals()
        } else {
            setupRegularCardVisuals()
        }
    }
    
    private func setupRegularCardVisuals() {
        guard let suit = card.suit, let rank = card.rank else { return }
        
        let color: SKColor = suit.color == .red ?
            SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) :
            SKColor(white: 0.1, alpha: 1.0)
        
        // Верхний левый угол - ранг (уменьшено на 20%)
        rankLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        rankLabel.text = rank.symbol
        rankLabel.fontSize = 43.2
        rankLabel.fontColor = color
        rankLabel.horizontalAlignmentMode = .left
        rankLabel.verticalAlignmentMode = .top
        rankLabel.position = CGPoint(
            x: -CardNode.cardWidth / 2 + 19.2,
            y: CardNode.cardHeight / 2 - 19.2
        )
        rankLabel.zPosition = 2
        addChild(rankLabel)
        
        // Верхний левый угол - масть (уменьшено на 20%)
        suitLabel = SKLabelNode(text: suit.rawValue)
        suitLabel.fontSize = 38.4
        suitLabel.horizontalAlignmentMode = .left
        suitLabel.verticalAlignmentMode = .top
        suitLabel.position = CGPoint(
            x: -CardNode.cardWidth / 2 + 19.2,
            y: CardNode.cardHeight / 2 - 62.4
        )
        suitLabel.zPosition = 2
        addChild(suitLabel)
        
        // Центральная масть (большая) - уменьшено на 20%
        centerSuitLabel = SKLabelNode(text: suit.rawValue)
        centerSuitLabel.fontSize = 115.2
        centerSuitLabel.horizontalAlignmentMode = .center
        centerSuitLabel.verticalAlignmentMode = .center
        centerSuitLabel.position = CGPoint(x: 0, y: 0)
        centerSuitLabel.zPosition = 2
        addChild(centerSuitLabel)
        
        // Нижний правый угол - ранг (перевёрнутый) - уменьшено на 20%
        let bottomRankLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bottomRankLabel.text = rank.symbol
        bottomRankLabel.fontSize = 43.2
        bottomRankLabel.fontColor = color
        bottomRankLabel.horizontalAlignmentMode = .right
        bottomRankLabel.verticalAlignmentMode = .bottom
        bottomRankLabel.position = CGPoint(
            x: CardNode.cardWidth / 2 - 19.2,
            y: -CardNode.cardHeight / 2 + 19.2
        )
        bottomRankLabel.zRotation = .pi  // Поворачиваем на 180 градусов
        bottomRankLabel.zPosition = 2
        addChild(bottomRankLabel)
        
        // Нижний правый угол - масть (перевёрнутая) - уменьшено на 20%
        let bottomSuitLabel = SKLabelNode(text: suit.rawValue)
        bottomSuitLabel.fontSize = 38.4
        bottomSuitLabel.horizontalAlignmentMode = .right
        bottomSuitLabel.verticalAlignmentMode = .bottom
        bottomSuitLabel.position = CGPoint(
            x: CardNode.cardWidth / 2 - 19.2,
            y: -CardNode.cardHeight / 2 + 62.4
        )
        bottomSuitLabel.zRotation = .pi  // Поворачиваем на 180 градусов
        bottomSuitLabel.zPosition = 2
        addChild(bottomSuitLabel)
    }
    
    private func setupJokerVisuals() {
        // Джокер - специальное оформление (уменьшено на 20%)
        let jokerLabel = SKLabelNode(text: "🃏")
        jokerLabel.fontSize = 134.4
        jokerLabel.horizontalAlignmentMode = .center
        jokerLabel.verticalAlignmentMode = .center
        jokerLabel.position = CGPoint(x: 0, y: 0)
        jokerLabel.zPosition = 2
        addChild(jokerLabel)
        
        // Текст "JOKER" (уменьшено на 20%)
        let textLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        textLabel.text = "JOKER"
        textLabel.fontSize = 33.6
        textLabel.fontColor = SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = CGPoint(x: 0, y: -84)
        textLabel.zPosition = 2
        addChild(textLabel)
        
        // Градиентный фон для джокера
        cardBackground.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
    }
    
    private func setupBackVisuals() {
        // Рубашка карты (размеры уменьшены на 20%)
        backPattern = SKNode()
        backPattern.zPosition = 2
        
        // Фон рубашки - синий с узором
        cardBackground.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1.0)
        
        // Внутренний прямоугольник (отступы уменьшены на 20%)
        let innerRect = CGRect(
            x: -CardNode.cardWidth / 2 + 24,
            y: -CardNode.cardHeight / 2 + 24,
            width: CardNode.cardWidth - 48,
            height: CardNode.cardHeight - 48
        )
        let innerBorder = SKShapeNode(rect: innerRect, cornerRadius: 9.6)
        innerBorder.strokeColor = .white
        innerBorder.lineWidth = 4.8
        innerBorder.fillColor = .clear
        innerBorder.zPosition = 0
        backPattern.addChild(innerBorder)
        
        // Узор из ромбов (размеры уменьшены на 20%)
        let diamondSize: CGFloat = 28.8
        let spacing: CGFloat = 38.4
        
        for row in stride(from: -CardNode.cardHeight / 2 + 48, to: CardNode.cardHeight / 2 - 24, by: spacing) {
            for col in stride(from: -CardNode.cardWidth / 2 + 48, to: CardNode.cardWidth / 2 - 24, by: spacing) {
                let diamond = createDiamond(size: diamondSize)
                diamond.position = CGPoint(x: col, y: row)
                diamond.fillColor = SKColor(white: 1.0, alpha: 0.3)
                diamond.strokeColor = .clear
                diamond.zPosition = 1
                backPattern.addChild(diamond)
            }
        }
        
        addChild(backPattern)
    }
    
    private func createDiamond(size: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size / 2))
        path.addLine(to: CGPoint(x: size / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -size / 2))
        path.addLine(to: CGPoint(x: -size / 2, y: 0))
        path.closeSubpath()
        
        return SKShapeNode(path: path)
    }
    
    // MARK: - Public Methods
    
    /// Переворачивает карту
    func flip(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            // Анимация переворота
            let shrink = SKAction.scaleX(to: 0.0, duration: 0.15)
            let grow = SKAction.scaleX(to: 1.0, duration: 0.15)
            
            run(shrink) { [weak self] in
                guard let self = self else { return }
                self.isFaceUp.toggle()
                self.updateVisuals()
                
                self.run(grow) {
                    completion?()
                }
            }
        } else {
            isFaceUp.toggle()
            updateVisuals()
            completion?()
        }
    }
    
    private func updateVisuals() {
        // Удаляем старые элементы
        suitLabel?.removeFromParent()
        rankLabel?.removeFromParent()
        centerSuitLabel?.removeFromParent()
        backPattern?.removeFromParent()
        
        // Очищаем все дочерние элементы кроме фона и рамки
        children.forEach { child in
            if child !== cardBackground && child !== cardBorder {
                child.removeFromParent()
            }
        }
        
        // Создаём новые элементы
        if isFaceUp {
            cardBackground.fillColor = .white
            setupFaceUpVisuals()
        } else {
            setupBackVisuals()
        }
    }
    
    /// Подсветка карты (например, когда её можно сыграть)
    func highlight(_ enabled: Bool, color: SKColor = .yellow) {
        if enabled {
            cardBorder.strokeColor = color
            cardBorder.lineWidth = 3
            
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])
            cardBorder.run(SKAction.repeatForever(pulse), withKey: "highlight")
        } else {
            cardBorder.removeAction(forKey: "highlight")
            cardBorder.strokeColor = SKColor(white: 0.3, alpha: 1.0)
            cardBorder.lineWidth = 2
            cardBorder.alpha = 1.0
        }
    }
    
    /// Анимация взятия карты в руку
    func animateTakeToHand(to position: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        let move = SKAction.move(to: position, duration: duration)
        move.timingMode = .easeOut
        
        run(move) {
            completion?()
        }
    }
    
    /// Анимация размещения карты на стол
    func animatePlaceOnTable(to position: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        let move = SKAction.move(to: position, duration: duration)
        let scale = SKAction.scale(to: 1.1, duration: duration)
        let group = SKAction.group([move, scale])
        group.timingMode = .easeOut
        
        run(group) {
            completion?()
        }
    }
}

