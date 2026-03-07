# Анализ планов BOT_AI_LEARNING_IMPROVEMENT_DETAILED_PLANS

**Дата:** 6 марта 2026 г.  
**Статус:** Review текущей кодовой базы vs детальные планы (этапы 01-08)

---

## Общее резюме

Проанализированы 8 детальных планов улучшения AI и текущая кодовая база. Планы составлены грамотно, с чёткой декомпозицией и зависимостями. Однако выявлены **критические расхождения** между планами и реализацией, а также **архитектурные риски**.

---

## Критические замечания

### 🔴 КРИТИЧЕСКОЕ 1. Этап 01 не выполнен — training pipeline использует heredoc-генерацию

**План (01_TRAINING_PIPELINE_RECOVERY_PLAN.md):**
> Шаг 3. Вынести training runner в checked-in Swift entrypoint
> - Оставить в `scripts/train_bot_tuning.sh` только orchestration
> - **Полностью удалить генерацию `main.swift` через heredoc**

**Реальность (`scripts/train_bot_tuning.sh`, строки 580-700+):**
```bash
runner_main="$build_dir/main.swift"
runner_bin="$build_dir/bot_training_runner"

cat > "$runner_main" <<SWIFT
import Foundation
import Darwin

// ... 600+ строк heredoc с генерацией main.swift ...
// Прямое знание внутренней формы BotTuning
// Дублирование структуры модели в shell-скрипте
SWIFT
```

**Проблема:**
- heredoc содержит **дублирование структуры `BotTuning`** в Swift-коде внутри shell-скрипта
- При изменении `BotTuning` требуется править heredoc в shell-скрипте
- Это **нарушает принцип single source of truth**
- План требует "полностью удалить heredoc", но это **не сделано**

**Последствия:**
- Следующее изменение `BotTuning` (например, добавление нового поля) **сломает training pipeline**
- Разработчики не знают о необходимости править heredoc в shell-скрипте
- Training tooling **не синхронизировано** с моделью

**Рекомендация:**
```swift
// Файл: JockerSelfPlayTools/Sources/bot-training-runner/main.swift (создать)
import Foundation
import JockerSelfPlayTools

// Checked-in entrypoint, а не heredoc
@main
struct TrainingRunner {
    static func main() throws {
        // Парсинг аргументов
        // Запуск BotSelfPlayEvolutionEngine.evolveViaSelfPlay
        // Вывод structured output
    }
}
```

**Приоритет:** 🔴 **Блокирующий** — не продолжать этапы 02-08 до исправления

---

### 🔴 КРИТИЧЕСКОЕ 2. Отсутствует baseline-only режим

**План (01_TRAINING_PIPELINE_RECOVERY_PLAN.md):**
> Шаг 4. Ввести явный baseline-only режим
> - Добавить в `BotSelfPlayEvolutionEngine+PublicTypes.swift` режим `baselineOnly`
> - Удалить семантику baseline-only через `--generations 0`

**Реальность (`scripts/train_bot_tuning.sh`):**
```bash
# Нет явного baseline-only режима
# Baseline запускается через --generations 0 (костыль)
```

**Реальность (`BotSelfPlayEvolutionEngine+PublicTypes.swift`):**
```swift
struct SelfPlayEvolutionConfig {
    let generations: Int  // Нет флага baselineOnly
}
```

**Проблема:**
- Baseline-запуск использует `--generations 0` как **семантический костыль**
- Это создаёт путаницу: "0 поколений" ≠ "baseline evaluation"
- Нет отдельного API для baseline

**Рекомендация:**
```swift
struct SelfPlayEvolutionConfig {
    let baselineOnly: Bool  // ← Добавить
    let generations: Int
}

// В evolveViaSelfPlay:
if config.baselineOnly {
    return evaluateBaselineOnly(...)  // ← Отдельный путь
}
```

**Приоритет:** 🔴 **Высокий** — влияет на корректность baseline harness

---

### 🔴 КРИТИЧЕСКОЕ 3. Fitness не разделён на primary/guardrail

**План (02_FITNESS_GUARDRAILS_EXPANSION_PLAN.md):**
> Шаг 1. Разделить fitness на два слоя:
> - `primaryFitness` (winRate, scoreDiff, underbidLoss)
> - `guardrailPenalty` (bidAccuracy, overbidRate, blindSuccessRate, etc.)

**Реальность (`BotSelfPlayEvolutionEngine+Fitness.swift`):**
```swift
func fitness(
    winRate: Double,
    averageScoreDiff: Double,
    averageUnderbidLoss: Double,
    // ...
) -> Double {
    return winRate * winRateWeight +
        (averageScoreDiff / scoreDiffNormalization) * scoreDiffWeight +
        -(averageUnderbidLoss / underbidLossNormalization) * underbidLossWeight
        // Все метрики в одной формуле, нет разделения
}
```

