//
//  GameState.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import Foundation

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
        case .first:
            // Блок 1: 8 раздач (1, 2, 3, 4, 5, 6, 7, 8 карт)
            totalRoundsInBlock = (GameConstants.deckSize / playerCount) - 1  // 8 для 4 игроков
        case .second:
            // Блок 2: 4 раздачи по 9 карт
            totalRoundsInBlock = playerCount  // 4 для 4 игроков
        case .third:
            // Блок 3: 8 раздач (8, 7, 6, 5, 4, 3, 2, 1 карта)
            totalRoundsInBlock = (GameConstants.deckSize / playerCount) - 1  // 8 для 4 игроков
        case .fourth:
            // Блок 4: 4 раздачи по 9 карт
            totalRoundsInBlock = playerCount  // 4 для 4 игроков
        }
    }
    
    /// Начать новый раунд
    func startNewRound() {
        // Сброс данных игроков
        for index in players.indices {
            players[index].resetForNewRound()
        }
        
        // Увеличиваем счетчик раундов
        currentRoundInBlock += 1
        
        // Проверяем, закончился ли текущий блок
        if currentRoundInBlock >= totalRoundsInBlock {
            // Переходим к следующему блоку
            moveToNextBlock()
        }
        
        // Обновляем дилера (следующий по кругу)
        currentDealer = (currentDealer + 1) % playerCount
        
        // Следующий игрок после дилера начинает
        currentPlayer = (currentDealer + 1) % playerCount
        
        // Обновляем количество карт в зависимости от блока
        updateCardsPerPlayer()
        
        phase = .bidding
    }
    
    /// Обновить количество карт на игрока
    ///
    /// Для 4 игроков последовательность раздач:
    /// Блок 1 (8 раздач): 1, 2, 3, 4, 5, 6, 7, 8 карт
    /// Блок 2 (4 раздачи): 9, 9, 9, 9 карт
    /// Блок 3 (8 раздач): 8, 7, 6, 5, 4, 3, 2, 1 карта
    /// Блок 4 (4 раздачи): 9, 9, 9, 9 карт
    private func updateCardsPerPlayer() {
        switch currentBlock {
        case .first:
            // Возрастающее: 1, 2, 3, ..., 8
            currentCardsPerPlayer = currentRoundInBlock + 1
        case .second:
            // Фиксированное: 9 карт для всех раздач
            currentCardsPerPlayer = 9
        case .third:
            // Убывающее: 8, 7, 6, 5, 4, 3, 2, 1
            let maxCards = (GameConstants.deckSize / playerCount) - 1  // 8 для 4 игроков
            currentCardsPerPlayer = maxCards - currentRoundInBlock
        case .fourth:
            // Фиксированное: 9 карт для всех раздач
            currentCardsPerPlayer = 9
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
        
        // Подсчитываем очки через единый ScoreCalculator
        for index in players.indices {
            let roundScore = ScoreCalculator.calculateRoundScore(
                cardsInRound: currentCardsPerPlayer,
                bid: players[index].currentBid,
                tricksTaken: players[index].tricksTaken,
                isBlind: false
            )
            players[index].score += roundScore
        }
        
        phase = .roundEnd
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
    
    // MARK: - Мутация игроков (для внешних вызовов)
    
    /// Установить ставку игрока (из UI)
    func setBid(_ bid: Int, forPlayerAt index: Int) {
        guard index >= 0, index < players.count else { return }
        players[index].currentBid = bid
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

