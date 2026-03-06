# Предложения по улучшению игры ботов через обучение

**Дата:** 6 марта 2026 г.  
**Автор:** AI Code Analysis  

---

## Содержание

1. [Анализ текущей реализации](#анализ-текущей-реализации)
2. [Предложения по улучшению](#предложения-по-улучшению)
3. [Сводная таблица приоритетов](#сводная-таблица-приоритетов)
4. [План внедрения](#план-внедрения)

---

## Анализ текущей реализации

### Архитектура

**Основные компоненты:**

| Компонент | Файл | Назначение |
|-----------|------|------------|
| `BotTuning` | `Models/Bot/BotTuning.swift` | 150+ коэффициентов для всех аспектов игры |
| `BotTurnStrategyService` | `Services/AI/BotTurnStrategyService.swift` | Принятие решений в фазе розыгрыша |
| `BotTurnCandidateEvaluatorService` | `Services/AI/BotTurnCandidateEvaluatorService.swift` | Оценка кандидатов хода через utility-функцию |
| `BotSelfPlayEvolutionEngine` | `Services/AI/BotSelfPlayEvolutionEngine+.swift` | Эволюционный поиск параметров через self-play |
| `BotTurnRolloutService` | `Services/AI/BotTurnRolloutService.swift` | Monte Carlo rollout для критических ситуаций |
| `BotTurnEndgameSolver` | `Services/AI/BotTurnEndgameSolver.swift` | Полный перебор до конца раздачи в эндшпиле |
| `BotBlindBidMonteCarloEstimator` | `Services/AI/BotBlindBidMonteCarloEstimator.swift` | Оценка тёмных ставок через сэмплирование |

### Текущий подход к обучению

```
Генетический алгоритм:
├── Популяция: 20 геномов (мутации ~150 параметров BotTuning)
├── Фитнес-функция: winRate×0.6 + scoreDiff×0.25 - underbidLoss×0.15
├── Селекция: турнирная из top-40%
├── Кроссовер + мутация
└── Early stopping при отсутствии улучшений
```

### Структура фитнес-функции (текущая)

```swift
struct FitnessScoringConfig {
    let winRateWeight: Double              // Вес доли побед
    let scoreDiffWeight: Double            // Вес средней разницы очков
    let underbidLossWeight: Double         // Штраф за недобор взяток
    let trumpDensityUnderbidWeight: Double // Штраф за недобор с козырем
    let noTrumpControlUnderbidWeight: Double
    let premiumAssistWeight: Double        // Штраф за помощь премии соперника
    let premiumPenaltyTargetWeight: Double // Штраф за попадание под премию
    
    // Нормализации для масштабирования
    let scoreDiffNormalization: Double
    let underbidLossNormalization: Double
    // ...
}
```

---

## Предложения по улучшению

### 1. Расширение фитнес-функции

**Приоритет:** 🔴 **Высокий**  
**Сложность:** Низкая  
**Ожидаемый эффект:** +15-20% win rate

#### Проблема

Текущая фитнес-функция (`FitnessScoringConfig`) не учитывает критически важные аспекты:

- ❌ Эффективность игры с джокерами (`jokerWishWinRate`, `earlyJokerSpendRate` есть в метриках, но **не в фитнес**)
- ❌ Точность выбора козыря
- ❌ Анти-премиум стратегию (блоки 1 и 3)
- ❌ Точность тёмных ставок

#### Решение

```swift
// Файл: BotSelfPlayEvolutionEngine+Fitness.swift

struct FitnessScoringConfig {
    // === СУЩЕСТВУЮЩИЕ ВЕСА ===
    let winRateWeight: Double
    let scoreDiffWeight: Double
    let underbidLossWeight: Double
    let trumpDensityUnderbidWeight: Double
    let noTrumpControlUnderbidWeight: Double
    let premiumAssistWeight: Double
    let premiumPenaltyTargetWeight: Double
    
    // === НОВЫЕ ВЕСА (ДОБАВИТЬ) ===
    
    /// Вес эффективности розыгрыша джокеров
    /// Высокий вес заставляет бота бережнее расходовать джокеров
    let jokerEfficiencyWeight: Double
    
    /// Штраф за ранний расход джокера (до критической фазы)
    /// Помогает избежать преждевременной траты сильного ресурса
    let earlyJokerSpendPenaltyWeight: Double
    
    /// Вес точности выбора козыря
    /// Оценивает % выигранных взяток в масти выбранного козыря
    let trumpSelectionAccuracyWeight: Double
    
    /// Вес успешного избегания премии слева (анти-премиум)
    /// Критично для блоков 1 и 3
    let antiPremiumSuccessWeight: Double
    
    /// Вес точности тёмной ставки
    /// Штрафует отклонение от оптимальной blind-ставки
    let blindBidAccuracyWeight: Double
    
    /// Вес эффективности rollout-решений
    /// Оценивает корректность выбора момента для rollout
    let rolloutDecisionAccuracyWeight: Double
    
    // === НОРМАЛИЗАЦИИ (ДОБАВИТЬ) ===
    
    let jokerEfficiencyNormalization: Double
    let earlyJokerSpendNormalization: Double
    let trumpSelectionNormalization: Double
    let antiPremiumNormalization: Double
    let blindBidAccuracyNormalization: Double
    
    // === МЕТОД РАСЧЁТА ФИТНЕСА (ОБНОВИТЬ) ===
    
    func fitness(
        winRate: Double,
        averageScoreDiff: Double,
        averageUnderbidLoss: Double,
        averageTrumpDensityUnderbidLoss: Double,
        averageNoTrumpControlUnderbidLoss: Double,
        averagePremiumAssistLoss: Double,
        averagePremiumPenaltyTargetLoss: Double,
        // Новые параметры:
        jokerEfficiency: Double,
        earlyJokerSpendRate: Double,
        trumpSelectionAccuracy: Double,
        antiPremiumSuccessRate: Double,
        blindBidAccuracy: Double
    ) -> Double {
        return winRate * winRateWeight +
            (averageScoreDiff / scoreDiffNormalization) * scoreDiffWeight +
            -(averageUnderbidLoss / underbidLossNormalization) * underbidLossWeight +
            -(averageTrumpDensityUnderbidLoss / trumpDensityUnderbidNormalization) * trumpDensityUnderbidWeight +
            -(averageNoTrumpControlUnderbidLoss / noTrumpControlUnderbidNormalization) * noTrumpControlUnderbidWeight +
            -(averagePremiumAssistLoss / premiumAssistNormalization) * premiumAssistWeight +
            -(averagePremiumPenaltyTargetLoss / premiumPenaltyTargetNormalization) * premiumPenaltyTargetWeight +
            // Новые компоненты:
            (jokerEfficiency / jokerEfficiencyNormalization) * jokerEfficiencyWeight +
            -(earlyJokerSpendRate / earlyJokerSpendNormalization) * earlyJokerSpendPenaltyWeight +
            (trumpSelectionAccuracy / trumpSelectionNormalization) * trumpSelectionAccuracyWeight +
            (antiPremiumSuccessRate / antiPremiumNormalization) * antiPremiumSuccessWeight +
            (blindBidAccuracy / blindBidAccuracyNormalization) * blindBidAccuracyWeight
    }
}
```

#### Рекомендуемые значения весов

```swift
// Для начала эволюции (требуют тонкой настройки):
jokerEfficiencyWeight: 0.15
earlyJokerSpendPenaltyWeight: 0.10
trumpSelectionAccuracyWeight: 0.08
antiPremiumSuccessWeight: 0.12
blindBidAccuracyWeight: 0.07

// Суммарный вес должен оставаться сбалансированным:
// winRateWeight: 0.50 (снизить с 0.60)
// scoreDiffWeight: 0.20 (снизить с 0.25)
```

#### Изменения в `FitnessBreakdown`

```swift
struct FitnessBreakdown {
    // Существующие поля...
    let fitness: Double
    let winRate: Double
    // ...
    
    // ДОБАВИТЬ новые метрики:
    let jokerEfficiency: Double           // % успешных розыгрышей джокеров
    let trumpSelectionAccuracy: Double    // % взяток с правильным козырем
    let antiPremiumSuccessRate: Double    // % успешного избегания премии
    let blindBidAccuracy: Double          // Среднее отклонение от оптимальной ставки
}
```

---

### 2. Динамическая настройка параметров по фазам блока

**Приоритет:** 🔴 **Высокий**  
**Сложность:** Средняя  
**Ожидаемый эффект:** +10-15% точность добора взяток

#### Проблема

`BotTuning` использует **статические коэффициенты** для всех 8 раздач блока, хотя стратегия должна меняться динамически:

| Фаза | Раздачи | Стратегия |
|------|---------|-----------|
| **Ранняя** | 1-3 | Разведка, сохранение контроля, минимизация рисков |
| **Средняя** | 4-6 | Максимизация очков, активный добор |
| **Поздняя** | 7-8 | Точный добор/сброс, учёт премии |

#### Решение

```swift
// Файл: Models/Bot/BotTuning.swift

extension BotTuning {
    /// Модификаторы поведения по фазам блока
    struct PhaseModifiers {
        // === АГРЕССИВНОСТЬ ПО ФАЗАМ ===
        
        /// Множитель агрессивности в ранней фазе (раздачи 1-3)
        /// < 1.0 = консервативно, > 1.0 = агрессивно
        let earlyBlockAggression: Double
        
        /// Множитель агрессивности в средней фазе (раздачи 4-6)
        let midBlockAggression: Double
        
        /// Множитель агрессивности в поздней фазе (раздачи 7-8)
        /// > 1.0 = агрессивно для добора заказа
        let lateBlockAggression: Double
        
        // === ДЖОКЕР-ПОЛИТИКА ПО ФАЗАМ ===
        
        /// Минимальный номер раздачи для расхода джокера лицом вверх
        /// Высокое значение = бережём джокера до поздней фазы
        let earlyJokerSpendThreshold: Int
        
        /// Максимальный номер раздачи для "безопасного" расхода джокера
        let safeJokerSpendMaxRound: Int
        
        // === АНТИ-ПРЕМИУМ ОСВЕДОМЛЁННОСТЬ ===
        
        /// С какой раздачи включать анти-премиум стратегию
        /// 5 = начинать с 5-й раздачи блока
        let antiPremiumAwarenessStartRound: Int
        
        /// Вес избегания премии слева в поздней фазе
        let lateBlockAntiPremiumWeight: Double
        
        // === ФАЗОВЫЕ ГАТЕЫ ===
        
        /// Порог количества карт для включения endgame solver в ранней фазе
        let earlyPhaseEndgameThreshold: Int
        
        /// Порог для rollout в поздней фазе
        let latePhaseRolloutThreshold: Int
    }
    
    /// Получить модификаторы для текущей раздачи
    func phaseModifier(for roundIndex: Int, totalRounds: Int) -> PhaseModifier {
        let phase = phaseFor(roundIndex: roundIndex, totalRounds: totalRounds)
        return PhaseModifier(
            aggression: aggressionFor(phase: phase),
            jokerSpendAllowed: jokerSpendAllowedFor(phase: phase, roundIndex: roundIndex),
            antiPremiumWeight: antiPremiumWeightFor(phase: phase, roundIndex: roundIndex)
        )
    }
    
    enum BlockPhase {
        case early    // раздачи 1-3
        case mid      // раздачи 4-6
        case late     // раздачи 7-8
    }
    
    struct PhaseModifier {
        let aggression: Double
        let jokerSpendAllowed: Bool
        let antiPremiumWeight: Double
    }
}
```

#### Применение в `BotTurnStrategyService`

```swift
// Файл: Services/AI/BotTurnStrategyService.swift

extension BotTurnStrategyService {
    func makeTurnDecision(context: BotTurnDecisionContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard let resolvedContext = resolveDecisionContext(context) else { return nil }
        
        // === НОВОЕ: Получить фазовый модификатор ===
        let roundIndex = context.matchContext?.blockProgress.currentRoundIndex ?? 0
        let totalRounds = context.matchContext?.blockProgress.totalRounds ?? 8
        let phaseModifier = tuning.phaseModifier(for: roundIndex, totalRounds: totalRounds)
        
        // Применить модификатор агрессивности к utility
        let adjustedTuning = tuning.withAggressionMultiplier(phaseModifier.aggression)
        
        // Применить ограничение на расход джокера
        if !phaseModifier.jokerSpendAllowed {
            // Блокировать расход джокера лицом вверх в ранней фазе
        }
        
        // ... остальная логика с adjustedTuning
    }
}
```

#### Рекомендуемые значения по умолчанию

```swift
PhaseModifiers(
    earlyBlockAggression: 0.75,    // Консервативно в начале
    midBlockAggression: 1.0,       // Нормально в середине
    lateBlockAggression: 1.25,     // Агрессивно в конце
    
    earlyJokerSpendThreshold: 4,   // Не тратить джокера до 4-й раздачи
    safeJokerSpendMaxRound: 6,     // После 6-й — только в критической ситуации
    
    antiPremiumAwarenessStartRound: 5,  // С 5-й раздачи думать о премии
    lateBlockAntiPremiumWeight: 1.5,    // Усилить анти-премиум в конце
    
    earlyPhaseEndgameThreshold: 2,      // В ранней фазе endgame только при ≤2 картах
    latePhaseRolloutThreshold: 4        // В поздней фазе rollout при ≤4 картах
)
```

---

### 3. Улучшение эволюционного алгоритма

**Приоритет:** 🔴 **Высокий**  
**Сложность:** Средняя  
**Ожидаемый эффект:** +20% скорость сходимости, избегание локальных оптимумов

#### Проблема

Текущий GA (`BotSelfPlayEvolutionEngine+Evolution.swift`) имеет ограничения:

- ❌ Простая Gaussian-мутация без адаптации
- ❌ Нет **speciation** — популяция вырождается к одному типу
- ❌ Фиксированное число поколений
- ❌ Нет защиты молодых перспективных видов
- ❌ Отсутствует **novelty search** для исследования пространства

#### Решение 3.1: Speciation (разделение на виды)

```swift
// Файл: BotSelfPlayEvolutionEngine+Evolution.swift

extension BotSelfPlayEvolutionEngine {
    struct SelfPlayEvolutionConfig {
        // === СУЩЕСТВУЮЩИЕ ПАРАМЕТРЫ ===
        let populationSize: Int
        let eliteCount: Int
        let generations: Int
        // ...
        
        // === НОВОЕ: SPECIATION ===
        
        /// Порог генетической дистанции для разделения на виды
        /// Геномы с расстоянием > threshold относятся к разным видам
        let speciationThreshold: Double
        
        /// Минимальный размер вида для защиты от вымирания
        /// Виды размером < minSpeciesSize получают защиту на несколько поколений
        let minSpeciesSize: Int
        
        /// Поколений защиты для молодых видов
        /// Позволяет новым видам развиться до конкуренции
        let speciesProtectionGenerations: Int
        
        /// Вес фитнеса внутри вида при селекции
        /// > 0 = отбор относительно вида, а не абсолютный
        let speciesRelativeFitnessWeight: Double
        
        /// Минимальное количество видов для поддержания разнообразия
        let targetSpeciesCount: Int
        
        /// Штраф за перенаселённость вида
        /// Предотвращает доминирование одного вида
        let speciesCompetitionPenalty: Double
    }
    
    /// Вычислить генетическую дистанцию между двумя геномами
    static func geneticDistance(_ genome1: EvolutionGenome, _ genome2: EvolutionGenome) -> Double {
        // Евклидово расстояние между векторами параметров
        let differences = zip(genome1.parameterVector, genome2.parameterVector)
            .map { abs($0 - $1) }
        return sqrt(differences.reduce(0, +))
    }
    
    /// Разделить популяцию на виды
    static func speciate(population: [EvolutionGenome], config: SelfPlayEvolutionConfig) -> [Species] {
        var species: [Species] = []
        
        for genome in population {
            var assigned = false
            
            // Попытаться назначить к существующему виду
            for speciesIndex in species.indices {
                let representative = species[speciesIndex].representative
                let distance = geneticDistance(genome, representative)
                
                if distance < config.speciationThreshold {
                    species[speciesIndex].members.append(genome)
                    assigned = true
                    break
                }
            }
            
            // Создать новый вид
            if !assigned {
                species.append(Species(representative: genome, members: [genome]))
            }
        }
        
        return species
    }
    
    struct Species {
        let representative: EvolutionGenome
        var members: [EvolutionGenome]
        let creationGeneration: Int
        var adjustedFitnesses: [Double] = []
        
        var averageFitness: Double {
            guard !adjustedFitnesses.isEmpty else { return 0.0 }
            return adjustedFitnesses.reduce(0, +) / Double(adjustedFitnesses.count)
        }
    }
}
```

#### Решение 3.2: Novelty Search

```swift
extension BotSelfPlayEvolutionEngine {
    struct SelfPlayEvolutionConfig {
        // === НОВОЕ: NOVELTY SEARCH ===
        
        /// Вес новизны в итоговом фитнесе
        /// 0.0 = только производительность, 1.0 = только новизна
        let noveltySearchWeight: Double
        
        /// Количество ближайших соседей для оценки новизны
        let noveltyKNeighbors: Int
        
        /// Размер архива новизны (максимум хранящихся геномов)
        let noveltyArchiveSize: Int
        
        /// Порог добавления в архив новизны
        /// Геномы с новизной > threshold добавляются в архив
        let noveltyArchiveThreshold: Double
        
        /// Частота обновления архива (каждые N поколений)
        let noveltyArchiveUpdateFrequency: Int
    }
    
    /// Вычислить оценку новизны генома
    static func noveltyScore(
        genome: EvolutionGenome,
        archive: [EvolutionGenome],
        currentPopulation: [EvolutionGenome],
        k: Int
    ) -> Double {
        // Найти k ближайших соседей в архиве + популяции
        let allGenomes = archive + currentPopulation
        let distances = allGenomes.map { geneticDistance(genome, $0) }
        let sortedDistances = distances.sorted()
        let kNearest = Array(sortedDistances.prefix(min(k, sortedDistances.count)))
        
        // Новизна = среднее расстояние до k ближайших соседей
        guard !kNearest.isEmpty else { return 0.0 }
        return kNearest.reduce(0, +) / Double(kNearest.count)
    }
    
    /// Комбинированный фитнес с учётом новизны
    static func combinedFitness(
        rawFitness: Double,
        noveltyScore: Double,
        maxFitness: Double,
        maxNovelty: Double,
        noveltyWeight: Double
    ) -> Double {
        // Нормализовать fitness и novelty к [0, 1]
        let normalizedFitness = rawFitness / max(maxFitness, 1e-10)
        let normalizedNovelty = noveltyScore / max(maxNovelty, 1e-10)
        
        // Комбинировать с весом новизны
        return normalizedFitness * (1.0 - noveltyWeight) + normalizedNovelty * noveltyWeight
    }
}
```

#### Решение 3.3: Адаптивная мутация

```swift
extension BotSelfPlayEvolutionEngine {
    struct SelfPlayEvolutionConfig {
        // === НОВОЕ: АДАПТИВНАЯ МУТАЦИЯ ===
        
        /// Включить адаптивную скорость мутации
        let adaptiveMutationRate: Bool
        
        /// Минимальная скорость мутации
        let minMutationChance: Double
        
        /// Максимальная скорость мутации
        let maxMutationChance: Double
        
        /// Порог разнообразия популяции для увеличения мутации
        /// Если разнообразие < threshold, увеличить мутацию
        let diversityThreshold: Double
        
        /// Множитель увеличения мутации при низком разнообразии
        let lowDiversityMutationMultiplier: Double
    }
    
    /// Вычислить разнообразие популяции
    static func populationDiversity(population: [EvolutionGenome]) -> Double {
        guard population.count > 1 else { return 0.0 }
        
        var totalDistance = 0.0
        var comparisons = 0
        
        for i in 0..<population.count {
            for j in (i+1)..<population.count {
                totalDistance += geneticDistance(population[i], population[j])
                comparisons += 1
            }
        }
        
        return comparisons > 0 ? totalDistance / Double(comparisons) : 0.0
    }
    
    /// Адаптировать скорость мутации по разнообразию
    static func adaptMutationRate(
        baseChance: Double,
        populationDiversity: Double,
        config: SelfPlayEvolutionConfig
    ) -> Double {
        guard config.adaptiveMutationRate else { return baseChance }
        
        if populationDiversity < config.diversityThreshold {
            // Низкое разнообразие → увеличить мутацию
            return min(config.maxMutationChance, baseChance * config.lowDiversityMutationMultiplier)
        } else {
            // Высокое разнообразие → уменьшить мутацию
            return max(config.minMutationChance, baseChance * 0.8)
        }
    }
}
```

---

### 4. Параллелизация обучения

**Приоритет:** 🔴 **Высокий**  
**Сложность:** Средняя  
**Ожидаемый эффект:** 4-8× ускорение обучения

#### Проблема

Обучение требует огромных вычислений:
```
20 геномов × 100 игр × 8 раздач = 16,000 симуляций на поколение
```

При 1 секунде на симуляцию = 4.5 часов на поколение.

#### Решение 4.1: Параллелизация по геномам

```swift
// Файл: BotSelfPlayEvolutionEngine+Evolution.swift

extension BotSelfPlayEvolutionEngine {
    static func evolveViaSelfPlay(
        baseTuning: BotTuning,
        config: SelfPlayEvolutionConfig = SelfPlayEvolutionConfig(),
        seed: UInt64 = 0x5EED,
        progress: ((SelfPlayEvolutionProgress) -> Void)? = nil
    ) -> SelfPlayEvolutionResult {
        // ... инициализация ...
        
        for generation in 0..<config.generations {
            // === ПАРАЛЛЕЛЬНАЯ ОЦЕНКА ПОПУЛЯЦИИ ===
            let scoredPopulation: [ScoredGenome]
            
            if config.parallelEvaluation {
                scoredPopulation = evaluatePopulationParallel(
                    population: population,
                    baseTuning: baseTuning,
                    context: generationEvaluationContext,
                    maxThreads: config.maxEvaluationThreads
                )
            } else {
                scoredPopulation = population.map { genome in
                    let breakdown = evaluateGenome(genome, baseTuning: baseTuning, context: generationEvaluationContext)
                    return ScoredGenome(genome: genome, breakdown: breakdown)
                }
            }
            
            // ... остальная логика ...
        }
    }
    
    /// Параллельная оценка популяции
    private static func evaluatePopulationParallel(
        population: [EvolutionGenome],
        baseTuning: BotTuning,
        context: FitnessEvaluationContext,
        maxThreads: Int
    ) -> [ScoredGenome] {
        let queue = DispatchQueue(label: "bot.evolution", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        var results: [ScoredGenome] = Array(repeating: ScoredGenome(genome: .identity, breakdown: .zero), count: population.count)
        
        for (index, genome) in population.enumerated() {
            group.enter()
            queue.async {
                let breakdown = evaluateGenome(genome, baseTuning: baseTuning, context: context)
                results[index] = ScoredGenome(genome: genome, breakdown: breakdown)
                group.leave()
            }
        }
        
        group.wait()
        return results
    }
}

// Обновление конфигурации:
extension SelfPlayEvolutionConfig {
    // === НОВОЕ: ПАРАЛЛЕЛИЗАЦИЯ ===
    
    /// Включить параллельную оценку геномов
    let parallelEvaluation: Bool
    
    /// Максимальное количество потоков для оценки
    /// 0 = использовать все доступные CPU
    let maxEvaluationThreads: Int
    
    /// Параллелизация внутри оценки игр (для больших gamesPerCandidate)
    let parallelGameEvaluation: Bool
}
```

#### Решение 4.2: Оптимизация симуляций

```swift
// Файл: BotSelfPlayEvolutionEngine+Simulation.swift

extension BotSelfPlayEvolutionEngine {
    /// Оптимизированная симуляция с кэшированием
    static func simulateGameOptimized(
        tuningsBySeat: [BotTuning],
        rounds: Int,
        cardsPerRoundRange: ClosedRange<Int>,
        seed: UInt64,
        useFullMatchRules: Bool
    ) -> SimulatedGameOutcome {
        // === КЭШИРОВАНИЕ РАСПРЕДЕЛЕНИЙ КАРТ ===
        // Предварительно сгенерировать все раздачи для семян
        // Избежать повторных вычислений Dealer
        
        // === БЫСТРАЯ СИМУЛЯЦИЯ БЕЗ UI ===
        // Отключить все задержки и анимации
        // Использовать упрощённую модель TrickResolution
        
        // === ВЕКТОРИЗАЦИЯ ===
        // Группировать одинаковые операции для SIMD
    }
}
```

---

### 5. Contextual Opponent Modeling

**Приоритет:** 🟡 **Средний**  
**Сложность:** Высокая  
**Ожидаемый эффект:** +10% win rate против сильных соперников

#### Проблема

`OpponentIntentionModel` строится только на основе **текущей взятки**, без истории:

- ❌ Не учитывает стиль соперника (агрессивный/консервативный)
- ❌ Не запоминает паттерны розыгрыша джокеров
- ❌ Не отслеживает "виртуальные" карты (что соперник *должен* иметь)
- ❌ Не адаптируется по ходу матча

#### Решение

```swift
// Файл: Models/Bot/BotOpponentModel.swift (создать новый)

import Foundation

/// Расширенная модель соперника с историей и адаптацией
struct AdvancedOpponentModel {
    /// История розыгрышей джокеров игроком
    struct JokerPlayHistory {
        var totalJokerPlays: Int = 0
        var faceUpPlays: Int = 0
        var faceDownPlays: Int = 0
        var wishDeclarations: Int = 0
        var aboveDeclarations: Int = 0
        var takesDeclarations: Int = 0
        var successfulPlays: Int = 0  // джокер выиграл взятку
        
        var faceUpRate: Double {
            guard totalJokerPlays > 0 else { return 0.5 }
            return Double(faceUpPlays) / Double(totalJokerPlays)
        }
        
        var successRate: Double {
            guard totalJokerPlays > 0 else { return 0.5 }
            return Double(successfulPlays) / Double(totalJokerPlays)
        }
    }
    
    /// Индекс агрессивности игрока
    struct AggressionIndex {
        /// % взятия взяток сверх ставки
        var overbidRate: Double = 0.5
        
        /// % агрессивных ходов (расход джокера, козыря без необходимости)
        var aggressiveMoveRate: Double = 0.5
        
        /// Средняя разница между взятыми и заказанными взятками
        var averageOverbidDelta: Double = 0.0
        
        /// Общий индекс агрессивности [0, 1]
        var compositeIndex: Double {
            return (overbidRate * 0.4 + aggressiveMoveRate * 0.4 + min(1.0, abs(averageOverbidDelta) / 3.0) * 0.2)
        }
    }
    
    /// Модель блефа игрока
    struct BluffModel {
        /// % проигрышных джокеров лицом вверх
        var failedFaceUpRate: Double = 0.0
        
        /// % ходов с заведомо проигрышной картой
        var sacrificialMoveRate: Double = 0.0
        
        /// Индекс склонности к блефу [0, 1]
        var bluffIndex: Double {
            return (failedFaceUpRate * 0.6 + sacrificialMoveRate * 0.4)
        }
    }
    
    /// Выведенные пустые масти соперника
    struct VoidInference {
        var inferredVoids: Set<Suit> = []
        var probableVoids: Set<Suit> = []  // масти, которых скорее всего нет
        var confidence: [Suit: Double] = [:]  // уверенность в выводе
    }
    
    // === ДАННЫЕ ПО КАЖДОМУ СОПЕРНИКУ ===
    
    /// PlayerIndex → история джокеров
    var jokerHistory: [Int: JokerPlayHistory] = [:]
    
    /// PlayerIndex → индекс агрессивности
    var aggressionIndex: [Int: AggressionIndex] = [:]
    
    /// PlayerIndex → модель блефа
    var bluffModel: [Int: BluffModel] = [:]
    
    /// PlayerIndex → выведенные масти
    var voidInferences: [Int: VoidInference] = [:]
    
    /// PlayerIndex → история заказов (склонность к завышению/занижению)
    var biddingHistory: [Int: BiddingPattern] = [:]
    
    struct BiddingPattern {
        var averageBidAccuracy: Double = 0.0
        var overbidFrequency: Double = 0.5
        var underbidFrequency: Double = 0.5
        var blindBidFrequency: Double = 0.0
    }
    
    // === МЕТОДЫ ОБНОВЛЕНИЯ ===
    
    mutating func updateAfterTrick(
        trick: [PlayedTrickCard],
        trump: Suit?,
        playerBids: [Int],
        playerTricksTaken: [Int]
    ) {
        // Обновить статистику по итогам взятки
        for played in trick {
            updateJokerHistory(for: played.playerIndex, played: played)
            updateAggressionIndex(for: played.playerIndex, trick: trick, trump: trump)
        }
        
        updateBiddingHistory(playerBids: playerBids, playerTricksTaken: playerTricksTaken)
    }
    
    mutating func updateJokerHistory(for playerIndex: Int, played: PlayedTrickCard) {
        guard played.card.isJoker else { return }
        
        if jokerHistory[playerIndex] == nil {
            jokerHistory[playerIndex] = JokerPlayHistory()
        }
        
        var history = jokerHistory[playerIndex]!
        history.totalJokerPlays += 1
        
        if played.jokerPlayStyle == .faceUp {
            history.faceUpPlays += 1
        } else {
            history.faceDownPlays += 1
        }
        
        switch played.jokerLeadDeclaration {
        case .wish:
            history.wishDeclarations += 1
        case .above:
            history.aboveDeclarations += 1
        case .takes:
            history.takesDeclarations += 1
        case nil:
            break
        }
        
        // Успех будет обновлён после определения победителя взятки
        
        jokerHistory[playerIndex] = history
    }
    
    // === МЕТОДЫ ПРОГНОЗА ===
    
    /// Предсказать вероятность агрессивного хода соперника
    func predictAggressiveMoveProbability(for playerIndex: Int) -> Double {
        return aggressionIndex[playerIndex]?.compositeIndex ?? 0.5
    }
    
    /// Предсказать вероятность блефа соперника
    func predictBluffProbability(for playerIndex: Int) -> Double {
        return bluffModel[playerIndex]?.bluffIndex ?? 0.0
    }
    
    /// Получить вероятные пустые масти соперника
    func getProbableVoids(for playerIndex: Int) -> Set<Suit> {
        return voidInferences[playerIndex]?.probableVoids ?? []
    }
}
```

#### Интеграция в `BotTurnCandidateEvaluatorService`

```swift
// Файл: Services/AI/BotTurnCandidateEvaluatorService.swift

extension BotTurnCandidateEvaluatorService {
    func bestMove(context: DecisionContext) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        // === ИСПОЛЬЗОВАНИЕ ADVANCED OPPONENT MODEL ===
        
        if let advancedModel = context.tableContext.matchContext?.advancedOpponentModel {
            for opponentIndex in remainingOpponentPlayerIndices ?? [] {
                // Корректировка utility на основе агрессивности соперника
                let aggression = advancedModel.aggressionIndex[opponentIndex]?.compositeIndex ?? 0.5
                
                if aggression > 0.7 {
                    // Агрессивный соперник → чаще сбрасывать угрозы
                    utilityContext.aggressionAdjustment *= 1.2
                }
                
                // Корректировка на основе блефа
                let bluffProb = advancedModel.bluffModel[opponentIndex]?.bluffIndex ?? 0.0
                
                if bluffProb > 0.3 {
                    // Соперник блефует → меньше верить его сильным ходам
                    beliefState = adjustBeliefForBluff(beliefState, bluffProbability: bluffProb)
                }
            }
        }
        
        // ... остальная логика
    }
}
```

---

### 6. Улучшение rollout-политики

**Приоритет:** 🟡 **Средний**  
**Сложность:** Средняя  
**Ожидаемый эффект:** +5-8% в эндшпиле

#### Проблема

`BotTurnRolloutService` использует упрощённую симуляцию:

- ❌ Соперники играют "жадно" без полной стратегии
- ❌ Не учитывается блеф и рандомизация
- ❌ Горизонт rollout фиксированный

#### Решение

```swift
// Файл: BotRuntimePolicy.swift

extension BotRuntimePolicy {
    struct Rollout {
        // === СУЩЕСТВУЮЩИЕ ПАРАМЕТРЫ ===
        let minimumIterations: Int
        let maximumIterations: Int
        // ...
        
        // === НОВОЕ: УЛУЧШЕННАЯ ПОЛИТИКА ===
        
        /// Уровень интеллекта симуляции соперников
        /// 0 = жадный, 1 = heuristic, 2 = полный AI
        let opponentModelFidelity: Int
        
        /// Вероятность симуляции блефа соперника
        /// > 0 = часть симуляций с заведомо проигрышными ходами
        let bluffSimulationRate: Double
        
        /// Включить динамический горизонт rollout
        /// true = адаптировать глубину по важности хода
        let adaptiveHorizon: Bool
        
        /// Минимальный горизонт для adaptiveHorizon
        let minAdaptiveHorizon: Int
        
        /// Максимальный горизонт для adaptiveHorizon
        let maxAdaptiveHorizon: Int
        
        /// Порог важности для увеличения горизонта
        /// Если важность > threshold, использовать maxHorizon
        let importanceThreshold: Double
        
        /// Вес rollout в итоговой utility
        /// Может быть адаптирован по фазе игры
        let dynamicWeight: Bool
        
        /// Минимальный вес rollout
        let minWeight: Double
        
        /// Максимальный вес rollout
        let maxWeight: Double
    }
}

// Файл: BotTurnRolloutService.swift

extension BotTurnRolloutService {
    /// Адаптивный выбор горизонта rollout
    func selectAdaptiveHorizon(
        context: DecisionContext,
        scoredCandidates: [CandidateScore]
    ) -> Int {
        guard policy.adaptiveHorizon else {
            return policy.maxTrickHorizon
        }
        
        // Вычислить важность текущего хода
        let importance = computeMoveImportance(context: context, scoredCandidates: scoredCandidates)
        
        if importance > policy.importanceThreshold {
            return policy.maxAdaptiveHorizon
        } else if importance < policy.importanceThreshold * 0.5 {
            return policy.minAdaptiveHorizon
        } else {
            // Линейная интерполяция
            let normalizedImportance = (importance - policy.importanceThreshold * 0.5) / (policy.importanceThreshold * 0.5)
            return policy.minAdaptiveHorizon + Int(normalizedImportance * Double(policy.maxAdaptiveHorizon - policy.minAdaptiveHorizon))
        }
    }
    
    /// Вычислить важность текущего хода
    private func computeMoveImportance(
        context: DecisionContext,
        scoredCandidates: [CandidateScore]
    ) -> Double {
        var importance = 0.0
        
        // Фактор 1: близость к концу раздачи
        let handSizeFactor = Double(context.handContext.handCards.count) / Double(context.roundContext.cardsInRound)
        importance += (1.0 - handSizeFactor) * 0.3
        
        // Фактор 2: разброс utility кандидатов
        if scoredCandidates.count > 1 {
            let utilities = scoredCandidates.map(\.baselineUtility)
            let utilityRange = (utilities.max() ?? 0) - (utilities.min() ?? 0)
            importance += min(1.0, utilityRange / 10.0) * 0.4
        }
        
        // Фактор 3: критичность для заказа
        let tricksNeeded = context.roundContext.targetBid - context.roundContext.currentTricks
        let cardsRemaining = context.handContext.handCards.count
        let pressureFactor = Double(tricksNeeded) / Double(max(1, cardsRemaining))
        importance += pressureFactor * 0.3
        
        return importance
    }
}
```

---

### 7. Meta-Learning для адаптации по ходу матча

**Приоритет:** 🟡 **Средний**  
**Сложность:** Высокая  
**Ожидаемый эффект:** +5% в длительных матчах

#### Проблема

Бот не адаптируется к **конкретным соперникам** в реальном времени.

#### Решение

```swift
// Файл: Models/Bot/BotRuntimePolicy.swift

extension BotRuntimePolicy {
    /// Политика адаптации по ходу матча
    struct Adaptation {
        /// Скорость обучения opponent model
        /// 0.0 = не обновлять, 1.0 = мгновенная адаптация
        let learningRate: Double
        
        /// Порог для переключения стратегии
        /// Если разница в счёре > threshold, менять агрессивность
        let strategySwitchThreshold: Int
        
        /// Вес контр-стратегии к utility
        /// 0.0 = игнорировать, 1.0 = полная контр-стратегия
        let counterStrategyWeight: Double
        
        /// Минимальное количество ходов перед адаптацией
        /// Предотвращает слишком частые переключения
        let minMovesBeforeAdaptation: Int
        
        /// Максимальное изменение коэффициента за одну адаптацию
        let maxAdaptationStep: Double
        
        /// Включить адаптацию тёмных ставок
        let adaptBlindBids: Bool
        
        /// Включить адаптацию розыгрыша джокеров
        let adaptJokerPlay: Bool
    }
}

// Файл: Services/AI/BotTurnStrategyService.swift

extension BotTurnStrategyService {
    /// Адаптировать стратегию по ходу матча
    func adaptToOpponents(during matchContext: BotMatchContext) -> BotTuning {
        var adaptedTuning = tuning
        
        guard let opponentModel = matchContext.advancedOpponentModel else {
            return adaptedTuning
        }
        
        // === АДАПТАЦИЯ К АГРЕССИВНОСТИ ===
        
        let averageAggression = opponentModel.aggressionIndex.values.map(\.compositeIndex).reduce(0, +) /
            Double(max(1, opponentModel.aggressionIndex.count))
        
        if averageAggression > 0.7 {
            // Против агрессивных: повысить dumpAvoidWinWeight
            adaptedTuning.turnStrategy.dumpAvoidWinWeight *= 1.2
        } else if averageAggression < 0.3 {
            // Против консервативных: повысить chaseWinProbabilityWeight
            adaptedTuning.turnStrategy.chaseWinProbabilityWeight *= 1.15
        }
        
        // === АДАПТАЦИЯ К БЛЕФУ ===
        
        let averageBluff = opponentModel.bluffModel.values.map(\.bluffIndex).reduce(0, +) /
            Double(max(1, opponentModel.bluffModel.count))
        
        if averageBluff > 0.3 {
            // Против блефующих: меньше верить сильным ходам
            adaptedTuning.runtimePolicy.ranking.opponentModeling.bluffDiscountFactor *= 0.8
        }
        
        // === АДАПТАЦИЯ ПО СЧЁТУ ===
        
        let myScore = matchContext.totalScores[matchContext.myPlayerIndex]
        let opponentScores = matchContext.totalScores.enumerated()
            .filter { $0.offset != matchContext.myPlayerIndex }
            .map(\.element)
        let averageOpponentScore = opponentScores.reduce(0, +) / Double(max(1, opponentScores.count))
        
        let scoreDiff = myScore - averageOpponentScore
        
        if scoreDiff < -tuning.runtimePolicy.adaptation.strategySwitchThreshold {
            // Отстаю → повысить агрессивность
            adaptedTuning.turnStrategy.chaseWinProbabilityWeight *= 1.3
            adaptedTuning.turnStrategy.dumpAvoidWinWeight *= 0.7
        } else if scoreDiff > tuning.runtimePolicy.adaptation.strategySwitchThreshold {
            // Лидирую → снизить риск
            adaptedTuning.turnStrategy.chaseWinProbabilityWeight *= 0.8
            adaptedTuning.turnStrategy.dumpAvoidWinWeight *= 1.2
        }
        
        return adaptedTuning
    }
}
```

---

### 8. Transfer Learning между уровнями сложности

**Приоритет:** 🟢 **Низкий**  
**Сложность:** Низкая  
**Ожидаемый эффект:** 2× быстрее обучение

#### Проблема

Боты `.easy`, `.normal`, `.hard` обучаются **независимо**, хотя можно использовать transfer learning.

#### Решение

```swift
// Файл: Models/Bot/BotTuning.swift

extension BotTuning {
    /// Деградировать tuning для более лёгкого уровня
    /// Используется после обучения .hard для быстрого получения .normal/.easy
    func deriveEasierTuning(for level: BotDifficulty) -> BotTuning {
        guard level != .hard else { return self }
        
        let degradationFactor: Double
        switch level {
        case .normal:
            degradationFactor = 0.7
        case .easy:
            degradationFactor = 0.4
        default:
            return self
        }
        
        // === ДОБАВИТЬ ШУМ К ПАРАМЕТРАМ ===
        var degradedTuning = self
        
        // Деградировать turnStrategy
        degradedTuning.turnStrategy = degradeTurnStrategy(
            self.turnStrategy,
            factor: degradationFactor
        )
        
        // Деградировать bidding
        degradedTuning.bidding = degradeBidding(
            self.bidding,
            factor: degradationFactor
        )
        
        // Ограничить rollout/endgame для слабых уровней
        degradedTuning.runtimePolicy = limitRuntimePolicy(
            self.runtimePolicy,
            for: level
        )
        
        // Увеличить задержки для естественности
        degradedTuning.timing = degradeTiming(
            self.timing,
            for: level
        )
        
        return degradedTuning
    }
    
    private func degradeTurnStrategy(_ strategy: TurnStrategy, factor: Double) -> TurnStrategy {
        // Добавить шум к коэффициентам
        return TurnStrategy(
            utilityTieTolerance: strategy.utilityTieTolerance * (1.0 + factor * 0.5),
            chaseWinProbabilityWeight: strategy.chaseWinProbabilityWeight * (1.0 - factor * 0.3),
            chaseThreatPenaltyWeight: strategy.chaseThreatPenaltyWeight * (1.0 - factor * 0.2),
            // ... деградировать все параметры
            powerNormalizationValue: strategy.powerNormalizationValue * (1.0 - factor * 0.1)
        )
    }
    
    private func limitRuntimePolicy(_ policy: BotRuntimePolicy, for level: BotDifficulty) -> BotRuntimePolicy {
        var limitedPolicy = policy
        
        switch level {
        case .easy:
            // Отключить rollout и endgame для easy
            limitedPolicy.rollout.minimumIterations = 0
            limitedPolicy.rollout.maximumIterations = 0
            limitedPolicy.endgame.minimumIterations = 0
            limitedPolicy.endgame.maximumIterations = 0
        case .normal:
            // Ограничить итерации для normal
            limitedPolicy.rollout.maximumIterations /= 2
            limitedPolicy.endgame.maximumIterations /= 2
        default:
            break
        }
        
        return limitedPolicy
    }
    
    private func degradeTiming(_ timing: Timing, for level: BotDifficulty) -> Timing {
        switch level {
        case .easy:
            return Timing(
                playingBotTurnDelay: timing.playingBotTurnDelay * 2.0,
                biddingStepDelay: timing.biddingStepDelay * 2.0,
                trickResolutionDelay: timing.trickResolutionDelay * 1.5
            )
        case .normal:
            return Timing(
                playingBotTurnDelay: timing.playingBotTurnDelay * 1.5,
                biddingStepDelay: timing.biddingStepDelay * 1.5,
                trickResolutionDelay: timing.trickResolutionDelay * 1.2
            )
        default:
            return timing
        }
    }
}
```

---

## Сводная таблица приоритетов

| № | Предложение | Ожидаемый эффект | Сложность | Время реализации | Приоритет |
|---|-------------|------------------|-----------|------------------|-----------|
| 1 | Расширение фитнес-функции | +15-20% win rate | Низкая | 1-2 дня | 🔴 Высокий |
| 2 | Фазовые модификаторы | +10-15% точность добора | Средняя | 3-4 дня | 🔴 Высокий |
| 3 | Улучшение GA (speciation, novelty) | +20% скорость сходимости | Средняя | 5-7 дней | 🔴 Высокий |
| 4 | Параллелизация | 4-8× ускорение обучения | Средняя | 3-4 дня | 🔴 Высокий |
| 5 | Contextual Opponent Modeling | +10% против сильных | Высокая | 7-10 дней | 🟡 Средний |
| 6 | Улучшение rollout-политики | +5-8% в эндшпиле | Средняя | 4-5 дней | 🟡 Средний |
| 7 | Meta-Learning адаптация | +5% в длительных матчах | Высокая | 5-7 дней | 🟡 Средний |
| 8 | Transfer Learning | 2× быстрее обучение | Низкая | 2-3 дня | 🟢 Низкий |

---

## План внедрения

### Фаза 1: Быстрые победы (Недели 1-2)

**Цель:** Максимальный эффект при минимальных изменениях

```
Неделя 1:
├── День 1-2: Расширение фитнес-функции
│   ├── Добавить jokerEfficiencyWeight
│   ├── Добавить earlyJokerSpendPenaltyWeight
│   ├── Добавить antiPremiumSuccessWeight
│   └── Запустить валидацию на 10 поколениях
│
├── День 3-4: Параллелизация оценки геномов
│   ├── DispatchGroup для параллельной оценки
│   ├── Тестирование на 4-8 потоках
│   └── Замер ускорения (ожидаем 3-4×)
│
└── День 5: Интеграция и тестирование
    ├── Полный прогон эволюции (50 поколений)
    └── Сравнение с baseline

Неделя 2:
└── Фазовые модификаторы
    ├── Добавить PhaseModifiers в BotTuning
    ├── Интеграция в BotTurnStrategyService
    ├── Обучение фазовых коэффициентов
    └── Валидация на тестовых матчах
```

**Ожидаемый результат Фазы 1:** +25-35% win rate, 4× ускорение обучения

---

### Фаза 2: Улучшение эволюции (Недели 3-4)

**Цель:** Стабильная сходимость к глобальному оптимуму

```
Неделя 3:
├── Speciation (разделение на виды)
│   ├── Реализовать geneticDistance()
│   ├── Реализовать speciate()
│   ├── Добавить species-protected selection
│   └── Подбор speciationThreshold
│
└── Novelty Search
    ├── Реализовать noveltyScore()
    ├── Добавить novelty archive
    └── Подбор noveltySearchWeight

Неделя 4:
├── Адаптивная мутация
│   ├── populationDiversity()
│   ├── adaptMutationRate()
│   └── Интеграция в evolution loop
│
└── Комплексное тестирование
    ├── 100 поколений эволюции
    ├── Сравнение diversity с/без speciation
    └── Замер скорости сходимости
```

**Ожидаемый результат Фазы 2:** +20% скорость сходимости, избегание локальных оптимумов

---

### Фаза 3: Продвинутые функции (Недели 5-8)

**Цель:** Качественный скачок интеллекта ботов

```
Недели 5-6: Contextual Opponent Modeling
├── Создать AdvancedOpponentModel
├── Интеграция в BotMatchContext
├── Методы обновления статистики
├── Методы прогноза поведения
└── Интеграция в BotTurnCandidateEvaluatorService

Недели 7-8: Rollout + Meta-Learning
├── Улучшение rollout-политики
│   ├── adaptiveHorizon
│   ├── opponentModelFidelity
│   └── bluffSimulationRate
│
├── Meta-Learning адаптация
│   ├── Adaptation policy
│   ├── adaptToOpponents()
│   └── Real-time strategy switching
│
└── Комплексная валидация
    ├── Матчи против .hard ботов
    ├── Замер win rate
    └── Анализ логов решений
```

**Ожидаемый результат Фазы 3:** +15-20% win rate против сильных соперников

---

### Фаза 4: Оптимизация и полировка (Недели 9-10)

**Цель:** Production-ready решение

```
Неделя 9: Transfer Learning
├── deriveEasierTuning() для .normal/.easy
├── Валидация деградированных тюнингов
└── Обучение только .hard + transfer

Неделя 10: Финальная оптимизация
├── Профилирование производительности
├── Оптимизация узких мест
├── Документирование API
└── Написание unit-тестов
```

---

## Метрики успеха

### Ключевые показатели

| Метрика | Baseline | Цель после Фазы 2 | Цель после Фазы 4 |
|---------|----------|-------------------|-------------------|
| Win rate vs .hard | 50% | 65% | 75% |
| Скорость сходимости | 100 поколений | 80 поколений | 60 поколений |
| Время обучения (1 поколение) | 60 мин | 15 мин | 10 мин |
| Joker efficiency | 60% | 75% | 85% |
| Blind bid accuracy | ±2 взятки | ±1.5 взятки | ±1 взятка |
| Anti-premium success | 50% | 70% | 85% |

### Методы валидации

1. **Head-to-Head матчи:** 1000 игр против baseline .hard
2. **Эволюционный трекинг:** График fitness по поколениям
3. **A/B тестирование:** Сравнение до/после каждого изменения
4. **Анализ логов:** Разбор критических решений

---

## Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Переобучение на self-play | Средняя | Высокое | Добавить разнообразие в оппонентов, novelty search |
| Замедление обучения | Низкая | Среднее | Параллелизация, кэширование симуляций |
| Нестабильная сходимость | Средняя | Среднее | Speciation, adaptive mutation |
| Сложность отладки | Высокая | Низкое | Детальное логирование, unit-тесты |
| Конфликты параметров | Средняя | Низкое | Поэтапное внедрение, валидация |

---

## Приложения

### A. Структура файлов для изменений

```
Jocker/
├── Models/
│   └── Bot/
│       ├── BotTuning.swift                    # ⚠️ Изменить: добавить PhaseModifiers
│       ├── BotRuntimePolicy.swift             # ⚠️ Изменить: добавить Adaptation, улучшенный Rollout
│       └── BotOpponentModel.swift             # ✅ Создать: AdvancedOpponentModel
│
├── Game/
│   └── Services/
│       └── AI/
│           ├── BotSelfPlayEvolutionEngine.swift
│           ├── BotSelfPlayEvolutionEngine+Evolution.swift  # ⚠️ Изменить: speciation, novelty
│           ├── BotSelfPlayEvolutionEngine+Fitness.swift    # ⚠️ Изменить: расширенная фитнес-функция
│           ├── BotSelfPlayEvolutionEngine+FitnessScoring.swift  # ✅ Создать
│           ├── BotTurnStrategyService.swift   # ⚠️ Изменить: адаптация, фазовые модификаторы
│           ├── BotTurnCandidateEvaluatorService.swift  # ⚠️ Изменить: opponent model integration
│           ├── BotTurnRolloutService.swift    # ⚠️ Изменить: adaptive horizon
│           └── BotTurnSamplingService.swift   # ✅ Без изменений
│
└── Tests/
    └── Bot/
        ├── BotSelfPlayEvolutionEngineTests.swift
        ├── BotAdvancedOpponentModelTests.swift  # ✅ Создать
        └── BotPhaseModifierTests.swift          # ✅ Создать
```

### B. Пример конфигурации для запуска эволюции

```swift
let config = BotTuning.SelfPlayEvolutionConfig(
    // Популяция
    populationSize: 24,
    eliteCount: 4,
    selectionPoolRatio: 0.4,
    
    // Поколения
    generations: 100,
    gamesPerCandidate: 50,
    
    // Мутация
    mutationChance: 0.15,
    mutationMagnitude: 0.12,
    
    // Speciation (НОВОЕ)
    speciationThreshold: 3.0,
    minSpeciesSize: 2,
    speciesProtectionGenerations: 3,
    speciesRelativeFitnessWeight: 0.3,
    targetSpeciesCount: 4,
    speciesCompetitionPenalty: 0.1,
    
    // Novelty Search (НОВОЕ)
    noveltySearchWeight: 0.15,
    noveltyKNeighbors: 5,
    noveltyArchiveSize: 100,
    noveltyArchiveThreshold: 2.0,
    noveltyArchiveUpdateFrequency: 5,
    
    // Адаптивная мутация (НОВОЕ)
    adaptiveMutationRate: true,
    minMutationChance: 0.05,
    maxMutationChance: 0.30,
    diversityThreshold: 1.5,
    lowDiversityMutationMultiplier: 2.0,
    
    // Параллелизация (НОВОЕ)
    parallelEvaluation: true,
    maxEvaluationThreads: 0,  // 0 = все доступные CPU
    parallelGameEvaluation: true,
    
    // Фитнес (расширенный)
    fitnessWinRateWeight: 0.50,
    fitnessScoreDiffWeight: 0.20,
    fitnessUnderbidLossWeight: 0.10,
    fitnessTrumpDensityUnderbidWeight: 0.05,
    fitnessNoTrumpControlUnderbidWeight: 0.05,
    fitnessPremiumAssistWeight: 0.05,
    fitnessPremiumPenaltyTargetWeight: 0.05,
    // Новые веса:
    fitnessJokerEfficiencyWeight: 0.15,
    fitnessEarlyJokerSpendPenaltyWeight: 0.10,
    fitnessTrumpSelectionAccuracyWeight: 0.08,
    fitnessAntiPremiumSuccessWeight: 0.12,
    fitnessBlindBidAccuracyWeight: 0.07,
    
    // Early stopping
    earlyStoppingPatience: 15,
    earlyStoppingWarmupGenerations: 20,
    earlyStoppingMinImprovement: 0.005,
    
    // Игра
    playerCount: 4,
    roundsPerGame: 8,
    cardsPerRoundRange: 6...10,
    useFullMatchRules: true,
    rotateCandidateAcrossSeats: true
)

let result = BotTuning.evolveViaSelfPlay(
    baseTuning: BotTuning(difficulty: .hard),
    config: config,
    seed: 0x5EED
) { progress in
    print("Поколение \(progress.generationIndex ?? 0): fitness = \(progress.currentFitness ?? 0)")
}
```

---

## Заключение

Предложенные улучшения разделены на **4 фазы** с чёткими приоритетами:

1. **Фаза 1 (Недели 1-2):** Быстрые победы — фитнес-функция + параллелизация
2. **Фаза 2 (Недели 3-4):** Улучшение эволюции — speciation + novelty search
3. **Фаза 3 (Недели 5-8):** Продвинутые функции — opponent modeling + meta-learning
4. **Фаза 4 (Недели 9-10):** Оптимизация — transfer learning + полировка

**Ожидаемый совокупный эффект:**
- **+40-50% win rate** против текущих .hard ботов
- **6-8× ускорение обучения**
- **Более стабильная сходимость** к глобальному оптимуму
- **Адаптивность** к разным стилям игры

Рекомендуется начинать с **Фазы 1** для быстрой демонстрации прогресса, затем последовательно внедрять остальные фазы с валидацией после каждой.
