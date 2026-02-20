//
//  Deck.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation
import Security

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
        guard cards.count > 1 else { return }

        performHumanStyleMixPasses()
        fisherYatesShuffleWithSecureRandom()
    }

    /// Имитирует "живое" перемешивание: несколько проходов cut + riffle.
    ///
    /// Это улучшает визуальное ощущение случайности перед финальным
    /// равномерным Fisher-Yates.
    private mutating func performHumanStyleMixPasses() {
        let passCount = secureRandomInt(in: 2...4)
        for _ in 0..<passCount {
            applyRandomCut()
            applyRifflePass()
        }
    }

    /// Случайный срез колоды около середины.
    private mutating func applyRandomCut() {
        guard cards.count > 1 else { return }

        let midpoint = cards.count / 2
        let spread = max(1, cards.count / 5)
        let minCut = max(1, midpoint - spread)
        let maxCut = min(cards.count - 1, midpoint + spread)
        let cutIndex = secureRandomInt(in: minCut...maxCut)

        let rotated = cards[cutIndex...] + cards[..<cutIndex]
        cards = Array(rotated)
    }

    /// Riffle-проход: две пачки интерливятся небольшими случайными блоками.
    private mutating func applyRifflePass() {
        guard cards.count > 1 else { return }

        let midpoint = cards.count / 2
        let splitJitter = max(1, cards.count / 6)
        let minSplit = max(1, midpoint - splitJitter)
        let maxSplit = min(cards.count - 1, midpoint + splitJitter)
        let splitIndex = secureRandomInt(in: minSplit...maxSplit)

        let left = Array(cards[..<splitIndex])
        let right = Array(cards[splitIndex...])

        var mixed: [Card] = []
        mixed.reserveCapacity(cards.count)

        var leftIndex = 0
        var rightIndex = 0

        while leftIndex < left.count || rightIndex < right.count {
            let takeLeft: Bool
            if leftIndex >= left.count {
                takeLeft = false
            } else if rightIndex >= right.count {
                takeLeft = true
            } else {
                let leftRemaining = left.count - leftIndex
                let rightRemaining = right.count - rightIndex
                let roll = secureRandomInt(in: 1...(leftRemaining + rightRemaining))
                takeLeft = roll <= leftRemaining
            }

            let chunkSize = secureRandomInt(in: 1...3)
            if takeLeft {
                let end = min(leftIndex + chunkSize, left.count)
                mixed.append(contentsOf: left[leftIndex..<end])
                leftIndex = end
            } else {
                let end = min(rightIndex + chunkSize, right.count)
                mixed.append(contentsOf: right[rightIndex..<end])
                rightIndex = end
            }
        }

        cards = mixed
    }

    /// Финальный unbiased Fisher-Yates с криптостойким источником случайных чисел.
    private mutating func fisherYatesShuffleWithSecureRandom() {
        guard cards.count > 1 else { return }

        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let swapIndex = secureRandomInt(in: 0...index)
            guard index != swapIndex else { continue }
            cards.swapAt(index, swapIndex)
        }
    }

    /// Случайное число в диапазоне без modulo bias (rejection sampling).
    ///
    /// Важно: seed от времени не используется.
    private func secureRandomInt(in range: ClosedRange<Int>) -> Int {
        precondition(range.lowerBound <= range.upperBound)
        if range.lowerBound == range.upperBound {
            return range.lowerBound
        }

        let width = UInt64(range.upperBound - range.lowerBound + 1)
        let limit = UInt64.max - (UInt64.max % width)

        var value: UInt64 = 0
        repeat {
            value = secureRandomUInt64()
        } while value >= limit

        return range.lowerBound + Int(value % width)
    }

    private func secureRandomUInt64() -> UInt64 {
        var value: UInt64 = 0
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            MemoryLayout<UInt64>.size,
            &value
        )
        if status == errSecSuccess {
            return value
        }

        // Fallback на системный генератор без ручного seed.
        var fallbackGenerator = SystemRandomNumberGenerator()
        return fallbackGenerator.next()
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
        return prepareFirstDealerSelection(
            playerCount: playerCount,
            startingPlayerIndex: startingPlayerIndex
        ).dealerIndex
    }

    /// Подготавливает последовательность карт для визуального выбора первого раздающего.
    ///
    /// Процедура совпадает с `selectFirstDealer`: верхняя карта уходит в центр,
    /// затем карты по одной выдаются игрокам по кругу до первого туза.
    /// - Parameters:
    ///   - playerCount: количество игроков
    ///   - startingPlayerIndex: индекс первого игрока в круге
    /// - Returns:
    ///   - tableCard: карта, ушедшая в центр (на кон)
    ///   - dealtCards: выданные карты в порядке раздачи
    ///   - dealerIndex: индекс игрока, получившего первого туза
    mutating func prepareFirstDealerSelection(
        playerCount: Int,
        startingPlayerIndex: Int
    ) -> (
        tableCard: Card?,
        dealtCards: [(playerIndex: Int, card: Card)],
        dealerIndex: Int
    ) {
        guard playerCount > 0 else {
            return (tableCard: nil, dealtCards: [], dealerIndex: 0)
        }

        let normalizedStartIndex = ((startingPlayerIndex % playerCount) + playerCount) % playerCount
        let tableCard = drawCard()

        var dealtCards: [(playerIndex: Int, card: Card)] = []
        var currentPlayerIndex = normalizedStartIndex

        while let card = drawCard() {
            dealtCards.append((playerIndex: currentPlayerIndex, card: card))
            if card.rank == .ace {
                return (
                    tableCard: tableCard,
                    dealtCards: dealtCards,
                    dealerIndex: currentPlayerIndex
                )
            }
            currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        }

        // На полной колоде до этого дойти нельзя, но оставляем безопасный fallback.
        return (
            tableCard: tableCard,
            dealtCards: dealtCards,
            dealerIndex: normalizedStartIndex
        )
    }
}
