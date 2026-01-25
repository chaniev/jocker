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
    
    init(playerNumber: Int, avatar: String, position: CGPoint, angle: CGFloat, totalPlayers: Int) {
        self.playerNumber = playerNumber
        self.avatar = avatar
        self.totalPlayers = totalPlayers
        
        super.init()
        
        self.position = position
        self.zPosition = 10
        
        setupVisuals(angle: angle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals(angle: CGFloat) {
        // Фоновый круг для аватара (увеличен в два раза)
        backgroundCircle = SKShapeNode(circleOfRadius: 90)
        backgroundCircle.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 0.9)
        backgroundCircle.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
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
    }
}
