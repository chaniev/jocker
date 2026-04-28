//
//  ScoreManager.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import Foundation

/// Менеджер подсчёта и хранения очков за всю игру
///
/// Отвечает за:
/// - Хранение результатов каждого раунда внутри блока
/// - Подсчёт базовых очков за блок
/// - Определение премий и их применение
/// - Хранение итогов по блокам и общего счёта
class ScoreManager {

    // MARK: - Properties

    /// Провайдер количества игроков (например, из GameState или другого источника)
    private let playerCountProvider: () -> Int
    private let gameModeProvider: () -> GameMode

    /// Текущее количество игроков (кэш)
    private var storedPlayerCount: Int
    private var storedGameMode: GameMode

    /// Количество игроков
    var playerCount: Int {
        return storedPlayerCount
    }

    var gameMode: GameMode {
        return storedGameMode
    }

    var partnerships: GamePartnerships {
        return GamePartnerships(playerCount: playerCount, gameMode: gameMode)
    }

    /// Результаты раундов в текущем блоке: [playerIndex][roundIndex]
    private(set) var currentBlockRoundResults: [[RoundResult]]

    /// Снимок текущего (незавершённого) раунда для отображения в таблице
    private(set) var inProgressRoundResults: [RoundResult]?
    private(set) var inProgressRoundBlockIndex: Int?
    private(set) var inProgressRoundIndex: Int?

    /// Завершённые блоки с итогами
    private(set) var completedBlocks: [BlockResult]

    // MARK: - Initialization

    convenience init(
        playerCount: Int,
        gameMode: GameMode = .freeForAll
    ) {
        self.init(
            playerCountProvider: { playerCount },
            gameModeProvider: { gameMode }
        )
    }

    /// Инициализация с динамическим источником количества игроков
    init(
        playerCountProvider: @escaping () -> Int,
        gameModeProvider: @escaping () -> GameMode = { .freeForAll }
    ) {
        self.playerCountProvider = playerCountProvider
        self.gameModeProvider = gameModeProvider
        let initialCount = max(1, playerCountProvider())
        let initialMode = gameModeProvider().normalized(for: initialCount)
        self.storedPlayerCount = initialCount
        self.storedGameMode = initialMode
        self.currentBlockRoundResults = Array(repeating: [], count: initialCount)
        self.inProgressRoundResults = nil
        self.inProgressRoundBlockIndex = nil
        self.inProgressRoundIndex = nil
        self.completedBlocks = []
    }

    /// Инициализация из состояния игры (актуализирует число игроков при запуске)
    convenience init(gameState: GameState) {
        self.init(
            playerCountProvider: { gameState.playerCount },
            gameModeProvider: { gameState.gameMode }
        )
    }

    // MARK: - Запись результатов раунда

    /// Записать результат раунда для одного игрока
    func recordRoundResult(playerIndex: Int, result: RoundResult) {
        synchronizePlayerCountIfNeeded()
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        currentBlockRoundResults[playerIndex].append(result)
    }

    /// Записать результаты раунда для всех игроков
    ///
    /// - Parameter results: массив результатов, по одному для каждого игрока (в порядке индексов)
    func recordRoundResults(_ results: [RoundResult]) {
        synchronizePlayerCountIfNeeded()
        guard results.count == playerCount else { return }
        for (index, result) in results.enumerated() {
            currentBlockRoundResults[index].append(result)
        }
    }

    /// Сохранить снимок текущего раунда (ещё не завершённого).
    func setInProgressRoundResults(_ results: [RoundResult], blockIndex: Int, roundIndex: Int) {
        synchronizePlayerCountIfNeeded()
        guard results.count == playerCount else { return }
        guard blockIndex >= 0, roundIndex >= 0 else { return }

        inProgressRoundResults = results
        inProgressRoundBlockIndex = blockIndex
        inProgressRoundIndex = roundIndex
    }

    /// Очистить снимок текущего раунда.
    func clearInProgressRoundResults() {
        inProgressRoundResults = nil
        inProgressRoundBlockIndex = nil
        inProgressRoundIndex = nil
    }

    /// Получить снимок результата игрока для текущего незавершённого раунда.
    func inProgressRoundResult(
        forBlockIndex blockIndex: Int,
        roundIndex: Int,
        playerIndex: Int
    ) -> RoundResult? {
        synchronizePlayerCountIfNeeded()
        guard inProgressRoundBlockIndex == blockIndex else { return nil }
        guard inProgressRoundIndex == roundIndex else { return nil }
        guard let inProgressRoundResults else { return nil }
        guard inProgressRoundResults.indices.contains(playerIndex) else { return nil }
        return inProgressRoundResults[playerIndex]
    }

    // MARK: - Завершение блока

    /// Завершить текущий блок: подсчитать премии и сохранить итоги
    ///
    /// - Parameter blockNumber: номер блока (1–4). Нулевая премия применяется в блоках 1 и 3.
    ///   Если не указан, нулевая премия не рассчитывается.
    /// - Returns: результат завершённого блока
    @discardableResult
    func finalizeBlock(blockNumber: Int = 0) -> BlockResult {
        synchronizePlayerCountIfNeeded()
        let finalization = PremiumRules.finalizeBlockScores(
            blockRoundResults: currentBlockRoundResults,
            blockNumber: blockNumber,
            playerCount: playerCount,
            gameMode: gameMode
        )

        let blockResult = BlockResult(
            roundResults: finalization.roundsWithPremiums,
            baseScores: finalization.baseBlockScores,
            premiumPlayerIndices: finalization.regularPremiumPlayers,
            premiumBonuses: finalization.premiumBonuses,
            premiumPenalties: finalization.premiumPenalties,
            premiumPenaltyRoundIndices: finalization.premiumPenaltyRoundIndices,
            premiumPenaltyRoundScores: finalization.premiumPenaltyRoundScores,
            zeroPremiumPlayerIndices: finalization.zeroPremiumPlayers,
            zeroPremiumBonuses: finalization.zeroPremiumBonuses,
            finalScores: finalization.finalScores
        )

        // Сохраняем итоги и сбрасываем текущий блок
        completedBlocks.append(blockResult)
        clearInProgressRoundResults()
        resetCurrentBlock()

        return blockResult
    }