**Проблема:**
- **Нет разделения** на primary objective и guardrail-штрафы
- Невозможно отладить, какая компонента вызывает деградацию
- Guardrail-метрики (jokerWishWinRate, blindSuccessRate) **не влияют на fitness**

**Рекомендация:**
```swift
struct FitnessScoringConfig {
    func computePrimaryFitness(...) -> Double { ... }
    func computeGuardrailPenalty(...) -> Double { ... }
    
    func finalFitness(primary: Double, guardrail: Double) -> Double {
        return primary - guardrail
    }
}
```

**Приоритет:** 🔴 **Высокий** — влияет на качество обучения

---

### 🔴 КРИТИЧЕСКОЕ 4. Genome не включает runtimePolicy

**План (03_RUNTIME_POLICY_EVOLUTION_SCOPE_PLAN.md):**
> Шаг 5. Расширить `EvolutionGenome`:
> - `rankingMatchCatchUpScale`
> - `rankingPremiumScale`
> - `rolloutActivationScale`
> - `endgameAdjustmentScale`
> - `opponentPressureScale`

**Реальность (`BotSelfPlayEvolutionEngine+Genome.swift`):**
```swift
struct EvolutionGenome {
    // Только turnStrategy и bidding scales
    var chaseWinProbabilityScale: Double
    var biddingJokerPowerScale: Double
    // ...
    
    // НЕТ runtimePolicy scales
}
```

**Проблема:**
- Genome **не эволюционирует runtimePolicy** (ranking, rollout, endgame, opponentModeling)
- Это **~50% коэффициентов бота** остаются зафиксированными
- Self-play **не оптимизирует** критические policy-кластеры

**Рекомендация:**
```swift
struct EvolutionGenome {
    // Существующие поля...
    
    // ← ДОБАВИТЬ:
    var rankingMatchCatchUpScale: Double
    var rankingPremiumPreserveScale: Double
    var rankingPenaltyAvoidScale: Double
    var rolloutActivationScale: Double
    var rolloutAdjustmentScale: Double
    var endgameActivationScale: Double
    var endgameAdjustmentScale: Double
    var opponentPressureScale: Double
    var jokerDeclarationScale: Double
}
```

**Приоритет:** 🔴 **Высокий** — ограничивает эффективность обучения

---

### 🟡 ВАЖНОЕ 5. Фазовые multipliers не реализованы

**План (04_PHASE_CONDITIONED_POLICY_MULTIPLIERS_PLAN.md):**
> Шаг 1. Создать тип `BotBlockPhase` (early/mid/late)
> Шаг 2. Добавить фазовые multipliers в policy-секции

**Реальность:**
- Тип `BotBlockPhase` **не существует**
- Фазовые multipliers **не добавлены**
- Бот играет одинаково на 1-й и 8-й раздаче блока

**Проблема:**
- Стратегия не адаптируется по фазе блока
- Ранний расход джокера не штрафуется
- Поздняя фаза не получает агрессивности

**Рекомендация:**
```swift
enum BotBlockPhase {
    case early  // раздачи 1-3
    case mid    // раздачи 4-6
    case late   // раздачи 7-8
    
    static func from(roundIndex: Int, totalRounds: Int) -> Self {
        let fraction = Double(roundIndex) / Double(totalRounds)
        if fraction < 0.375 { return .early }
        if fraction < 0.75 { return .mid }
        return .late
    }
}
```

**Приоритет:** 🟡 **Средний** — улучшение, а не исправление

---

### 🟡 ВАЖНОЕ 6. Параллелизация не реализована

**План (05_PARALLEL_CANDIDATE_EVALUATION_PLAN.md):**
> Шаг 4. Перевести generation loop на structured concurrency

**Реальность (`BotSelfPlayEvolutionEngine+Evolution.swift`):**
```swift
for (candidateOffset, genome) in population.enumerated() {
    let breakdown = evaluateGenome(...)  // ← Последовательно
    scoredPopulation.append(...)
}
```

**Проблема:**
- Оценка кандидатов **последовательная**
- 20 кандидатов × 100 игр = 2000 симуляций **последовательно**
- Время обучения: **4-6 часов** на поколение

**Ожидаемое ускорение:**
- 4 CPU → 4× быстрее
- 8 CPU → 8× быстрее

