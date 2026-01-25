//
//  Deck.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Колода карт
class Deck {
    private(set) var cards: [Card] = []
    
    /// Создаёт стандартную колоду для игры
    init() {
        createStandardDeck()
    }
    
    /// Создание стандартной колоды из 36 карт с 2 джокерами
    /// 6♦️ и 6♣️ заменяются на джокеров
    private func createStandardDeck() {
        cards.removeAll()
        
        // Добавляем бубны от 6 до туза
        for rank in Rank.allCases {
            if rank == .six {
                // 6♦️ заменяем на джокера
                cards.append(Card(joker: true))
            } else {
                cards.append(Card(suit: .diamonds, rank: rank))
            }
        }
        
        // Добавляем черви от 6 до туза
        for rank in Rank.allCases {
            cards.append(Card(suit: .hearts, rank: rank))
        }
        
        // Добавляем пики от 7 до туза (нет шестёрки)
        for rank in Rank.allCases where rank != .six {
            cards.append(Card(suit: .spades, rank: rank))
        }
        
        // Добавляем крести от 7 до туза (6♣️ заменяем на джокера)
        cards.append(Card(joker: true))  // Второй джокер
        for rank in Rank.allCases where rank != .six {
            cards.append(Card(suit: .clubs, rank: rank))
        }
    }
    
    /// Перемешивание колоды
    func shuffle() {
        cards.shuffle()
    }
    
    /// Взять верхнюю карту
    func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }
    
    /// Взять несколько карт
    func drawCards(count: Int) -> [Card] {
        var drawnCards: [Card] = []
        for _ in 0..<min(count, cards.count) {
            if let card = drawCard() {
                drawnCards.append(card)
            }
        }
        return drawnCards
    }
    
    /// Посмотреть верхнюю карту без взятия
    func peekTopCard() -> Card? {
        return cards.first
    }
    
    /// Вернуть карту в колоду
    func returnCard(_ card: Card) {
        cards.append(card)
    }
    
    /// Вернуть карты в колоду
    func returnCards(_ cards: [Card]) {
        self.cards.append(contentsOf: cards)
    }
    
    /// Количество оставшихся карт
    var count: Int {
        return cards.count
    }
    
    /// Сброс колоды и создание новой
    func reset() {
        createStandardDeck()
    }
    
    /// Раздача карт игрокам
    /// - Parameters:
    ///   - playerCount: количество игроков
    ///   - cardsPerPlayer: количество карт каждому игроку
    /// - Returns: массив рук для каждого игрока и козырная карта (если есть)
    func dealCards(playerCount: Int, cardsPerPlayer: Int) -> (hands: [[Card]], trump: Card?) {
        var hands: [[Card]] = Array(repeating: [], count: playerCount)
        
        // Раздаём карты по очереди каждому игроку
        for _ in 0..<cardsPerPlayer {
            for playerIndex in 0..<playerCount {
                if let card = drawCard() {
                    hands[playerIndex].append(card)
                }
            }
        }
        
        // Верхняя карта становится козырем только если остались карты в колоде
        // Если все карты розданы, козыря нет
        let trumpCard: Card?
        if cards.isEmpty {
            // Все карты розданы - козыря нет
            trumpCard = nil
        } else {
            // Остались карты - верхняя карта становится козырем
            trumpCard = peekTopCard()
        }
        
        return (hands, trumpCard)
    }
}