    // MARK: - Текущие очки

    /// Базовые очки текущего (незавершённого) блока для каждого игрока
    var currentBlockBaseScores: [Int] {
        return calculateBaseBlockScores()
    }

    /// Очки за раунд для каждого игрока в текущем блоке: [playerIndex][roundIndex]
    var currentBlockRoundScores: [[Int]] {
        return currentBlockRoundResults.map { rounds in
            rounds.map { $0.score }
        }
    }

    /// Общие очки за всю игру (сумма итогов завершённых блоков)
    var totalScores: [Int] {
        var scores = Array(repeating: 0, count: playerCount)
        for block in completedBlocks {
            for i in 0..<playerCount {
                scores[i] += block.finalScores[i]
            }
        }
        return scores
    }

    /// Общие очки с учётом текущего незавершённого блока
    var totalScoresIncludingCurrentBlock: [Int] {
        let completed = totalScores
        let current = currentBlockBaseScores
        return (0..<playerCount).map { completed[$0] + current[$0] }
    }

    var currentBlockTeamScores: [Int] {
        return partnerships.teamTotals(from: currentBlockBaseScores)
    }

    var totalTeamScores: [Int] {
        return partnerships.teamTotals(from: totalScores)
    }

    var totalTeamScoresIncludingCurrentBlock: [Int] {
        return partnerships.teamTotals(from: totalScoresIncludingCurrentBlock)
    }

    func teamScores(for blockResult: BlockResult) -> [Int] {
        return partnerships.teamTotals(from: blockResult.finalScores)
    }

    // MARK: - Определение победителя

    /// Индекс игрока с наибольшим количеством очков
    func getWinnerIndex() -> Int? {
        if gameMode == .pairs {
            guard let winningTeamIndex = getWinningTeamIndex() else { return nil }
            let winningMembers = partnerships.teamMembers(for: winningTeamIndex)
            return winningMembers.max { lhs, rhs in
                let lhsScore = totalScores.indices.contains(lhs) ? totalScores[lhs] : Int.min
                let rhsScore = totalScores.indices.contains(rhs) ? totalScores[rhs] : Int.min
                if lhsScore == rhsScore {
                    return lhs > rhs
                }
                return lhsScore < rhsScore
            }
        }

        let scores = totalScores
        guard !scores.isEmpty else { return nil }
        return scores.enumerated().max(by: { $0.element < $1.element })?.offset
    }

    /// Таблица очков: массив (playerIndex, totalScore) отсортированный по убыванию
    func getScoreboard() -> [(playerIndex: Int, score: Int)] {
        let scores = totalScores
        return scores.enumerated()
            .map { (playerIndex: $0.offset, score: $0.element) }
            .sorted { $0.score > $1.score }
    }

    func getWinningTeamIndex() -> Int? {
        return partnerships.leadingTeamIndex(from: totalScores)
    }

    func getTeamScoreboard() -> [(teamIndex: Int, score: Int)] {
        let scores = totalTeamScores
        return scores.enumerated()
            .map { (teamIndex: $0.offset, score: $0.element) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.teamIndex < rhs.teamIndex
                }
                return lhs.score > rhs.score
            }
    }

    // MARK: - Сброс

    /// Полный сброс менеджера для новой игры
    func reset() {
        synchronizePlayerCountIfNeeded()
        currentBlockRoundResults = Array(repeating: [], count: playerCount)
        clearInProgressRoundResults()
        completedBlocks = []
    }

    /// Явно синхронизировать кэшированное количество игроков с `playerCountProvider`.
    ///
    /// Важно: может очистить текущее состояние (текущий блок, in-progress round, завершённые блоки),
    /// если провайдер вернул другое положительное количество игроков.
    @discardableResult
    func synchronizePlayerCountIfNeeded() -> Bool {
        return applyConfigurationProviderUpdatesIfNeeded()
    }

    // MARK: - Private Methods

    /// Рассчитать базовые очки за текущий блок
    private func calculateBaseBlockScores() -> [Int] {
        return calculateBlockScores(currentBlockRoundResults)
    }

    /// Рассчитать сумму очков по каждому игроку на основе переданных раздач блока.
    private func calculateBlockScores(_ roundResults: [[RoundResult]]) -> [Int] {
        return (0..<playerCount).map { playerIndex in
            guard roundResults.indices.contains(playerIndex) else { return 0 }
            return roundResults[playerIndex].reduce(0) { $0 + $1.score }
        }
    }

    /// Сбросить данные текущего блока
    private func resetCurrentBlock() {
        currentBlockRoundResults = Array(repeating: [], count: playerCount)
    }

    /// Обновить количество игроков, если источник изменился.
    /// - Returns: `true`, если количество игроков изменилось и состояние было сброшено.
    @discardableResult
    private func applyConfigurationProviderUpdatesIfNeeded() -> Bool {
        let updatedCount = playerCountProvider()
        guard updatedCount > 0 else { return false }
        let updatedMode = gameModeProvider().normalized(for: updatedCount)
        guard updatedCount != storedPlayerCount || updatedMode != storedGameMode else { return false }
        storedPlayerCount = updatedCount
        storedGameMode = updatedMode
        currentBlockRoundResults = Array(repeating: [], count: updatedCount)
        clearInProgressRoundResults()
        completedBlocks = []
        return true
    }
}
