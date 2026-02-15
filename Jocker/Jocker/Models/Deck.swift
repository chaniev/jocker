//
//  Deck.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Колода карт
struct Deck {
    private(set) var cards: [Card] = []
    
    /// Создаёт стандартную колоду для игры
    init() {
        createStandardDeck()
    }
    
    /// Создание стандартной колоды из 36 карт с 2 джокерами.
    /// По правилам 6♠ и 6♣ заменяются на джокеров.
    private mutating func createStandardDeck() {
        cards.removeAll()
        
        // Добавляем бубны от 6 до туза
        for rank in Rank.allCases {
            cards.append(.regular(suit: .diamonds, rank: rank))
        }
        
        // Добавляем черви от 6 до туза
        for rank in Rank.allCases {
            cards.append(.regular(suit: .hearts, rank: rank))
        }
        
        // Добавляем пики от 7 до туза; 6♠ заменяем первым джокером.
        cards.append(.joker)
        for rank in Rank.allCases where rank != .six {
            cards.append(.regular(suit: .spades, rank: rank))
        }
        
        // Добавляем крести от 7 до туза; 6♣ заменяем вторым джокером.
        cards.append(.joker)
        for rank in Rank.allCases where rank != .six {
            cards.append(.regular(suit: .clubs, rank: rank))
        }
    }
    
    /// Перемешивание колоды
    mutating func shuffle() {
        cards.shuffle()
    }
    
    /// Взять верхнюю карту
    mutating func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }
    
    /// Взять несколько карт
    mutating func drawCards(count: Int) -> [Card] {
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
    mutating func returnCard(_ card: Card) {
        cards.append(card)
    }
    
    /// Вернуть карты в колоду
    mutating func returnCards(_ cards: [Card]) {
        self.cards.append(contentsOf: cards)
    }
    
    /// Количество оставшихся карт
    var count: Int {
        return cards.count
    }
    
    /// Сброс колоды и создание новой
    mutating func reset() {
        createStandardDeck()
    }
    
    /// Раздача карт игрокам
    /// - Parameters:
    ///   - playerCount: количество игроков
    ///   - cardsPerPlayer: количество карт каждому игроку
    ///   - startingPlayerIndex: индекс игрока, который получает первую карту
    /// - Returns: массив рук для каждого игрока и козырная карта (если есть)
    mutating func dealCards(
        playerCount: Int,
        cardsPerPlayer: Int,
        startingPlayerIndex: Int = 0
    ) -> (hands: [[Card]], trump: Card?) {
        var hands: [[Card]] = Array(repeating: [], count: playerCount)
        let normalizedStartIndex = playerCount > 0
            ? ((startingPlayerIndex % playerCount) + playerCount) % playerCount
            : 0
        
        // Раздаём карты по очереди каждому игроку
        for _ in 0..<cardsPerPlayer {
            for offset in 0..<playerCount {
                let playerIndex = (normalizedStartIndex + offset) % playerCount
                if let card = drawCard() {
                    hands[playerIndex].append(card)
                }
            }
        }
        
        // Верхняя карта становится козырем только если остались карты в колоде
        let trumpCard: Card? = cards.isEmpty ? nil : peekTopCard()
        
        return (hands, trumpCard)
    }

    /// Выбор первого раздающего:
    /// 1) верхняя карта уходит "на кон" (в центр),
    /// 2) затем карты по одной выдаются игрокам по кругу,
    ///    пока кому-либо не попадётся туз.
    /// - Parameters:
    ///   - playerCount: количество игроков
    ///   - startingPlayerIndex: индекс первого игрока в круге раздачи (обычно слева)
    /// - Returns: индекс игрока, получившего первого туза
    mutating func selectFirstDealer(
        playerCount: Int,
        startingPlayerIndex: Int
    ) -> Int {
        guard playerCount > 0 else { return 0 }

        let normalizedStartIndex = ((startingPlayerIndex % playerCount) + playerCount) % playerCount

        // Верхняя карта уходит в центр кона и не участвует в выборе раздающего.
        _ = drawCard()

        var currentPlayerIndex = normalizedStartIndex
        while let card = drawCard() {
            if card.rank == .ace {
                return currentPlayerIndex
            }
            currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        }

        // На полной колоде до этого дойти нельзя, но оставляем безопасный fallback.
        return normalizedStartIndex
    }
}
