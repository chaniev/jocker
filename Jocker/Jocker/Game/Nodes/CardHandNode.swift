//
//  CardHandNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit

/// Нода для отображения руки игрока с картами
class CardHandNode: SKNode {
    
    // MARK: - Properties
    
    private(set) var cards: [Card] = []
    private(set) var cardNodes: [CardNode] = []
    
    var handPosition: CGPoint = .zero
    var cardSpacing: CGFloat = 60       // Расстояние между картами (центрами)
    var cardOverlapRatio: CGFloat = 0.3  // Коэффициент перекрывания карт (0.0 = нет, 1.0 = полное)
    var arcAngle: CGFloat = 0.3         // Угол дуги для раскладки карт (в радианах)
    var isVertical: Bool = false        // Вертикальное или горизонтальное расположение
    var isFaceUp: Bool = true           // Показывать ли карты лицом
    
    // Callback при выборе карты
    var onCardSelected: ((Card, CardNode) -> Void)?
    
    // MARK: - Public Methods
    
    /// Добавить карту в руку
    func addCard(_ card: Card, animated: Bool = true) {
        cards.append(card)
        
        let cardNode = CardNode(card: card, faceUp: isFaceUp)
        cardNode.zPosition = CGFloat(cardNodes.count)
        cardNodes.append(cardNode)
        addChild(cardNode)
        
        if animated {
            cardNode.alpha = 0
            cardNode.setScale(0.5)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let scale = SKAction.scale(to: 1.0, duration: 0.2)
            let group = SKAction.group([fadeIn, scale])
            
            cardNode.run(group) { [weak self] in
                self?.arrangeCards(animated: true)
            }
        } else {
            arrangeCards(animated: false)
        }
    }
    
