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
    
    private(set) var playedCards: [PlayedTrickCard] = []
    private var playedCardNodes: [CardNode] = []
    var centerPosition: CGPoint = .zero
    var cardRadius: CGFloat = 100  // Радиус размещения карт вокруг центра
    
    // MARK: - Public Methods
    
    /// Добавить карту в текущую взятку
    func playCard(
        _ card: Card,
        fromPlayer playerNumber: Int,
        jokerPlayStyle: JokerPlayStyle = .faceUp,
        jokerLeadDeclaration: JokerLeadDeclaration? = nil,
        to targetPosition: CGPoint? = nil,
        animated: Bool = true
    ) -> CardNode {
        let resolvedJokerStyle: JokerPlayStyle = card.isJoker ? jokerPlayStyle : .faceUp
        let shouldShowFaceUp = !card.isJoker || resolvedJokerStyle == .faceUp
        let cardNode = CardNode(card: card, faceUp: shouldShowFaceUp)
        cardNode.zPosition = CGFloat(playedCards.count)

        let playerIndex = max(0, playerNumber - 1)
        let declaration = (card.isJoker && playedCards.isEmpty) ? jokerLeadDeclaration : nil
        let playedCard = PlayedTrickCard(
            playerIndex: playerIndex,
            card: card,
            jokerPlayStyle: resolvedJokerStyle,
            jokerLeadDeclaration: declaration
        )
        
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
        
        playedCards.append(playedCard)
        playedCardNodes.append(cardNode)
        addChild(cardNode)
        
        if animated {
            // Карта на кону всегда полностью непрозрачна.
            cardNode.position = centerPosition
            cardNode.setScale(0.5)
            
            let scale = SKAction.scale(to: 1.0, duration: 0.3)
            let move = SKAction.move(to: resolvedTargetPosition, duration: 0.3)
            let rotate = SKAction.rotate(byAngle: .pi * 0.1, duration: 0.3)
            
            let group = SKAction.group([scale, move, rotate])
            group.timingMode = .easeOut
            cardNode.run(group)
        } else {
            cardNode.position = resolvedTargetPosition
        }
        
        return cardNode
    }
    
    /// Очистить взятку (забрать карты)
    func clearTrick(toPosition position: CGPoint, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !playedCardNodes.isEmpty else {
            completion?()
            return
        }
        
        if animated {
            var completionCount = 0
            let totalCards = playedCardNodes.count
            
            for cardNode in playedCardNodes {
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
            playedCardNodes.forEach { $0.removeFromParent() }
            completion?()
        }
        
        playedCardNodes.removeAll()
        playedCards.removeAll()
    }
    
    /// Определить победителя взятки
    func determineWinner(trump: Suit?) -> Int? {
        guard let winnerIndex = TrickTakingResolver.winnerPlayerIndex(
            playedCards: playedCards,
            trump: trump
        ) else {
            return nil
        }

        // Возвращаем формат номера игрока (1...N) для совместимости с существующим API.
        return winnerIndex + 1
    }
    
    /// Получить карты текущей взятки
    func getCards() -> [Card] {
        return playedCards.map(\.card)
    }
    
    /// Проверить, можно ли сыграть карту
    func canPlayCard(_ card: Card, fromHand hand: [Card], trump: Suit?) -> Bool {
        // Если это первая карта - можно любую
        guard !playedCards.isEmpty else { return true }

        // Джокер можно всегда
        if card.isJoker {
            return true
        }

        guard let cardSuit = card.suit else {
            return true
        }

        // "Хочу" при заходе с джокера: остальные карты можно класть без ограничений.
        if isWishLeadMode {
            return true
        }

        guard let leadSuit = effectiveLeadSuit else {
            return true
        }

        // Должны следовать в масть
        if cardSuit == leadSuit {
            return true
        }

        // Проверяем, есть ли карты нужной масти в руке
        let hasLeadSuit = hand.contains { handCard in
            handCard.suit == leadSuit
        }

        if hasLeadSuit {
            // Есть карты нужной масти - нельзя играть другую масть
            return false
        }

        // Нет карт масти первого хода:
        // если есть козырь в руке, обязаны сыграть козырь (или джокер, обработан выше).
        if let trump {
            let hasTrump = hand.contains { handCard in
                handCard.suit == trump
            }

            if hasTrump {
                return cardSuit == trump
            }
        }

        // Нет ни масти первого хода, ни козыря — можно любую карту.
        return true
    }

    private var effectiveLeadSuit: Suit? {
        guard let leadCard = playedCards.first else { return nil }

        if !leadCard.card.isJoker {
            return leadCard.card.suit
        }

        switch leadCard.jokerLeadDeclaration {
        case .above(let suit), .takes(let suit):
            return suit
        case .wish, .none:
            return nil
        }
    }

    private var isWishLeadMode: Bool {
        guard let leadCard = playedCards.first else { return false }
        guard leadCard.card.isJoker else { return false }

        switch leadCard.jokerLeadDeclaration {
        case .wish, .none:
            return true
        case .above, .takes:
            return false
        }
    }
}
