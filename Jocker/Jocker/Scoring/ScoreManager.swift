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

    // MARK: - Завершение блока

    /// Завершить текущий блок: подсчитать премии и сохранить итоги
    ///
    /// - Parameter blockNumber: номер блока (1–4). Нулевая премия применяется в блоках 1 и 3.
    ///   Если не указан, нулевая премия не рассчитывается.
    /// - Returns: результат завершённого блока
    @discardableResult
    func finalizeBlock(blockNumber: Int = 0) -> BlockResult {
        // 1. Базовые очки за блок (сумма очков всех раундов)
        let baseBlockScores = calculateBaseBlockScores()

        // 2. Определяем всех игроков с премией (совпали все ставки в блоке)
        let allPremiumPlayerIndices = determinePremiumPlayers()

        // 3. Среди них определяем, кто получает нулевую премию (блоки 1/3, все ставки=0, все взятки=0)
        let zeroPremiumPlayerIndices = determineZeroPremiumPlayers(
            among: allPremiumPlayerIndices,
            blockNumber: blockNumber
        )
        let zeroPremiumSet = Set(zeroPremiumPlayerIndices)

        // 4. Остальные премиальные игроки получают обычную премию
        let regularPremiumPlayerIndices = allPremiumPlayerIndices
            .filter { !zeroPremiumSet.contains($0) }

        // 5. Рассчитываем бонусы и штрафы
        //    Все премиальные игроки (и обычные, и нулевые) участвуют в системе штрафов:
        //    — защищены от штрафов
        //    — штрафуют соседа справа
        let (premiumBonuses, zeroPremiumBonuses, premiumPenalties) = calculateAllPremiums(
            allPremiumPlayers: allPremiumPlayerIndices,
            regularPremiumPlayers: regularPremiumPlayerIndices,
            zeroPremiumPlayers: zeroPremiumPlayerIndices
        )

        // 6. Итоговые очки за блок
        var finalBlockScores = Array(repeating: 0, count: playerCount)
        for i in 0..<playerCount {
            finalBlockScores[i] = baseBlockScores[i]
                + premiumBonuses[i]
                + zeroPremiumBonuses[i]
                - premiumPenalties[i]
        }

        let blockResult = BlockResult(
            roundResults: currentBlockRoundResults,
            baseScores: baseBlockScores,
            premiumPlayerIndices: regularPremiumPlayerIndices,
            premiumBonuses: premiumBonuses,
            premiumPenalties: premiumPenalties,
            zeroPremiumPlayerIndices: zeroPremiumPlayerIndices,
            zeroPremiumBonuses: zeroPremiumBonuses,
            finalScores: finalBlockScores
        )

        // Сохраняем итоги и сбрасываем текущий блок
        completedBlocks.append(blockResult)
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
        completedBlocks = []
    }

    // MARK: - Private Methods

    /// Рассчитать базовые очки за текущий блок
    private func calculateBaseBlockScores() -> [Int] {
        return (0..<playerCount).map { playerIndex in
            currentBlockRoundResults[playerIndex].reduce(0) { $0 + $1.score }
        }
    }

    /// Определить игроков, получающих премию
    ///
    /// Игрок получает премию, если во всех раундах блока он взял
    /// ровно столько взяток, сколько объявил
    private func determinePremiumPlayers() -> [Int] {
        var premiumPlayers: [Int] = []
        for i in 0..<playerCount {
            let results = currentBlockRoundResults[i]
            guard !results.isEmpty else { continue }
            if results.allSatisfy({ $0.bidMatched }) {
                premiumPlayers.append(i)
            }
        }
        return premiumPlayers
    }

    /// Определить, кто из премиальных игроков получает нулевую премию
    ///
    /// Нулевая премия: в блоках 1 и 3 игрок заказывал 0 и брал 0 на каждой раздаче → 500 очков.
    /// Игрок может получить только одну из премий (нулевую ИЛИ обычную).
    ///
    /// - Parameters:
    ///   - premiumPlayers: все игроки с премией (все ставки совпали)
    ///   - blockNumber: номер блока (1–4)
    /// - Returns: индексы игроков с нулевой премией
    private func determineZeroPremiumPlayers(among premiumPlayers: [Int], blockNumber: Int) -> [Int] {
        guard blockNumber == 1 || blockNumber == 3 else { return [] }

        return premiumPlayers.filter { playerIndex in
            ScoreCalculator.isZeroPremiumEligible(roundResults: currentBlockRoundResults[playerIndex])
        }
    }

    /// Рассчитать бонусы и штрафы для всех премиальных игроков
    ///
    /// Все премиальные игроки (обычные и нулевые) одинаково:
    /// — защищены от штрафов за чужие премии
    /// — штрафуют соседа справа (максимальное положительное очко за раунд)
    ///
    /// Отличие: бонус обычной премии = max(очки раундов 1..N-1),
    ///          бонус нулевой премии = 500
    ///
    /// - Parameters:
    ///   - allPremiumPlayers: все игроки с премией
    ///   - regularPremiumPlayers: игроки с обычной премией
    ///   - zeroPremiumPlayers: игроки с нулевой премией
    /// - Returns: кортеж (обычные бонусы, нулевые бонусы, штрафы)
    private func calculateAllPremiums(
        allPremiumPlayers: [Int],
        regularPremiumPlayers: [Int],
        zeroPremiumPlayers: [Int]
    ) -> (premiumBonuses: [Int], zeroPremiumBonuses: [Int], penalties: [Int]) {
        var premiumBonuses = Array(repeating: 0, count: playerCount)
        var zeroPremiumBonuses = Array(repeating: 0, count: playerCount)
        var penalties = Array(repeating: 0, count: playerCount)

        let allPremiumSet = Set(allPremiumPlayers)

        // Бонусы обычной премии
        for playerIndex in regularPremiumPlayers {
            let roundScores = currentBlockRoundResults[playerIndex].map { $0.score }
            premiumBonuses[playerIndex] = ScoreCalculator.calculatePremiumBonus(roundScores: roundScores)
        }

        // Бонусы нулевой премии
        for playerIndex in zeroPremiumPlayers {
            zeroPremiumBonuses[playerIndex] = ScoreCalculator.zeroPremiumAmount
        }

        // Штрафы: все премиальные игроки (и обычные, и нулевые) штрафуют соседа справа
        // и все защищены от штрафов
        for playerIndex in allPremiumPlayers {
            if let penaltyTarget = findPenaltyTarget(
                for: playerIndex,
                premiumPlayers: allPremiumSet
            ) {
                let targetRoundScores = currentBlockRoundResults[penaltyTarget].map { $0.score }
                let penalty = ScoreCalculator.calculatePremiumPenalty(roundScores: targetRoundScores)
                // += потому что несколько премий могут штрафовать одного игрока
                penalties[penaltyTarget] += penalty
            }
        }

        return (premiumBonuses, zeroPremiumBonuses, penalties)
    }

    /// Найти игрока для штрафа за премию
    ///
    /// Ищет первого игрока справа, у которого нет премии.
    /// Если справа сидящий тоже получает премию — пропускаем его
    /// и ищем следующего справа.
    ///
    /// - Parameters:
    ///   - playerIndex: индекс игрока с премией
    ///   - premiumPlayers: множество индексов игроков с премией
    /// - Returns: индекс игрока для штрафа, или nil если все имеют премию
    private func findPenaltyTarget(for playerIndex: Int, premiumPlayers: Set<Int>) -> Int? {
        var candidate = rightNeighbor(of: playerIndex)
        var checked = 0

        while checked < playerCount - 1 {
            if !premiumPlayers.contains(candidate) {
                return candidate
            }
            candidate = rightNeighbor(of: candidate)
            checked += 1
        }

        // Все игроки получили премию — ошибка по правилам
        return nil
    }

    /// Получить индекс игрока справа (0-based)
    ///
    /// Для игрока 1 справа сидит игрок 4 (0-based: 0 → 3)
    /// Для игрока 2 справа сидит игрок 1 (0-based: 1 → 0)
    /// Для игрока 3 справа сидит игрок 2 (0-based: 2 → 1)
    /// Для игрока 4 справа сидит игрок 3 (0-based: 3 → 2)
    private func rightNeighbor(of playerIndex: Int) -> Int {
        return (playerIndex - 1 + playerCount) % playerCount
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
        completedBlocks = []
    }
}
