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
    private var players: [PlayerNode] = []
    private var dealButton: SKShapeNode?
    private var dealButtonLabel: SKLabelNode?
    
    // Размеры стола (для расчёта позиций игроков)
    private var tableWidth: CGFloat = 0
    private var tableHeight: CGFloat = 0
    
    override func didMove(to view: SKView) {
        // Устанавливаем фон сцены - темно-синий
        self.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        // Создаём овальный зелёный стол
        setupPokerTable()
        
        // Размещаем игроков вокруг стола
        setupPlayers()
        
        // Создаём кнопку "Раздать карты"
        setupDealButton()
    }
    
    private func setupPokerTable() {
        // Размеры овального стола для горизонтальной ориентации (уменьшены для размещения имён)
        tableWidth = self.size.width * 0.70
        tableHeight = self.size.height * 0.70
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
            
            // Проверяем, нажата ли кнопка "Раздать карты"
            if let button = dealButton, button.contains(location) {
                handleDealButtonTap()
                return
            }
            
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
    
    // MARK: - Настройка игроков
    
    private func setupPlayers() {
        let center = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // Радиусы овала для позиционирования игроков (снаружи стола)
        let radiusX = tableWidth / 2 + 80
        let radiusY = tableHeight / 2 + 80
        
        // Аватары для игроков (эмодзи людей)
        let avatars = ["👨‍💼", "👩‍💼", "🧔", "👨‍🦰", "👩‍🦱"]
        
        for i in 0..<playerCount {
            // Расчёт угла для равномерного распределения
            // Начинаем с нижней части стола и идём по часовой стрелке
            let angle = -CGFloat(i) * (2.0 * .pi / CGFloat(playerCount)) - (.pi / 2)
            
            // Вычисляем позицию на овале
            let x = center.x + radiusX * cos(angle)
            let y = center.y + radiusY * sin(angle)
            
            // Создаём игрока
            let playerNode = PlayerNode(
                playerNumber: i + 1,
                avatar: avatars[i % avatars.count],
                position: CGPoint(x: x, y: y),
                angle: angle,
                totalPlayers: playerCount
            )
            
            players.append(playerNode)
            self.addChild(playerNode)
        }
    }
    
    // MARK: - Кнопка "Раздать карты"
    
    private func setupDealButton() {
        // Размеры кнопки (увеличены в 2 раза)
        let buttonWidth: CGFloat = 360
        let buttonHeight: CGFloat = 100
        let cornerRadius: CGFloat = 24
        
        // Позиция: левый край кнопки на расстоянии 50 от края экрана, поднята выше
        let buttonX: CGFloat = 50 + buttonWidth / 2  // сдвиг вправо еще на 25
        let buttonY: CGFloat = buttonHeight / 2 + 50   // поднята еще на 25
        
        // Создаём прямоугольник с закруглёнными углами для кнопки
        let buttonRect = CGRect(
            x: -buttonWidth / 2,
            y: -buttonHeight / 2,
            width: buttonWidth,
            height: buttonHeight
        )
        let button = SKShapeNode(rect: buttonRect, cornerRadius: cornerRadius)
        button.position = CGPoint(x: buttonX, y: buttonY)
        
        // Стильный красный цвет для кнопки (как фишки в покере)
        button.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.65, green: 0.1, blue: 0.1, alpha: 1.0)
        button.lineWidth = 3
        button.zPosition = 100
        
        // Добавляем эффект градиента с помощью дополнительного слоя
        let highlightRect = CGRect(
            x: -buttonWidth / 2,
            y: 0,
            width: buttonWidth,
            height: buttonHeight / 2
        )
        let highlight = SKShapeNode(rect: highlightRect, cornerRadius: cornerRadius)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        highlight.strokeColor = .clear
        highlight.zPosition = 1
        button.addChild(highlight)
        
        self.dealButton = button
        self.addChild(button)
        
        // Создаём текст на кнопке
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "Раздать карты"
        label.fontSize = 40
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 2
        
        // Добавляем тень для текста
        let shadow = SKLabelNode(fontNamed: "Helvetica-Bold")
        shadow.text = "Раздать карты"
        shadow.fontSize = 40
        shadow.fontColor = SKColor(white: 0.0, alpha: 0.5)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = 1
        button.addChild(shadow)
        
        button.addChild(label)
        self.dealButtonLabel = label
    }
    
    private func handleDealButtonTap() {
        // Анимация нажатия кнопки
        guard let button = dealButton else { return }
        
        // Эффект нажатия
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let pulse = SKAction.sequence([scaleDown, scaleUp])
        
        button.run(pulse) {
            // Здесь будет логика раздачи карт
            print("Раздача карт...")
            // TODO: Добавить логику раздачи карт игрокам
        }
    }
}
