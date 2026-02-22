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
    func startGame(initialDealerIndex: Int = 0) {
        resetPlayersForNewGame()

        currentBlock = .first
        currentRoundInBlock = 0
        currentDealer = normalizedPlayerIndex(initialDealerIndex)
        currentCardsPerPlayer = GameConstants.cardsPerPlayer(
            for: currentBlock,
            roundIndex: currentRoundInBlock,
            playerCount: playerCount
        ) ?? 1
        
        calculateRoundsInBlock()
        
        phase = .bidding
        
        // Следующий игрок после дилера начинает ставки
        currentPlayer = normalizedPlayerIndex(currentDealer + 1)
    }

    private func resetPlayersForNewGame() {
        for index in players.indices {
            players[index].score = 0
            players[index].resetForNewRound()
        }
    }
    
    /// Установить имена игроков.
    ///
    /// Для пустых значений применяются стандартные имена вида "Игрок N".
    func setPlayerNames(_ names: [String]) {
        for index in players.indices {
            let fallbackName = "Игрок \(index + 1)"
            guard names.indices.contains(index) else {
                players[index].name = fallbackName
                continue
            }
            
            let trimmedName = names[index].trimmingCharacters(in: .whitespacesAndNewlines)
            players[index].name = trimmedName.isEmpty ? fallbackName : trimmedName
        }
    }
    
    /// Рассчитать количество раундов в текущем блоке
    private func calculateRoundsInBlock() {
        totalRoundsInBlock = GameConstants.deals(
            for: currentBlock,
            playerCount: playerCount
        ).count
    }
    
    /// Начать новый раунд
    func startNewRound() {
        guard phase != .gameEnd else { return }

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
            if phase == .gameEnd {
                return
            }
        }
        
        // Обновляем дилера (следующий по кругу)
        currentDealer = normalizedPlayerIndex(currentDealer + 1)
        
        // Следующий игрок после дилера начинает
        currentPlayer = normalizedPlayerIndex(currentDealer + 1)
        
        // Обновляем количество карт в зависимости от блока
        updateCardsPerPlayer()
        
        phase = .bidding
    }
    
    /// Обновить количество карт на игрока
    ///
    /// Данные берутся из `GameConstants.deals(for:playerCount:)`
    /// и совпадают с отображением таблицы очков.
    private func updateCardsPerPlayer() {
        currentCardsPerPlayer = GameConstants.cardsPerPlayer(
            for: currentBlock,
            roundIndex: currentRoundInBlock,
            playerCount: playerCount
        ) ?? currentCardsPerPlayer
    }
    
    /// Сделать ставку
    func placeBid(
        _ bid: Int,
        forPlayer playerIndex: Int,
        isBlind: Bool = false,
        lockBeforeDeal: Bool = false
    ) -> Bool {
        guard phase == .bidding else { return false }
        guard playerIndex >= 0 && playerIndex < players.count else { return false }
        
        players[playerIndex].currentBid = bid
        players[playerIndex].isBlindBid = isBlind
        players[playerIndex].isBidLockedBeforeDeal = lockBeforeDeal
        
        // Переход к следующему игроку
        currentPlayer = normalizedPlayerIndex(currentPlayer + 1)
        
        // Проверяем, все ли сделали ставки
        if currentPlayer == normalizedPlayerIndex(currentDealer + 1) {
            // Все игроки сделали ставки
            phase = .playing
            currentPlayer = normalizedPlayerIndex(currentDealer + 1)
            return true
        }
        
        return false
    }
    
    /// Проверка валидности ставки для последнего игрока (дилера)
    func isValidBidForDealer(_ bid: Int) -> Bool {
        guard currentPlayer == currentDealer else { return true }

        let currentBids = players.map { $0.currentBid }
        return allowedBids(forPlayer: currentDealer, bids: currentBids).contains(bid)
    }

    /// Доступна ли ставка «в тёмную» для игрока в текущем раунде.
    ///
    /// В 4-м блоке все игроки могут выбрать blind, кроме дилера:
    /// дилеру blind доступен только если все остальные игроки уже выбрали blind.
    func canChooseBlindBid(forPlayer playerIndex: Int, blindSelections: [Bool]) -> Bool {
        guard currentBlock == .fourth else { return false }
        return BiddingRules.canChooseBlindBid(
            forPlayer: playerIndex,
            dealer: currentDealer,
            blindSelections: blindSelections,
            playerCount: playerCount
        )
    }

    /// Допустимые ставки для игрока в текущем раунде.
    ///
    /// Для недилера возвращается полный диапазон `0...currentCardsPerPlayer`.
    /// Для дилера исключается единственная ставка, при которой суммарный заказ
    /// всех игроков будет равен количеству розданных карт.
    func allowedBids(forPlayer playerIndex: Int, bids: [Int]) -> [Int] {
        return BiddingRules.allowedBids(
            forPlayer: playerIndex,
            dealer: currentDealer,
            cardsInRound: currentCardsPerPlayer,
            bids: bids,
            playerCount: playerCount
        )
    }
    
    /// Разыграть карту
    func playCard(byPlayer playerIndex: Int) {
        guard phase == .playing else { return }
        
        // Переход к следующему игроку
        currentPlayer = normalizedPlayerIndex(currentPlayer + 1)
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
                isBlind: players[index].isBlindBid
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
    func setBid(
        _ bid: Int,
        forPlayerAt index: Int,
        isBlind: Bool = false,
        lockBeforeDeal: Bool = false
    ) {
        guard index >= 0, index < players.count else { return }
        players[index].currentBid = bid
        players[index].isBlindBid = isBlind
        players[index].isBidLockedBeforeDeal = lockBeforeDeal
    }
    
    /// Перейти в фазу розыгрыша после того, как ставки выставлены извне (UI).
    func beginPlayingAfterBids() {
        guard phase == .bidding else { return }
        phase = .playing
        currentPlayer = normalizedPlayerIndex(currentDealer + 1)
    }

    /// Явно завершить игру (используется сценой после финальной раздачи)
    func markGameEnded() {
        phase = .gameEnd
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
        return GameBlockFormatter.detailedDescription(
            for: currentBlock,
            playerCount: playerCount
        )
    }

    private func normalizedPlayerIndex(_ index: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((index % playerCount) + playerCount) % playerCount
    }
}
