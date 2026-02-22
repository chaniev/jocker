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

    /// Текущее количество игроков (кэш)
    private var storedPlayerCount: Int

    /// Количество игроков
    var playerCount: Int {
        syncPlayerCountIfNeeded()
        return storedPlayerCount
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

    convenience init(playerCount: Int) {
        self.init(playerCountProvider: { playerCount })
    }

    /// Инициализация с динамическим источником количества игроков
    init(playerCountProvider: @escaping () -> Int) {
        self.playerCountProvider = playerCountProvider
        let initialCount = max(1, playerCountProvider())
        self.storedPlayerCount = initialCount
        self.currentBlockRoundResults = Array(repeating: [], count: initialCount)
        self.inProgressRoundResults = nil
        self.inProgressRoundBlockIndex = nil
        self.inProgressRoundIndex = nil
        self.completedBlocks = []
    }

    /// Инициализация из состояния игры (актуализирует число игроков при запуске)
    convenience init(gameState: GameState) {
        self.init(playerCountProvider: { gameState.playerCount })
    }

    // MARK: - Запись результатов раунда

    /// Записать результат раунда для одного игрока
    func recordRoundResult(playerIndex: Int, result: RoundResult) {
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        currentBlockRoundResults[playerIndex].append(result)
    }

    /// Записать результаты раунда для всех игроков
    ///
    /// - Parameter results: массив результатов, по одному для каждого игрока (в порядке индексов)
    func recordRoundResults(_ results: [RoundResult]) {
        guard results.count == playerCount else { return }
        for (index, result) in results.enumerated() {
            currentBlockRoundResults[index].append(result)
        }
    }

    /// Сохранить снимок текущего раунда (ещё не завершённого).
    func setInProgressRoundResults(_ results: [RoundResult], blockIndex: Int, roundIndex: Int) {
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
        let finalization = PremiumRules.finalizeBlockScores(
            blockRoundResults: currentBlockRoundResults,
            blockNumber: blockNumber,
            playerCount: playerCount
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

    // MARK: - Определение победителя

    /// Индекс игрока с наибольшим количеством очков
    func getWinnerIndex() -> Int? {
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

    // MARK: - Сброс

    /// Полный сброс менеджера для новой игры
    func reset() {
        currentBlockRoundResults = Array(repeating: [], count: playerCount)
        clearInProgressRoundResults()
        completedBlocks = []
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

    /// Обновить количество игроков, если источник изменился
    private func syncPlayerCountIfNeeded() {
        let updatedCount = playerCountProvider()
        guard updatedCount > 0, updatedCount != storedPlayerCount else { return }
        storedPlayerCount = updatedCount
        currentBlockRoundResults = Array(repeating: [], count: updatedCount)
        clearInProgressRoundResults()
        completedBlocks = []
    }
}
