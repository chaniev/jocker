//
//  TurnIndicatorNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 12.02.2026.
//

import SpriteKit

final class TurnIndicatorNode: SKNode {
    
    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode
    private let arrowNode: SKShapeNode
    
    override init() {
        let backgroundSize = CGSize(width: 110, height: 44)
        let cornerRadius: CGFloat = 12
        
        backgroundNode = SKShapeNode(
            rectOf: backgroundSize,
            cornerRadius: cornerRadius
        )
        backgroundNode.fillColor = GameColors.statusGreen
        backgroundNode.strokeColor = .white
        backgroundNode.lineWidth = 2
        backgroundNode.zPosition = 0
        
        labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.text = "ХОД"
        labelNode.fontSize = 18
        labelNode.fontColor = .black
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.position = CGPoint(x: 0, y: 2)
        labelNode.zPosition = 1
        
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 0, y: -10))
        arrowPath.addLine(to: CGPoint(x: -10, y: 10))
        arrowPath.addLine(to: CGPoint(x: 10, y: 10))
        arrowPath.closeSubpath()
        
        arrowNode = SKShapeNode(path: arrowPath)
        arrowNode.fillColor = .white
        arrowNode.strokeColor = .clear
        arrowNode.position = CGPoint(x: 0, y: -(backgroundSize.height / 2) - 10)
        arrowNode.zPosition = 0
        
        super.init()
        
        isHidden = true
        zPosition = 200
        
        addChild(backgroundNode)
        addChild(labelNode)
        addChild(arrowNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTurnOwnerPosition(_ ownerPosition: CGPoint, seatDirection: CGVector, animated: Bool) {
        let direction = normalize(seatDirection)
        let offsetDistance: CGFloat = 118
        let targetPosition = CGPoint(
            x: ownerPosition.x + direction.dx * offsetDistance,
            y: ownerPosition.y + direction.dy * offsetDistance
        )
        
        isHidden = false
        
        let angleToOwner = atan2(-direction.dy, -direction.dx)
        arrowNode.zRotation = angleToOwner + (.pi / 2)
        
        removeAction(forKey: "pulse")
        if animated {
            run(SKAction.move(to: targetPosition, duration: 0.18))
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.45),
                SKAction.scale(to: 1.0, duration: 0.45)
            ])
            run(SKAction.repeatForever(pulse), withKey: "pulse")
        } else {
            position = targetPosition
        }
    }
    
    func hide() {
        removeAction(forKey: "pulse")
        isHidden = true
    }
    
    private func normalize(_ vector: CGVector) -> CGVector {
        let length = max(0.0001, sqrt(vector.dx * vector.dx + vector.dy * vector.dy))
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
}
