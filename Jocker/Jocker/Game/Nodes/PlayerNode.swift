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
    let isLocalPlayer: Bool
    let shouldRevealCards: Bool
    let seatDirection: CGVector
    
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
    
    init(
        playerNumber: Int,
        avatar: String,
        position: CGPoint,
        seatDirection: CGVector,
        isLocalPlayer: Bool,
        shouldRevealCards: Bool = false,
        totalPlayers: Int
    ) {
        self.playerNumber = playerNumber
        self.avatar = avatar
        self.totalPlayers = totalPlayers
        self.isLocalPlayer = isLocalPlayer
        self.shouldRevealCards = shouldRevealCards
        self.seatDirection = seatDirection
        
        super.init()
        
        self.position = position
        self.zPosition = 10
        
        setupVisuals(seatDirection: seatDirection)
        setupCardHand(seatDirection: seatDirection)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals(seatDirection: CGVector) {
        let avatarRadius: CGFloat = 58
        let isSideSeat = abs(seatDirection.dx) > abs(seatDirection.dy)
        
        // Фоновый круг для аватара
        backgroundCircle = SKShapeNode(circleOfRadius: avatarRadius)
        backgroundCircle.fillColor = GameColors.playerBackground
        backgroundCircle.strokeColor = GameColors.gold
        backgroundCircle.lineWidth = 3
        backgroundCircle.zPosition = 0
        addChild(backgroundCircle)
        
        // Аватар (эмодзи)
        avatarNode = SKLabelNode(text: avatar)
        avatarNode.fontSize = 64
        avatarNode.verticalAlignmentMode = .center
        avatarNode.horizontalAlignmentMode = .center
        avatarNode.zPosition = 1
        addChild(avatarNode)
        
        // Имя игрока
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nameLabel.text = "Игрок \(playerNumber)"
        nameLabel.fontSize = 40
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.zPosition = 1
        
        // Текст ставим снаружи от стола, чтобы не пересекался с рукой
        if isSideSeat {
            nameLabel.position = CGPoint(x: 0, y: -88)
        } else {
            nameLabel.position = CGPoint(x: 118, y: 0)
        }
        
        addChild(nameLabel)
        
        // Добавляем небольшую тень для лучшей видимости
        let shadow = SKShapeNode(circleOfRadius: avatarRadius)
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        addChild(shadow)
        
        // Счётчик взяток
        trickCountLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        trickCountLabel.fontSize = 20
        trickCountLabel.fontColor = .white
        trickCountLabel.horizontalAlignmentMode = .center
        trickCountLabel.verticalAlignmentMode = .center
        trickCountLabel.position = isSideSeat ? CGPoint(x: 0, y: -118) : CGPoint(x: 118, y: -40)
        trickCountLabel.zPosition = 3
        trickCountLabel.text = "0/0"
        addChild(trickCountLabel)
        
        // Индикатор ставки
        bidLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bidLabel.fontSize = 18
        bidLabel.fontColor = GameColors.gold
        bidLabel.horizontalAlignmentMode = .center
        bidLabel.verticalAlignmentMode = .center
        bidLabel.position = isSideSeat ? CGPoint(x: 0, y: -90) : CGPoint(x: 118, y: -68)
        bidLabel.zPosition = 3
        bidLabel.text = ""
        bidLabel.isHidden = true
        addChild(bidLabel)
    }
    
    private func setupCardHand(seatDirection: CGVector) {
        hand = CardHandNode()
        
        // В режиме раскрытия показываем карты всех игроков.
        hand.isFaceUp = isLocalPlayer || shouldRevealCards
        
        // Рука всегда располагается в сторону центра стола
        let toCenter = CGVector(dx: -seatDirection.dx, dy: -seatDirection.dy)
        let handDistance: CGFloat = isLocalPlayer ? 180 : 165
        hand.handPosition = CGPoint(
            x: toCenter.dx * handDistance,
            y: toCenter.dy * handDistance
        )
        
        hand.arcAngle = isLocalPlayer ? 0.34 : 0.26
        hand.cardSpacing = isLocalPlayer ? 62 : 46
        hand.cardOverlapRatio = isLocalPlayer ? 0.58 : 0.68
        
        // На боковых местах карты размещаются вертикально
        let isSideSeat = abs(seatDirection.dx) > abs(seatDirection.dy)
        hand.isVertical = isSideSeat
        
        if isSideSeat {
            // Разворачиваем карты боковых игроков в сторону центра
            hand.orientationRotation = seatDirection.dx < 0 ? -.pi / 2 : .pi / 2
        } else {
            // Верхний игрок располагает карты "вниз", к центру
            hand.orientationRotation = seatDirection.dy > 0 ? .pi : 0
        }
        
        hand.setScale(isLocalPlayer ? 0.72 : 0.56)
        
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
    
    func setHandDimmed(_ isDimmed: Bool, animated: Bool) {
        let targetAlpha: CGFloat = isDimmed ? 0.45 : 1.0
        hand.removeAction(forKey: "handDim")
        
        if animated {
            let action = SKAction.fadeAlpha(to: targetAlpha, duration: 0.18)
            hand.run(action, withKey: "handDim")
        } else {
            hand.alpha = targetAlpha
        }
    }
}