**Рекомендация:**
```swift
let scoredPopulation: [ScoredGenome] = await withTaskGroup(
    of: (Int, ScoredGenome).self,
    returning: [ScoredGenome].self
) { group in
    for (index, genome) in population.enumerated() {
        group.addTask {
            let breakdown = evaluateGenome(...)
            return (index, ScoredGenome(genome: genome, breakdown: breakdown))
        }
    }
    
    // Merge результатов
}
```

**Приоритет:** 🟡 **Средний** — влияет на скорость, а не корректность

---

### 🟡 ВАЖНОЕ 7. Отсутствует diversity telemetry

**План (06_EVOLUTION_SEARCH_STABILITY_PLAN.md):**
> Шаг 1. Добавить diversity telemetry:
> - средняя дистанция до элиты
> - средняя попарная дистанция
> - доля уникальных signatures

**Реальность:**
- Diversity **не измеряется**
- Stagnation **не детектируется**
- Adaptive mutation **не реализован**

**Проблема:**
- Популяция может **выродиться** к одному типу
- Алгоритм застревает в **локальном оптимуме**
- Нет механизма **восстановления разнообразия**

**Рекомендация:**
```swift
func populationDiversity(population: [EvolutionGenome]) -> Double {
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
```

**Приоритет:** 🟡 **Средний** — влияет на стабильность обучения

---

### 🟡 ВАЖНОЕ 8. Opponent model v2 не реализован

**План (07_OPPONENT_MODEL_V2_PLAN.md):**
> Шаг 1. Расширить модель:
> - block-level и match-level наблюдения
> - joker usage style
> - aggression score
> - volatility score

**Реальность (`BotOpponentModel.swift`):**
```swift
struct BotOpponentModel {
    // Только текущая взятка
    // Нет истории
    // Нет match-level памяти
}
```

**Проблема:**
- Бот **не запоминает** стиль соперников
- Не адаптируется к **агрессивным/консервативным** игрокам
- Не использует **историю джокеров** соперника

**Рекомендация:**
```swift
struct AdvancedOpponentModel {
    struct MatchObservations {
        var jokerHistory: [Int: JokerPlayHistory] = [:]
        var aggressionIndex: [Int: Double] = [:]
        var bluffFrequency: [Int: Double] = [:]
    }
    
    var currentBlock: BlockObservations = .init()
    var currentMatch: MatchObservations = .init()
}
```

**Приоритет:** 🟡 **Средний** — улучшение против сильных соперников

---

### 🟢 МИНОРНОЕ 9. Experiment harness не имеет machine-readable output

**План (08_EXPERIMENT_HARNESS_AND_REPORTING_PLAN.md):**
> Шаг 1. Ввести machine-readable артефакты:
> - `summary.json`
> - `per-seed-metrics.json`
> - `comparison.json`

**Реальность:**
- Training runner выводит **только text log**
- Нет **structured JSON output**
- Scripts парсят **human-readable log**

**Проблема:**
- Невозможно автоматически анализировать результаты
- Сравнение baseline vs candidate **вручную**
- Нет интеграции с **CI/CD**

**Рекомендация:**
```swift
struct TrainingSummary: Codable {
    let bestFitness: Double
    let baselineFitness: Double
    let improvement: Double
    let bestTuning: BotTuning
    let perSeedMetrics: [SeedMetrics]
}

// Вывод в JSON:
let encoder = JSONEncoder()
let json = try encoder.encode(summary)
FileManager.default.createFile(atPath: "summary.json", contents: json)
```

**Приоритет:** 🟢 **Низкий** — улучшает workflow, а не корректность

---

## Сводная таблица статусов

| Этап | Статус | Критичность | Блокирует |
|------|--------|-------------|-----------|
| 01. Training pipeline recovery | ❌ Не выполнен | 🔴 Критический | Все этапы 02-08 |
| 02. Fitness guardrails expansion | ❌ Не выполнен | 🔴 Высокий | Качество обучения |
| 03. Runtime policy evolution scope | ❌ Не выполнен | 🔴 Высокий | Эффективность genome |
| 04. Phase-conditioned multipliers | ❌ Не выполнен | 🟡 Средний | Адаптивность бота |
| 05. Parallel candidate evaluation | ❌ Не выполнен | 🟡 Средний | Скорость обучения |
| 06. Evolution search stability | ❌ Не выполнен | 🟡 Средний | Стабильность сходимости |
| 07. Opponent model v2 | ❌ Не выполнен | 🟡 Средний | Сила против соперников |
| 08. Experiment harness | ❌ Не выполнен | 🟢 Низкий | Automation workflow |

---

## Архитектурные риски

### Риск 1. Дублирование структуры модели в heredoc

