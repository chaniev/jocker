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
    var isVertical: Bool = false        // Вертикальное или горизонтальное расположение
    var isFaceUp: Bool = true           // Показывать ли карты лицом
    var orientationRotation: CGFloat = 0 // Базовый поворот всей руки
    
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
    
    /// Расположить карты в руке: один ряд с перекрыванием
    func arrangeCards(animated: Bool = true) {
        let count = cardNodes.count
        guard count > 0 else { return }
        
        let duration: TimeInterval = animated ? 0.3 : 0
        let overlap = min(max(cardOverlapRatio, 0.0), 0.92)
        let cardAxisSize = isVertical ? CardNode.cardHeight : CardNode.cardWidth
        let spacingFromOverlap = cardAxisSize * (1.0 - overlap)
        let minimumReveal = cardAxisSize * (isVertical ? 0.28 : 0.37)
        let effectiveSpacing = min(
            cardAxisSize,
            max(minimumReveal, max(cardSpacing, spacingFromOverlap))
        )
        let totalSpan = CGFloat(count - 1) * effectiveSpacing
        let startOffset = -totalSpan / 2
        
        for (index, cardNode) in cardNodes.enumerated() {
            let axisOffset = startOffset + CGFloat(index) * effectiveSpacing
            let x = isVertical ? handPosition.x : handPosition.x + axisOffset
            let y = isVertical ? handPosition.y + axisOffset : handPosition.y
            
            let position = CGPoint(x: x, y: y)
            let move = SKAction.move(to: position, duration: duration)
            let rotate = SKAction.rotate(toAngle: orientationRotation, duration: duration)
            
            // Последующие карты идут поверх предыдущих: виден индекс/масть на нижних картах.
            cardNode.zPosition = CGFloat(100 + index)
            cardNode.run(SKAction.group([move, rotate]))
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
