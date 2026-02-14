//
//  TrickNode.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit

/// Нода для отображения текущей взятки (карт на столе)
class TrickNode: SKNode {
    
    // MARK: - Properties
    
    private(set) var playedCards: [(card: Card, player: Int, cardNode: CardNode)] = []
    var centerPosition: CGPoint = .zero
    var cardRadius: CGFloat = 100  // Радиус размещения карт вокруг центра
    
    // MARK: - Public Methods
    
    /// Добавить карту в текущую взятку
    func playCard(
        _ card: Card,
        fromPlayer playerNumber: Int,
        to targetPosition: CGPoint? = nil,
        animated: Bool = true
    ) -> CardNode {
        let cardNode = CardNode(card: card, faceUp: true)
        cardNode.zPosition = CGFloat(playedCards.count)
        
        // Вычисляем позицию для карты
        let resolvedTargetPosition: CGPoint
        if let targetPosition {
            resolvedTargetPosition = targetPosition
        } else {
            let angle = CGFloat(playedCards.count) * (.pi / 2)  // 90 градусов между картами
            let x = centerPosition.x + cardRadius * cos(angle)
            let y = centerPosition.y + cardRadius * sin(angle)
            resolvedTargetPosition = CGPoint(x: x, y: y)
        }
        
        playedCards.append((card, playerNumber, cardNode))
        addChild(cardNode)
        
        if animated {
            // Начинаем с невидимой карты в центре
            cardNode.position = centerPosition
            cardNode.alpha = 0
            cardNode.setScale(0.5)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let scale = SKAction.scale(to: 1.0, duration: 0.3)
            let move = SKAction.move(to: resolvedTargetPosition, duration: 0.3)
            let rotate = SKAction.rotate(byAngle: .pi * 0.1, duration: 0.3)
            
            let group = SKAction.group([fadeIn, scale, move, rotate])
            group.timingMode = .easeOut
            cardNode.run(group)
        } else {
            cardNode.position = resolvedTargetPosition
        }
        
        return cardNode
    }
    
    /// Очистить взятку (забрать карты)
    func clearTrick(toPosition position: CGPoint, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !playedCards.isEmpty else {
            completion?()
            return
        }
        
        if animated {
            var completionCount = 0
            let totalCards = playedCards.count
            
            for (_, _, cardNode) in playedCards {
                let move = SKAction.move(to: position, duration: 0.4)
                let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                let scale = SKAction.scale(to: 0.5, duration: 0.4)
                let group = SKAction.group([move, fadeOut, scale])
                
                cardNode.run(group) {
                    cardNode.removeFromParent()
                    completionCount += 1
                    
                    if completionCount == totalCards {
                        completion?()
                    }
                }
            }
        } else {
            playedCards.forEach { $0.cardNode.removeFromParent() }
            completion?()
        }
        
        playedCards.removeAll()
    }
    
    /// Определить победителя взятки
    func determineWinner(trump: Suit?) -> Int? {
        let normalizedCards = playedCards.map { entry in
            (playerIndex: entry.player - 1, card: entry.card)
        }

        guard let winnerIndex = TrickTakingResolver.winnerPlayerIndex(
            playedCards: normalizedCards,
            trump: trump
        ) else {
            return nil
        }

        // Внутри TrickNode игрок хранится как номер (1...N), возвращаем совместимый формат.
        return winnerIndex + 1
    }
    
    /// Получить карты текущей взятки
    func getCards() -> [Card] {
        return playedCards.map { $0.card }
    }
    
    /// Проверить, можно ли сыграть карту
    func canPlayCard(_ card: Card, fromHand hand: [Card], trump: Suit?) -> Bool {
        // Если это первая карта - можно любую
        guard !playedCards.isEmpty else { return true }
        
        let leadCard = playedCards[0].card
        
        // Джокер можно всегда
        if card.isJoker {
            return true
        }
        
        guard let leadSuit = leadCard.suit else {
            // Первая карта - джокер, можно любую
            return true
        }
        
        guard let cardSuit = card.suit else {
            return true  // Джокер
        }
        
        // Должны следовать в масть
        if cardSuit == leadSuit {
            return true
        }
        
        // Проверяем, есть ли карты нужной масти в руке
        let hasLeadSuit = hand.contains { card in
            if let suit = card.suit {
                return suit == leadSuit
            }
            return false
        }
        
        if hasLeadSuit {
            // Есть карты нужной масти - нельзя играть другую масть
            return false
        }
        
        // Нет карт нужной масти - можно играть козырь или любую карту
        return true
    }
}