**Где:** `scripts/train_bot_tuning.sh` (heredoc с main.swift)

**Риск:**
- При изменении `BotTuning` требуется править heredoc
- Разработчики **не знают** об этой зависимости
- Training pipeline **сломается** при следующем изменении модели

**Митигация:**
1. Вынести training runner в **checked-in Swift code**
2. Удалить heredoc полностью
3. Оставить в shell-скрипте только **оркестрацию**

---

### Риск 2. Genome не эволюционирует runtimePolicy

**Где:** `BotSelfPlayEvolutionEngine+Genome.swift`

**Риск:**
- ~50% коэффициентов бота **зафиксированы**
- Self-play не оптимизирует **ranking, rollout, endgame**
- Потолок эффективности **ниже возможного**

**Митигация:**
1. Расширить `EvolutionGenome` runtimePolicy scales
2. Обновить `applyingEvolutionScopeMask` для новых genes
3. Добавить bounds для новых параметров

---

### Риск 3. Fitness смешивает primary/guardrail метрики

**Где:** `BotSelfPlayEvolutionEngine+Fitness.swift`

**Риск:**
- Невозможно отладить причину деградации
- Guardrail-метрики **не влияют** на отбор
- Бот может **переобучиться** на primary fitness в ущерб guardrails

**Митигация:**
1. Разделить fitness на primary/guardrail слои
2. Добавить guardrail thresholds
3. Ввести penalty за нарушение thresholds

---

### Риск 4. Отсутствует diversity telemetry

**Где:** `BotSelfPlayEvolutionEngine+Evolution.swift`

**Риск:**
- Популяция **вырождается** к одному типу
- Алгоритм **застревает** в локальном оптимуме
- Нет механизма **восстановления**

**Митигация:**
1. Добавить diversity metrics в progress
2. Ввести adaptive mutation rate
3. Добавить random immigrants
4. Реализовать controlled restart

---

## Рекомендации по приоритизации

### 🔴 Блокирующие (выполнить до продолжения)

1. **Этап 01.3:** Вынести training runner в checked-in Swift code
   - Удалить heredoc из shell-скрипта
   - Создать `JockerSelfPlayTools/Sources/bot-training-runner/main.swift`
   
2. **Этап 01.4:** Добавить baseline-only режим
   - Добавить `baselineOnly: Bool` в `SelfPlayEvolutionConfig`
   - Реализовать отдельный путь `evaluateBaselineOnly`

3. **Этап 03.5:** Расширить Genome runtimePolicy scales
   - Добавить ranking/rollout/endgame/opponent genes
   - Обновить crossover/mutation для новых genes

### 🟡 Критичные (выполнить в следующей итерации)

4. **Этап 02.1:** Разделить fitness на primary/guardrail
   - Ввести `computePrimaryFitness()` и `computeGuardrailPenalty()`
   - Добавить guardrail thresholds

5. **Этап 05.4:** Реализовать параллелизацию
   - Использовать `withTaskGroup` для оценки кандидатов
   - Добавить `maxParallelEvaluations` в config

6. **Этап 06.1-06.4:** Добавить stability mechanisms
   - Diversity telemetry
   - Adaptive mutation
   - Random immigrants
   - Controlled restart

### 🟢 Улучшения (выполнить после стабилизации)

7. **Этап 04:** Фазовые multipliers
8. **Этап 07:** Opponent model v2
9. **Этап 08:** Machine-readable артефакты

---

## Конфликты между планами

### Конфликт 1. Этап 03 vs Этап 05

**Проблема:**
- Этап 03 требует изменения `EvolutionGenome`
- Этап 05 требует изменения `evaluateCandidate` для параллелизации
- Оба этапа меняют `BotSelfPlayEvolutionEngine+Evolution.swift`

**Решение:**
- Выполнить **Этап 03 первым** (расширение Genome)
- Затем выполнить **Этап 05** (параллелизация)
- Избежать merge conflicts

---

### Конфликт 2. Этап 02 vs Этап 06

**Проблема:**
- Этап 02 меняет fitness formula
- Этап 06 добавляет diversity metrics
- Оба влияют на selection logic

**Решение:**
- Выполнить **Этап 02 первым** (fitness разделение)
- Затем выполнить **Этап 06** (diversity telemetry)
- Diversity metrics должны использовать **новый fitness**

---

## Замечания к конкретным планам

### 01_TRAINING_PIPELINE_RECOVERY_PLAN

**Замечания:**
- ✅ План правильный, но **не выполнен**
- ⚠️ Шаг 3 (heredoc removal) — **критический долг**
- ⚠️ Шаг 4 (baseline-only) — влияет на baseline harness