    /// Добавить несколько карт
    func addCards(_ cards: [Card], animated: Bool = true) {
        if animated {
            var delay: TimeInterval = 0
            for card in cards {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.addCard(card, animated: true)
                }
                delay += 0.1
            }
        } else {
            for card in cards {
                addCard(card, animated: false)
            }
        }
    }
    
    /// Удалить карту из руки
    func removeCard(_ card: Card, animated: Bool = true) -> CardNode? {
        guard let index = cards.firstIndex(of: card) else { return nil }
        
        cards.remove(at: index)
        let cardNode = cardNodes.remove(at: index)
        
        if animated {
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let scale = SKAction.scale(to: 0.5, duration: 0.2)
            let group = SKAction.group([fadeOut, scale])
            
            cardNode.run(group) { [weak cardNode] in
                cardNode?.removeFromParent()
            }
            
            arrangeCards(animated: true)
        } else {
            cardNode.removeFromParent()
            arrangeCards(animated: false)
        }
        
        return cardNode
    }
    
    /// Очистить всю руку
    func removeAllCards(animated: Bool = true) {
        if animated {
            for (index, cardNode) in cardNodes.enumerated() {
                let delay = TimeInterval(index) * 0.05
                let wait = SKAction.wait(forDuration: delay)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let scale = SKAction.scale(to: 0.5, duration: 0.2)
                let group = SKAction.group([fadeOut, scale])
                let sequence = SKAction.sequence([wait, group, SKAction.removeFromParent()])
                
                cardNode.run(sequence)
            }
        } else {
            cardNodes.forEach { $0.removeFromParent() }
        }
        
        cards.removeAll()
        cardNodes.removeAll()
    }
    
    /// Расположить карты в руке (стиль покерного стола с перекрыванием)
    func arrangeCards(animated: Bool = true) {
        let count = cardNodes.count
        guard count > 0 else { return }
        
        let duration: TimeInterval = animated ? 0.3 : 0
        
        if count == 1 {
            // Одна карта - в центре
            let move = SKAction.move(to: handPosition, duration: duration)
            let rotate = SKAction.rotate(toAngle: 0, duration: duration)
            cardNodes[0].run(SKAction.group([move, rotate]))
        } else {
            // Несколько карт - веерная раскладка с перекрыванием (как в покере)
            let totalWidth = CGFloat(count - 1) * cardSpacing
            let startX = handPosition.x - totalWidth / 2
            
            // Радиус дуги для создания веерного эффекта
            let arcRadius: CGFloat = 400.0  // Больший радиус = более плоская дуга
            
            for (index, cardNode) in cardNodes.enumerated() {
                let progress = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0.5
                
                // Угол поворота карты для веерного эффекта
                let angle = (progress - 0.5) * arcAngle
                
                let x: CGFloat
                let y: CGFloat
                
                if isVertical {
                    // Вертикальное расположение (для боковых игроков)
                    // Небольшое смещение по X для веерного эффекта
                    let horizontalOffset = sin(angle) * 15
                    x = handPosition.x + horizontalOffset
                    y = startX + CGFloat(index) * cardSpacing
                } else {
                    // Горизонтальное расположение (для игроков сверху/снизу)
                    x = startX + CGFloat(index) * cardSpacing
                    
                    // Создаём дугу с помощью окружности (более реалистичный веер)
                    // Чем дальше от центра, тем ниже карта
                    let distanceFromCenter = abs(progress - 0.5) * 2.0  // 0.0 в центре, 1.0 по краям
                    let arcHeight = (1.0 - distanceFromCenter * distanceFromCenter) * arcRadius
                    let yOffset = arcRadius - arcHeight
                    
                    y = handPosition.y - yOffset * 0.12  // Коэффициент для настройки высоты дуги
                }
                
                let position = CGPoint(x: x, y: y)
                let move = SKAction.move(to: position, duration: duration)
                let rotate = SKAction.rotate(toAngle: angle, duration: duration)
                
                // Z-позиция: карты в центре должны быть выше
                // Это создаёт эффект "вложенности" как в покере
                let centerDistance = abs(Float(index) - Float(count - 1) / 2.0)
                let maxDistance = Float(count - 1) / 2.0
                let zPosition = CGFloat(100 - Int(centerDistance / maxDistance * 50))
                cardNode.zPosition = zPosition
                
                cardNode.run(SKAction.group([move, rotate]))
            }
        }
    }
    
    /// Подсветить карты, которые можно сыграть
    func highlightPlayableCards(_ playableCards: [Card]) {
        for cardNode in cardNodes {
            let isPlayable = playableCards.contains(cardNode.card)
            cardNode.highlight(isPlayable)
        }
    }
    
    /// Снять подсветку со всех карт
    func removeAllHighlights() {
        for cardNode in cardNodes {
            cardNode.highlight(false)
        }
    }
    
    /// Перевернуть все карты
    func flipAllCards(faceUp: Bool, animated: Bool = true) {
        self.isFaceUp = faceUp
        
        for (index, cardNode) in cardNodes.enumerated() {
            if cardNode.isFaceUp != faceUp {
                if animated {
                    let delay = TimeInterval(index) * 0.05
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        cardNode.flip(animated: true)
                    }
                } else {
                    cardNode.flip(animated: false)
                }
            }
        }
    }
    
    /// Отсортировать карты в руке
    func sortCards(by sortFunction: (Card, Card) -> Bool, animated: Bool = true) {
        let sortedIndices = cards.enumerated().sorted { sortFunction($0.element, $1.element) }.map { $0.offset }
        
        var newCards: [Card] = []
        var newCardNodes: [CardNode] = []
        
        for index in sortedIndices {
            newCards.append(cards[index])
            newCardNodes.append(cardNodes[index])
        }
        
        cards = newCards
        cardNodes = newCardNodes
        
        arrangeCards(animated: animated)
    }
    
    /// Стандартная сортировка (по масти и рангу, джокеры в конец)
    func sortCardsStandard(animated: Bool = true) {
        sortCards(by: { $0 < $1 }, animated: animated)
    }
}

