//
//  GameState.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

/// Состояние игры
enum GamePhase {
    case notStarted      // Игра не начата
    case bidding         // Фаза ставок
    case playing         // Фаза игры (разыгрывание карт)
    case roundEnd        // Конец раунда
    case gameEnd         // Конец игры
}

/// Блок игры (всего 4 блока)
enum GameBlock: Int {
    case first = 1       // 1-й блок: возрастающее количество карт
    case second = 2      // 2-й блок: фиксированное количество карт (равное числу игроков)
    case third = 3       // 3-й блок: убывающее количество карт
    case fourth = 4      // 4-й блок: фиксированное количество карт (равное числу игроков)
}

/// Информация об игроке
class PlayerInfo {
    let playerNumber: Int
    var name: String
    var score: Int = 0
    var currentBid: Int = 0
    var tricksTaken: Int = 0
    
    init(playerNumber: Int, name: String) {
        self.playerNumber = playerNumber
        self.name = name
    }
    
    /// Рассчитать очки за раунд
    func calculateRoundScore(cardsInRound: Int) -> Int {
        let bid = currentBid
        let taken = tricksTaken
        
        // Игрок взял столько, сколько объявил
        if taken == bid {
            // Взял все карты (объявил максимум)
            if bid == cardsInRound {
                return bid * 100
            }
            // Обычное выполнение ставки
            return bid * 50 + 50
        }
        
        // Игрок взял больше
        if taken > bid {
            return taken * 10
        }
        
        // Игрок взял меньше
        let deficit = bid - taken
        
        // Объявил все карты, но не взял ни одной
        if bid == cardsInRound && taken == 0 {
            return -bid * 100
        }
        
        // Не добрал до ставки
        return -deficit * 50 - 50
    }
    
    /// Добавить очки за раунд
    func addRoundScore(cardsInRound: Int) {
        let roundScore = calculateRoundScore(cardsInRound: cardsInRound)
        score += roundScore
    }
    
    /// Сброс для нового раунда
    func resetForNewRound() {
        currentBid = 0
        tricksTaken = 0
    }
}

/// Менеджер состояния игры
class GameState {
    
    // MARK: - Properties
    
    private(set) var playerCount: Int
    private(set) var players: [PlayerInfo] = []
    private(set) var currentBlock: GameBlock = .first
    private(set) var currentRoundInBlock: Int = 0
    private(set) var currentCardsPerPlayer: Int = 1
    private(set) var currentDealer: Int = 0  // Индекс раздающего
    private(set) var currentPlayer: Int = 0  // Индекс текущего игрока
    private(set) var phase: GamePhase = .notStarted
    
    private(set) var totalRoundsInBlock: Int = 0
    
    // MARK: - Initialization
    
    init(playerCount: Int) {
        self.playerCount = playerCount
        
        // Создаём игроков
        for i in 1...playerCount {
            let player = PlayerInfo(playerNumber: i, name: "Игрок \(i)")
            players.append(player)
        }
        
        calculateRoundsInBlock()
    }
    
    // MARK: - Game Flow
    
    /// Начать игру
    func startGame() {
        currentBlock = .first
        currentRoundInBlock = 0
        currentDealer = 0
        currentCardsPerPlayer = 1
        
        calculateRoundsInBlock()
        
        phase = .bidding
        
        // Следующий игрок после дилера начинает ставки
        currentPlayer = (currentDealer + 1) % playerCount
    }
    
    /// Рассчитать количество раундов в текущем блоке
    private func calculateRoundsInBlock() {
        switch currentBlock {
        case .first, .third:
            // 36/N - 1 раздач
            totalRoundsInBlock = (36 / playerCount) - 1
        case .second, .fourth:
            // N раздач (по количеству игроков)
            totalRoundsInBlock = playerCount
        }
    }
    
    /// Начать новый раунд
    func startNewRound() {
        // Сброс данных игроков
        for player in players {
            player.resetForNewRound()
        }
        
        // Обновляем дилера (следующий по кругу)
        currentDealer = (currentDealer + 1) % playerCount
        
        // Следующий игрок после дилера начинает
        currentPlayer = (currentDealer + 1) % playerCount
        
        // Обновляем количество карт в зависимости от блока
        updateCardsPerPlayer()
        
        currentRoundInBlock += 1
        phase = .bidding
    }
    