**Рекомендация:**
- Пометить этап 01 как **BLOCKER** для всех остальных этапов
- Не продолжать этапы 02-08 до завершения этапа 01

---

### 02_FITNESS_GUARDRAILS_EXPANSION_PLAN

**Замечания:**
- ✅ Разделение fitness — правильное решение
- ⚠️ План не учитывает **обратную совместимость** с existing runs
- ⚠️ Нет плана миграции для **training scripts**

**Рекомендация:**
- Добавить **deprecated period** для старой fitness formula
- Добавить **comparison mode** (old vs new fitness)

---

### 03_RUNTIME_POLICY_EVOLUTION_SCOPE_PLAN

**Замечания:**
- ✅ Расширение Genome — необходимо
- ⚠️ План не учитывает **влияние на время обучения**
- ⚠️ Больше genes = **медленнее сходимость**

**Рекомендация:**
- Добавить **scope flags** для включения/выключения групп genes
- По умолчанию включать только **критические genes**

---

### 04_PHASE_CONDITIONED_POLICY_MULTIPLIERS_PLAN

**Замечания:**
- ✅ Фазовые multipliers — хорошее улучшение
- ⚠️ План требует изменения **множества сервисов**
- ⚠️ Риск **регрессии** поведения бота

**Рекомендация:**
- Добавить **neutral baseline test** (все multipliers = 1.0)
- Выполнять **regression tests** после каждого изменения

---

### 05_PARALLEL_CANDIDATE_EVALUATION_PLAN

**Замечания:**
- ✅ Параллелизация — необходимо для скорости
- ⚠️ План не учитывает **детерминизм**
- ⚠️ Structured concurrency может **сломать seed derivation**

**Рекомендация:**
- Добавить **deterministic seed derivation** тесты
- Использовать **локальные RNG** на каждый worker

---

### 06_EVOLUTION_SEARCH_STABILITY_PLAN

**Замечания:**
- ✅ Diversity telemetry — необходимо для стабильности
- ⚠️ План **не включает speciation** (отложено)
- ⚠️ Adaptive mutation может **дестабилизировать** сходимость

**Рекомендация:**
- Начать с **telemetry только** (без adaptive mutation)
- Добавить **stagnation detection** перед adaptive mutation

---

### 07_OPPONENT_MODEL_V2_PLAN

**Замечания:**
- ✅ Opponent model v2 — улучшение против сильных
- ⚠️ План требует **значительных изменений** в сервисах
- ⚠️ Риск **переобучения** на историю

**Рекомендация:**
- Добавить **confidence gating** (не доверять малой истории)
- Ввести **decay** для старых наблюдений

---

### 08_EXPERIMENT_HARNESS_AND_REPORTING_PLAN

**Замечания:**
- ✅ Machine-readable output — необходимо для automation
- ⚠️ План требует изменения **всех scripts**
- ⚠️ JSON schema должна быть **стабильной**

**Рекомендация:**
- Добавить **versioning** к JSON schema
- Использовать **Codable** для Swift-структур

---

## Итоговые рекомендации

### Немедленные действия (P0)

1. **Остановить этапы 02-08** до завершения этапа 01
2. **Вынести training runner** в checked-in Swift code
3. **Удалить heredoc** из shell-скрипта
4. **Добавить baseline-only** режим

### Краткосрочные действия (P1, 1-2 недели)

5. **Расширить Genome** runtimePolicy scales
6. **Разделить fitness** на primary/guardrail
7. **Добавить diversity telemetry**

### Среднесрочные действия (P2, 3-4 недели)

8. **Реализовать параллелизацию**
9. **Добавить adaptive mutation**
10. **Реализовать фазовые multipliers**

### Долгосрочные действия (P3, 5-8 недель)

11. **Opponent model v2**
12. **Machine-readable артефакты**
13. **CI/CD интеграция**

---

## Заключение

Планы составлены **грамотно и детально**, но **не синхронизированы** с текущей реализацией. Критическое расхождение — **heredoc в training pipeline** — создаёт риск поломки при следующем изменении модели.

**Рекомендуемый порядок:**
1. ✅ Завершить этап 01 (training pipeline recovery)
2. ✅ Выполнить этап 03 (runtimePolicy genome scope)
3. ✅ Выполнить этап 02 (fitness guardrails)
4. ✅ Выполнить этап 05 (parallel evaluation)
5. ✅ Выполнить этап 06 (stability mechanisms)
6. ⏸️ Остальные этапы — по приоритету

**Общее время реализации:** 6-8 недель при полном выполнении всех этапов.
