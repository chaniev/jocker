//
//  PlayerNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit

class PlayerNode: SKNode {
    
    let playerNumber: Int
    let avatar: String
    let totalPlayers: Int
    
    private var avatarNode: SKLabelNode!
    private var nameLabel: SKLabelNode!
    private var backgroundCircle: SKShapeNode!
    
    // Карты игрока
    var hand: CardHandNode!
    private var trickCountLabel: SKLabelNode!
    private var bidLabel: SKLabelNode!
    
    // Ставка и взятки
    private(set) var bid: Int = 0
    private(set) var tricksTaken: Int = 0
    
    init(playerNumber: Int, avatar: String, position: CGPoint, angle: CGFloat, totalPlayers: Int) {
        self.playerNumber = playerNumber
        self.avatar = avatar
        self.totalPlayers = totalPlayers
        
        super.init()
        
        self.position = position
        self.zPosition = 10
        
        setupVisuals(angle: angle)
        setupCardHand(angle: angle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals(angle: CGFloat) {
        // Фоновый круг для аватара (увеличен в два раза)
        backgroundCircle = SKShapeNode(circleOfRadius: 90)
        backgroundCircle.fillColor = GameColors.playerBackground
        backgroundCircle.strokeColor = GameColors.gold
        backgroundCircle.lineWidth = 3
        backgroundCircle.zPosition = 0
        addChild(backgroundCircle)
        
        // Аватар (эмодзи) - увеличен в два раза
        avatarNode = SKLabelNode(text: avatar)
        avatarNode.fontSize = 100
        avatarNode.verticalAlignmentMode = .center
        avatarNode.horizontalAlignmentMode = .center
        avatarNode.zPosition = 1
        addChild(avatarNode)
        
        // Имя игрока - позиционируем в зависимости от номера игрока
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.text = "Игрок \(playerNumber)"
        nameLabel.fontSize = 54
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.zPosition = 1
        
        // Для игроков 1 и 3 имя справа, для остальных - адаптивно по углу
        // Также для игрока 2 при 3 игроках имя справа
        // При 4 игроках игроки 2 и 4 имеют имена под аватаром
        if playerNumber == 1 || playerNumber == 3 || (playerNumber == 2 && totalPlayers == 3) {
            // Имя справа от аватара
            nameLabel.position = CGPoint(x: 180, y: 0)
        } else if (playerNumber == 2 || playerNumber == 4) && totalPlayers == 4 {
            // Имя под аватаром для игроков 2 и 4 при 4 игроках
            nameLabel.position = CGPoint(x: 0, y: -120)
        } else {
            // Определяем позицию имени в зависимости от угла игрока
            let normalizedAngle = angle.truncatingRemainder(dividingBy: 2 * .pi)
            
            if normalizedAngle >= -.pi/4 && normalizedAngle < .pi/4 {
                // Игрок снизу - имя сверху аватара
                nameLabel.position = CGPoint(x: 0, y: 70)
            } else if normalizedAngle >= .pi/4 && normalizedAngle < 3 * .pi/4 {
                // Игрок справа - имя слева от аватара
                nameLabel.position = CGPoint(x: -120, y: 0)
            } else if normalizedAngle >= 3 * .pi/4 || normalizedAngle < -3 * .pi/4 {
                // Игрок сверху - имя снизу аватара
                nameLabel.position = CGPoint(x: 0, y: -70)
            } else {
                // Игрок слева - имя справа от аватара
                nameLabel.position = CGPoint(x: 120, y: 0)
            }
        }
        
        addChild(nameLabel)
        
        // Добавляем небольшую тень для лучшей видимости (увеличена в два раза)
        let shadow = SKShapeNode(circleOfRadius: 90)
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        addChild(shadow)
        
        // Счётчик взяток
        trickCountLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        trickCountLabel.fontSize = 24
        trickCountLabel.fontColor = .white
        trickCountLabel.horizontalAlignmentMode = .center
        trickCountLabel.verticalAlignmentMode = .center
        trickCountLabel.position = CGPoint(x: 0, y: -150)
        trickCountLabel.zPosition = 3
        trickCountLabel.text = "0/0"
        addChild(trickCountLabel)
        
        // Индикатор ставки
        bidLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bidLabel.fontSize = 20
        bidLabel.fontColor = GameColors.gold
        bidLabel.horizontalAlignmentMode = .center
        bidLabel.verticalAlignmentMode = .center
        bidLabel.position = CGPoint(x: 0, y: -120)
        bidLabel.zPosition = 3
        bidLabel.text = ""
        bidLabel.isHidden = true
        addChild(bidLabel)
    }
    
    private func setupCardHand(angle: CGFloat) {
        hand = CardHandNode()
        
        // Только игрок 1 видит свои карты лицом, остальные показываются рубашкой
        hand.isFaceUp = (playerNumber == 1)
        
        // Специальная обработка для Игрока 1 (внизу экрана)
        if playerNumber == 1 {
            // Карты располагаются горизонтально над игроком (как в покере)
            hand.handPosition = CGPoint(x: 0, y: 200)  // Подняли выше
            hand.arcAngle = 0.25  // Уменьшенный угол для более плоского веера
            hand.cardSpacing = 35   // Сильно уменьшено для перекрывания как в покере
            hand.cardOverlapRatio = 0.35  // Карты перекрываются на 65%
            hand.isVertical = false  // Горизонтальное расположение
        } else if playerNumber == 3 && totalPlayers == 4 {
            // Для Игрока 3 (сверху) - карты под ним, на том же расстоянии что и у Игрока 1
            hand.handPosition = CGPoint(x: 0, y: -200)  // Под игроком (отрицательное значение)
            hand.arcAngle = 0.25  // Уменьшенный угол для более плоского веера
            hand.cardSpacing = 35   // Сильно уменьшено для перекрывания как в покере
            hand.cardOverlapRatio = 0.35  // Карты перекрываются на 65%
            hand.isVertical = false  // Горизонтальное расположение
        } else {
            // Позиция руки относительно игрока для остальных игроков
            let handDistance: CGFloat = 150
            let handX = handDistance * cos(angle)
            let handY = handDistance * sin(angle)
            
            hand.handPosition = CGPoint(x: handX, y: handY)
            hand.arcAngle = 0.25  // Уменьшенный угол для более плоского веера
            hand.cardSpacing = 35   // Сильно уменьшено для перекрывания как в покере
            hand.cardOverlapRatio = 0.35  // Карты перекрываются на 65%
            
            // Определяем, должна ли рука быть вертикальной
            let normalizedAngle = angle.truncatingRemainder(dividingBy: 2 * .pi)
            hand.isVertical = (normalizedAngle >= .pi/4 && normalizedAngle < 3 * .pi/4) ||
                              (normalizedAngle >= -3 * .pi/4 && normalizedAngle < -.pi/4)
        }
        
        addChild(hand)
    }
    
    // MARK: - Public Methods
    
    /// Установить ставку игрока
    func setBid(_ bid: Int, animated: Bool = true) {
        self.bid = bid
        updateBidDisplay(animated: animated)
    }
    
    /// Увеличить счётчик взяток
    func incrementTricks() {
        tricksTaken += 1
        updateTrickDisplay()
    }
    
    /// Сбросить счётчики для новой раздачи
    func resetForNewRound() {
        bid = 0
        tricksTaken = 0
        updateBidDisplay(animated: false)
        updateTrickDisplay()
    }
    
    /// Обновить отображение ставки
    private func updateBidDisplay(animated: Bool) {
        bidLabel.text = "Ставка: \(bid)"
        bidLabel.isHidden = false
        
        if animated {
            bidLabel.alpha = 0
            bidLabel.setScale(0.5)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let scale = SKAction.scale(to: 1.0, duration: 0.3)
            bidLabel.run(SKAction.group([fadeIn, scale]))
        }
    }
    
    /// Обновить отображение взяток
    private func updateTrickDisplay() {
        trickCountLabel.text = "\(tricksTaken)/\(bid)"
        
        // Изменить цвет в зависимости от выполнения ставки
        if tricksTaken > bid {
            trickCountLabel.fontColor = GameColors.statusOrange
        } else if tricksTaken == bid {
            trickCountLabel.fontColor = GameColors.statusGreen
        } else {
            trickCountLabel.fontColor = .white
        }
        
        // Анимация изменения
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        trickCountLabel.run(scale)
    }
    
    /// Подсветить игрока (когда его ход)
    func highlight(_ enabled: Bool) {
        if enabled {
            backgroundCircle.strokeColor = GameColors.statusGreen
            backgroundCircle.lineWidth = 5
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            backgroundCircle.run(SKAction.repeatForever(pulse), withKey: "highlight")
        } else {
            backgroundCircle.removeAction(forKey: "highlight")
            backgroundCircle.strokeColor = GameColors.gold
            backgroundCircle.lineWidth = 3
            backgroundCircle.setScale(1.0)
        }
    }
}

