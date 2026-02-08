//
//  CardDemoScene.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//
//  Демонстрационная сцена для показа всех типов карт

import SpriteKit

class CardDemoScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        setupDemo()
    }
    
    private func setupDemo() {
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "Демонстрация карт"
        title.fontSize = 32
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(title)
        
        // Демонстрация всех мастей и рангов
        var yPosition: CGFloat = size.height - 120
        let suits: [(Suit, String)] = [
            (.diamonds, "Бубны"),
            (.hearts, "Черви"),
            (.spades, "Пики"),
            (.clubs, "Крести")
        ]
        
        for (suit, suitName) in suits {
            // Заголовок масти
            let suitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            suitLabel.text = suitName
            suitLabel.fontSize = 20
            suitLabel.fontColor = suit.color == .red ?
                SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) :
                SKColor(white: 0.9, alpha: 1.0)
            suitLabel.horizontalAlignmentMode = .left
            suitLabel.position = CGPoint(x: 30, y: yPosition)
            addChild(suitLabel)
            
            yPosition -= 30
            
            // Карты этой масти
            var xPosition: CGFloat = 50
            let startRank: Rank = (suit == .spades || suit == .clubs) ? .seven : .six
            let allRanks: [Rank] = Rank.allCases.filter { $0.rawValue >= startRank.rawValue }
            
            for rank in allRanks {
                let card = Card(suit: suit, rank: rank)
                let cardNode = CardNode(card: card, faceUp: true)
                cardNode.position = CGPoint(x: xPosition, y: yPosition - 60)
                cardNode.setScale(0.8)
                addChild(cardNode)
                
                xPosition += 75
            }
            
            yPosition -= 150
        }
        
        // Джокеры
        let jokerLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        jokerLabel.text = "Джокеры"
        jokerLabel.fontSize = 20
        jokerLabel.fontColor = SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)
        jokerLabel.horizontalAlignmentMode = .left
        jokerLabel.position = CGPoint(x: 30, y: yPosition)
        addChild(jokerLabel)
        
        yPosition -= 30
        
        // Два джокера
        for i in 0..<2 {
            let joker = Card(joker: true)
            let jokerNode = CardNode(card: joker, faceUp: true)
            jokerNode.position = CGPoint(x: 50 + CGFloat(i) * 100, y: yPosition - 60)
            jokerNode.setScale(0.8)
            addChild(jokerNode)
        }
        
        yPosition -= 150
        
        // Рубашка карты
        let backLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        backLabel.text = "Рубашка карты"
        backLabel.fontSize = 20
        backLabel.fontColor = .white
        backLabel.horizontalAlignmentMode = .left
        backLabel.position = CGPoint(x: 30, y: yPosition)
        addChild(backLabel)
        
        yPosition -= 30
        
        let backCard = Card(suit: .diamonds, rank: .ace)
        let backNode = CardNode(card: backCard, faceUp: false)
        backNode.position = CGPoint(x: 90, y: yPosition - 60)
        backNode.setScale(0.8)
        addChild(backNode)
        
        // Анимация переворота
        let flipCard = Card(suit: .hearts, rank: .king)
        let flipNode = CardNode(card: flipCard, faceUp: false)
        flipNode.position = CGPoint(x: 200, y: yPosition - 60)
        flipNode.setScale(0.8)
        addChild(flipNode)
        
        // Бесконечная анимация переворота
        let wait = SKAction.wait(forDuration: 2.0)
        let flip = SKAction.run { [weak flipNode] in
            flipNode?.flip(animated: true)
        }
        let sequence = SKAction.sequence([wait, flip])
        flipNode.run(SKAction.repeatForever(sequence))
        
        // Подсвеченная карта
        let highlightCard = Card(suit: .spades, rank: .ace)
        let highlightNode = CardNode(card: highlightCard, faceUp: true)
        highlightNode.position = CGPoint(x: 310, y: yPosition - 60)
        highlightNode.setScale(0.8)
        highlightNode.highlight(true, color: .yellow)
        addChild(highlightNode)
        
        // Демонстрация колоды
        yPosition -= 180
        
        let deckLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        deckLabel.text = "Статистика колоды:"
        deckLabel.fontSize = 20
        deckLabel.fontColor = .white
        deckLabel.horizontalAlignmentMode = .left
        deckLabel.position = CGPoint(x: 30, y: yPosition)
        addChild(deckLabel)
        
        let deck = Deck()
        let stats = [
            "Всего карт: \(deck.count)",
            "Джокеров: 2",
            "Бубны: 9 карт (6-Туз)",
            "Черви: 9 карт (6-Туз)",
            "Пики: 8 карт (7-Туз)",
            "Крести: 8 карт (7-Туз)"
        ]
        
        yPosition -= 25
        for stat in stats {
            let statLabel = SKLabelNode(fontNamed: "Helvetica")
            statLabel.text = stat
            statLabel.fontSize = 16
            statLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
            statLabel.horizontalAlignmentMode = .left
            statLabel.position = CGPoint(x: 50, y: yPosition)
            addChild(statLabel)
            yPosition -= 22
        }
        
        // Инструкция
        let instruction = SKLabelNode(fontNamed: "Helvetica")
        instruction.text = "Нажмите в любом месте, чтобы вернуться"
        instruction.fontSize = 18
        instruction.fontColor = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        instruction.position = CGPoint(x: size.width / 2, y: 30)
        addChild(instruction)
        
        // Пульсация инструкции
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 1.0)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        let pulse = SKAction.sequence([fadeOut, fadeIn])
        instruction.run(SKAction.repeatForever(pulse))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Возврат к главной сцене
        // В реальном приложении здесь будет переход к GameScene
        print("Возврат к игре...")
    }
}