    /// Обновить количество карт на игрока
    private func updateCardsPerPlayer() {
        switch currentBlock {
        case .first:
            // Возрастающее: 1, 2, 3, ...
            currentCardsPerPlayer = currentRoundInBlock + 1
        case .second:
            // Фиксированное: равно количеству игроков
            currentCardsPerPlayer = playerCount
        case .third:
            // Убывающее: начинаем с максимума
            let maxCards = (36 / playerCount) - 1
            currentCardsPerPlayer = maxCards - currentRoundInBlock + 1
        case .fourth:
            // Фиксированное: равно количеству игроков
            currentCardsPerPlayer = playerCount
        }
    }
    
    /// Сделать ставку
    func placeBid(_ bid: Int, forPlayer playerIndex: Int) -> Bool {
        guard phase == .bidding else { return false }
        guard playerIndex >= 0 && playerIndex < players.count else { return false }
        
        players[playerIndex].currentBid = bid
        
        // Переход к следующему игроку
        currentPlayer = (currentPlayer + 1) % playerCount
        
        // Проверяем, все ли сделали ставки
        if currentPlayer == (currentDealer + 1) % playerCount {
            // Все игроки сделали ставки
            phase = .playing
            currentPlayer = (currentDealer + 1) % playerCount
            return true
        }
        
        return false
    }
    
    /// Проверка валидности ставки для последнего игрока (дилера)
    func isValidBidForDealer(_ bid: Int) -> Bool {
        guard currentPlayer == currentDealer else { return true }
        
        // Считаем сумму всех ставок
        var totalBids = bid
        for i in 0..<playerCount {
            if i != currentDealer {
                totalBids += players[i].currentBid
            }
        }
        
        // Дилер не может называть ставку, при которой сумма равна количеству карт
        return totalBids != currentCardsPerPlayer
    }
    
    /// Разыграть карту
    func playCard(byPlayer playerIndex: Int) {
        guard phase == .playing else { return }
        
        // Переход к следующему игроку
        currentPlayer = (currentPlayer + 1) % playerCount
    }
    
    /// Завершить взятку
    func completeTrick(winner playerIndex: Int) {
        guard phase == .playing else { return }
        
        players[playerIndex].tricksTaken += 1
        
        // Победитель начинает следующую взятку
        currentPlayer = playerIndex
    }
    
    /// Завершить раунд
    func completeRound() {
        guard phase == .playing else { return }
        
        // Подсчитываем очки
        for player in players {
            player.addRoundScore(cardsInRound: currentCardsPerPlayer)
        }
        
        phase = .roundEnd
        
        // Проверяем, закончился ли блок
        if currentRoundInBlock >= totalRoundsInBlock {
            moveToNextBlock()
        }
    }
    
    /// Переход к следующему блоку
    private func moveToNextBlock() {
        switch currentBlock {
        case .first:
            currentBlock = .second
        case .second:
            currentBlock = .third
        case .third:
            currentBlock = .fourth
        case .fourth:
            phase = .gameEnd
            return
        }
        
        currentRoundInBlock = 0
        calculateRoundsInBlock()
    }
    
    /// Получить игрока с наибольшим счётом
    func getWinner() -> PlayerInfo? {
        return players.max(by: { $0.score < $1.score })
    }
    
    /// Получить таблицу очков
    func getScoreboard() -> [(player: PlayerInfo, rank: Int)] {
        let sorted = players.sorted(by: { $0.score > $1.score })
        return sorted.enumerated().map { (player: $1, rank: $0 + 1) }
    }
    
    // MARK: - Helper Methods
    
    /// Получить информацию об игроке
    func getPlayer(_ index: Int) -> PlayerInfo? {
        guard index >= 0 && index < players.count else { return nil }
        return players[index]
    }
    
    /// Текущий этап игры (описание)
    func getCurrentPhaseDescription() -> String {
        switch phase {
        case .notStarted:
            return "Игра не начата"
        case .bidding:
            return "Фаза ставок"
        case .playing:
            return "Идёт игра"
        case .roundEnd:
            return "Раунд завершён"
        case .gameEnd:
            return "Игра окончена"
        }
    }
    
    /// Описание текущего блока
    func getCurrentBlockDescription() -> String {
        switch currentBlock {
        case .first:
            return "Блок 1: возрастающее количество карт"
        case .second:
            return "Блок 2: \(playerCount) карт"
        case .third:
            return "Блок 3: убывающее количество карт"
        case .fourth:
            return "Блок 4: \(playerCount) карт"
        }
    }
}
