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
    
    private lazy var cardBackground: SKShapeNode = {
        let node = SKShapeNode(rect: CardNode.cardRect, cornerRadius: CardNode.cornerRadius)
        node.fillColor = .white
        node.strokeColor = .clear
        node.zPosition = 0
        return node
    }()
    private lazy var cardBorder: SKShapeNode = {
        let node = SKShapeNode(rect: CardNode.cardRect, cornerRadius: CardNode.cornerRadius)
        node.fillColor = .clear
        node.strokeColor = GameColors.cardBorder
        node.lineWidth = Style.baseBorderLineWidth
        node.zPosition = 1
        return node
    }()
    private lazy var shadowNode: SKShapeNode = {
        let shadow = SKShapeNode(rect: CardNode.cardRect, cornerRadius: CardNode.cornerRadius)
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: CardNode.scaled(4.8), y: -CardNode.scaled(4.8))
        shadow.zPosition = -1
        return shadow
    }()
    private var suitLabel: SKLabelNode?
    private var rankLabel: SKLabelNode?
    private var centerSuitLabel: SKLabelNode?
    private var backPattern: SKNode?

    private enum Style {
        static let baseBorderLineWidth: CGFloat = CardNode.scaled(4.8)
        static let highlightedBorderLineWidth: CGFloat = CardNode.scaled(6.0)
    }

    private static let sizeMultiplier: CGFloat = 1.1

    private static func scaled(_ value: CGFloat) -> CGFloat {
        return value * sizeMultiplier
    }
    
    // Базовые размеры карты с глобальным увеличением на 10%.
    static let cardWidth: CGFloat = CardNode.scaled(192)
    static let cardHeight: CGFloat = CardNode.scaled(288)
    static let cornerRadius: CGFloat = CardNode.scaled(19.2)
    private static var cardRect: CGRect {
        CGRect(
            x: -CardNode.cardWidth / 2,
            y: -CardNode.cardHeight / 2,
            width: CardNode.cardWidth,
            height: CardNode.cardHeight
        )
    }
    
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
        addChild(shadowNode)
        addChild(cardBackground)
        addChild(cardBorder)

        // Создаём элементы лицевой стороны
        if isFaceUp {
            setupFaceUpVisuals()
        } else {
            setupBackVisuals()
        }
    }
    
    private func setupFaceUpVisuals() {
        if card.isJoker {
            setupJokerVisuals()
        } else {
            setupRegularCardVisuals()
        }
    }
    
    private func setupRegularCardVisuals() {
        guard case .regular(let suit, let rank) = card else { return }
        
        let color = cardColor(for: suit)
        
        // Верхний левый угол - ранг
        let topRankLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        topRankLabel.text = rank.symbol
        topRankLabel.fontSize = CardNode.scaled(43.2)
        topRankLabel.fontColor = color
        topRankLabel.horizontalAlignmentMode = .left
        topRankLabel.verticalAlignmentMode = .top
        topRankLabel.position = CGPoint(
            x: -CardNode.cardWidth / 2 + CardNode.scaled(19.2),
            y: CardNode.cardHeight / 2 - CardNode.scaled(19.2)
        )
        topRankLabel.zPosition = 2
        addChild(topRankLabel)
        rankLabel = topRankLabel
        
        // Верхний левый угол - масть
        let topSuitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        topSuitLabel.text = suit.rawValue
        topSuitLabel.fontSize = CardNode.scaled(38.4)
        topSuitLabel.fontColor = color
        topSuitLabel.horizontalAlignmentMode = .left
        topSuitLabel.verticalAlignmentMode = .top
        topSuitLabel.position = CGPoint(
            x: -CardNode.cardWidth / 2 + CardNode.scaled(19.2),
            y: CardNode.cardHeight / 2 - CardNode.scaled(62.4)
        )
        topSuitLabel.zPosition = 2
        addChild(topSuitLabel)
        suitLabel = topSuitLabel
        
        // Центральная масть (большая)
        let middleSuitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        middleSuitLabel.text = suit.rawValue
        middleSuitLabel.fontSize = CardNode.scaled(115.2)
        middleSuitLabel.fontColor = color
        middleSuitLabel.horizontalAlignmentMode = .center
        middleSuitLabel.verticalAlignmentMode = .center
        middleSuitLabel.position = CGPoint(x: 0, y: 0)
        middleSuitLabel.zPosition = 2
        addChild(middleSuitLabel)
        centerSuitLabel = middleSuitLabel
        
        // Нижний правый угол - ранг (перевёрнутый)
        let bottomRankLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bottomRankLabel.text = rank.symbol
        bottomRankLabel.fontSize = CardNode.scaled(43.2)
        bottomRankLabel.fontColor = color
        bottomRankLabel.horizontalAlignmentMode = .right
        bottomRankLabel.verticalAlignmentMode = .bottom
        bottomRankLabel.position = CGPoint(
            x: CardNode.cardWidth / 2 - CardNode.scaled(19.2),
            y: -CardNode.cardHeight / 2 + CardNode.scaled(19.2)
        )
        bottomRankLabel.zRotation = .pi  // Поворачиваем на 180 градусов
        bottomRankLabel.zPosition = 2
        addChild(bottomRankLabel)
        
        // Нижний правый угол - масть (перевёрнутая)
        let bottomSuitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bottomSuitLabel.text = suit.rawValue
        bottomSuitLabel.fontSize = CardNode.scaled(38.4)
        bottomSuitLabel.fontColor = color
        bottomSuitLabel.horizontalAlignmentMode = .right
        bottomSuitLabel.verticalAlignmentMode = .bottom
        bottomSuitLabel.position = CGPoint(
            x: CardNode.cardWidth / 2 - CardNode.scaled(19.2),
            y: -CardNode.cardHeight / 2 + CardNode.scaled(62.4)
        )
        bottomSuitLabel.zRotation = .pi  // Поворачиваем на 180 градусов
        bottomSuitLabel.zPosition = 2
        addChild(bottomSuitLabel)
    }
    
    private func setupJokerVisuals() {
        // Джокер - специальное оформление
        let jokerLabel = SKLabelNode(text: "🃏")
        jokerLabel.fontSize = CardNode.scaled(134.4)
        jokerLabel.horizontalAlignmentMode = .center
        jokerLabel.verticalAlignmentMode = .center
        jokerLabel.position = CGPoint(x: 0, y: 0)
        jokerLabel.zPosition = 2
        addChild(jokerLabel)
        
        // Текст "JOKER"
        let textLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        textLabel.text = "JOKER"
        textLabel.fontSize = CardNode.scaled(33.6)
        textLabel.fontColor = GameColors.jokerText
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = CGPoint(x: 0, y: -CardNode.scaled(84))
        textLabel.zPosition = 2
        addChild(textLabel)
        
        // Градиентный фон для джокера
        cardBackground.fillColor = GameColors.jokerBackground
    }
    
    private func setupBackVisuals() {
        // Рубашка карты
        let pattern = SKNode()
        pattern.zPosition = 2
        
        // Фон рубашки - синий с узором
        cardBackground.fillColor = GameColors.cardBack
        
        // Внутренний прямоугольник
        let innerRect = CGRect(
            x: -CardNode.cardWidth / 2 + CardNode.scaled(24),
            y: -CardNode.cardHeight / 2 + CardNode.scaled(24),
            width: CardNode.cardWidth - CardNode.scaled(48),
            height: CardNode.cardHeight - CardNode.scaled(48)
        )
        let innerBorder = SKShapeNode(rect: innerRect, cornerRadius: CardNode.scaled(9.6))
        innerBorder.strokeColor = .white
        innerBorder.lineWidth = CardNode.scaled(4.8)
        innerBorder.fillColor = .clear
        innerBorder.zPosition = 0
        pattern.addChild(innerBorder)
        
        // Узор из ромбов
        let diamondSize: CGFloat = CardNode.scaled(28.8)
        let spacing: CGFloat = CardNode.scaled(38.4)
        
        for row in stride(from: -CardNode.cardHeight / 2 + CardNode.scaled(48), to: CardNode.cardHeight / 2 - CardNode.scaled(24), by: spacing) {
            for col in stride(from: -CardNode.cardWidth / 2 + CardNode.scaled(48), to: CardNode.cardWidth / 2 - CardNode.scaled(24), by: spacing) {
                let diamond = createDiamond(size: diamondSize)
                diamond.position = CGPoint(x: col, y: row)
                diamond.fillColor = SKColor(white: 1.0, alpha: 0.3)
                diamond.strokeColor = .clear
                diamond.zPosition = 1
                pattern.addChild(diamond)
            }
        }
        
        addChild(pattern)
        backPattern = pattern
    }

    private func cardColor(for suit: Suit) -> SKColor {
        switch suit {
        case .diamonds, .hearts:
            return GameColors.cardRed
        case .spades:
            return GameColors.cardSpade
        case .clubs:
            return GameColors.cardClub
        }
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
            if child !== cardBackground && child !== cardBorder && child !== shadowNode {
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
            cardBorder.lineWidth = Style.highlightedBorderLineWidth
            
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])
            cardBorder.run(SKAction.repeatForever(pulse), withKey: "highlight")
        } else {
            cardBorder.removeAction(forKey: "highlight")
            cardBorder.strokeColor = GameColors.cardBorder
            cardBorder.lineWidth = Style.baseBorderLineWidth
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
