//
//  GameScene.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var playerCount: Int = 4
    private var pokerTable: SKShapeNode?
    private var tableInner: SKShapeNode?
    
    override func didMove(to view: SKView) {
        // Устанавливаем фон сцены - темно-синий
        self.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        // Создаём овальный зелёный стол
        setupPokerTable()
        
        // Отображаем количество игроков (для проверки)
        showPlayerCount()
    }
    
    private func setupPokerTable() {
        // Размеры овального стола для горизонтальной ориентации
        let tableWidth = self.size.width * 0.75
        let tableHeight = self.size.height * 0.85
        let outerTableSize = CGSize(width: tableWidth, height: tableHeight)
        let innerTableSize = CGSize(width: tableWidth * 0.92, height: tableHeight * 0.92)
        
        let centerPosition = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // Внешний овал стола (деревянная окантовка)
        let outerTable = SKShapeNode(ellipseOf: outerTableSize)
        outerTable.position = centerPosition
        outerTable.fillColor = SKColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0) // Коричневый цвет дерева
        outerTable.strokeColor = SKColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        outerTable.lineWidth = 3
        outerTable.zPosition = 1
        
        self.pokerTable = outerTable
        self.addChild(outerTable)
        
        // Внутренний овал (зелёное сукно)
        let innerTable = SKShapeNode(ellipseOf: innerTableSize)
        innerTable.position = centerPosition
        
        // Красивый зелёный цвет покерного стола
        innerTable.fillColor = SKColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0) // Forest Green
        innerTable.strokeColor = SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)
        innerTable.lineWidth = 2
        innerTable.zPosition = 2
        
        self.tableInner = innerTable
        self.addChild(innerTable)
        
        // Добавляем декоративную линию по краю зелёного поля
        let decorativeBorderSize = CGSize(width: innerTableSize.width - 10, height: innerTableSize.height - 10)
        let decorativeBorder = SKShapeNode(ellipseOf: decorativeBorderSize)
        decorativeBorder.position = centerPosition
        decorativeBorder.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.6) // Золотистый
        decorativeBorder.lineWidth = 1.5
        decorativeBorder.fillColor = .clear
        decorativeBorder.zPosition = 3
        self.addChild(decorativeBorder)
        
        // Добавляем текстуру/паттерн на зелёное поле для реалистичности
        addTableTexture(size: innerTableSize)
    }
    
    private func addTableTexture(size: CGSize) {
        // Создаём несколько полупрозрачных кругов для имитации текстуры сукна
        let center = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // Область для текстуры ограничена овалом
        let maxWidth = size.width * 0.35
        let maxHeight = size.height * 0.35
        
        for _ in 0..<15 {
            let x = center.x + CGFloat.random(in: -maxWidth...maxWidth)
            let y = center.y + CGFloat.random(in: -maxHeight...maxHeight)
            
            let textureSpot = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...15))
            textureSpot.position = CGPoint(x: x, y: y)
            textureSpot.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 0.05)
            textureSpot.strokeColor = .clear
            textureSpot.zPosition = 2.5
            textureSpot.alpha = 0.3
            self.addChild(textureSpot)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Обработка касаний для будущей игровой логики
        for touch in touches {
            let location = touch.location(in: self)
            print("Touch at: \(location)")
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    private func showPlayerCount() {
        // Добавляем текст с количеством игроков для проверки
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "Игроков: \(playerCount)"
        label.fontSize = 24
        label.fontColor = .white
        label.position = CGPoint(x: self.size.width / 2, y: self.size.height - 50)
        label.zPosition = 100
        self.addChild(label)
    }
}
