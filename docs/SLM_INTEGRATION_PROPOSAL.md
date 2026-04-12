# Интеграция локальных SLM (Small Language Models) для улучшения бота

## 📊 Текущее состояние бота

### Что имеем сейчас:
- **Эвристическая система** с ~300+ настраиваемыми коэффициентами
- **Monte Carlo rollout** для критических ситуаций
- **Endgame solver** для точной игры при малом количестве карт
- **Self-play эволюция** (генетический алгоритм) для оптимизации ~40 параметров
- **Opponent modeling** (MVP) — трекинг паттернов соперников
- **Phase-aware logic** — учет фазы игры

### Проблемы текущей системы:
1. **Жесткие формулы** — бот не может обобщать опыт за пределы закодированных эвристик
2. **Ограниченный геном** — эволюция тюнит только ~40 из 300+ параметров
3. **Нет истинного обучения** — нет нейросетевой модели, которая могла бы учиться на паттернах
4. **Потолок качества** — похоже, мы уперлись в ceiling эвристического подхода

---

## 🎯 Возможности iOS SLM/LLM

### Доступные технологии (2025-2026):

| Технология | Требования | Описание |
|------------|-----------|----------|
| **Foundation Models Framework** | iOS 26+ | Встроенная модель Apple (3B параметров, 2-bit quantized, ~750MB) |
| **Core ML + конвертированные SLM** | iOS 17+ | Кастомные модели через Core ML (Gemma-2B, Phi-3-mini, Qwen-1.8B) |
| **MLX Framework** | iOS 18+ | Запуск квантизованных LLM на Apple Silicon |

### Рекомендуемые SLM модели для iOS:

| Модель | Размер | Квантование | RAM | Скорость (iPhone) | Подходит для |
|--------|--------|------------|-----|-------------------|--------------|
| **Gemma-2-2B** | 2B | 4-bit | ~1.5GB | 15-25 tok/s | ✅ Стратегия, анализ |
| **Phi-3-mini** | 3.8B | 4-bit | ~2.5GB | 10-15 tok/s | ✅ Рассуждения |
| **Qwen-1.5B** | 1.5B | 4-bit | ~1GB | 20-30 tok/s | ✅ Быстрые решения |
| **SmolLM-135M** | 135M | 8-bit | ~200MB | 150+ tok/s | ✅ Простая классификация |
| **Apple Foundation Model** | 3B | 2-bit | ~1.2GB | 10-30 tok/s | ✅ Универсальная |

---

## 🚀 Стратегии интеграции SLM в бота

### Стратегия 1: **SLM как Advisor** (Рекомендательная система)

**Концепция:** SLM не принимает решения напрямую, а оценивает позицию и даёт рекомендации текущей эвристической системе.

**Архитектура:**
```
Текущая ситуация в игре
         ↓
   [SLM Analyzer] → Оценка позиции (текст/структура)
         ↓
   [SLM suggests]: 
   - лучшая карта
   - уровень уверенности (0-1)
   - краткое объяснение почему
         ↓
   [Hybrid Evaluator]:
   - heuristic utility (70%)
   - SLM suggestion (30%)
         ↓
   Финальное решение бота
```

**Плюсы:**
- ✅ Безопасно — эвристика всегда fallback
- ✅ Можно постепенно увеличивать вес SLM
- ✅ SLM можно обучать/файнтюнить на self-play данных
- ✅ Работает даже если SLM ошибается
- ✅ Не требует больших изменений архитектуры

**Минусы:**
- ⚠️ SLM только советует, не учится на ходу
- ⚠️ Latency: 100-300ms на запрос (нужен caching)
- ⚠️ RAM usage: 1-2GB (проблема на старых iPhone)

**Реализация:**
```swift
protocol SLMAdvisor {
    func analyzePosition(_ context: BotTurnContext) async -> SLMRecommendation
}

struct SLMRecommendation {
    let suggestedCard: Card
    let confidence: Float  // 0.0 - 1.0
    let reasoning: String? // для дебага
    let alternativeCards: [(Card, confidence: Float)]
}

// В BotTurnCandidateEvaluatorService:
func bestMove(context: BotTurnContext) async -> Card {
    let heuristicBest = evaluateCandidatesHeuristic(context)
    
    // Асинхронный запрос к SLM
    let slmRec = await slmAdvisor.analyzePosition(context)
    
    // Hybrid scoring
    let finalScore = hybridScore(
        heuristic: heuristicBest.utility,
        slm: slmRec.confidence,
        slmWeight: dynamicSLMWeight(context) // 0.2-0.5
    )
    
    return finalScore.bestCard
}
```

**Сложность:** ⭐⭐⭐ (средняя)
**Время реализации:** 2-3 недели
**Ожидаемый прирост качества:** +5-10% win rate

---

### Стратегия 2: **SLM как Policy Network** (Прямое управление)

**Концепция:** SLM напрямую выбирает действия, обученная на self-play данных через imitation learning.

**Архитектура:**
```
Состояние игры (структурированное)
         ↓
   [Prompt Template] → текст/JSON
         ↓
   [SLM Inference] → выбранная карта
         ↓
   [Validation Layer] → проверка легальности
         ↓
   Ход бота
```

**Плюсы:**
- ✅ Потенциально более сильная игра
- ✅ Истинное ML-моделирование
- ✅ Может находить неочевидные стратегии

**Минусы:**
- ❌ Сложная валидация (SLM может предложить нелегальный ход)
- ❌ Высокий latency (не приемлемо для реального времени)
- ❌ Большой RAM footprint
- ❌ Сложно дебажить и объяснять решения
- ❌ Требует файнтюна на доменных данных

**Вердикт:** ❌ Не рекомендуется для production (слишком рискованно)

---

### Стратегия 3: **SLM для Self-Play Evolution** (Обучение оффлайн)

**Концепция:** Использовать SLM для генерации лучших training данных и фич для генетической эволюции.

**Архитектура:**
```
[Self-Play Games] → сбор позиций и решений
         ↓
   [SLM Analyzer] → для каждой позиции:
   - оценка качества хода
   - выявление паттернов
   - предложение новых фич
         ↓
   [Feature Generator]:
   - создание новых эвристических признаков
   - предложение новых коэффициентов
         ↓
   [Evolution Engine] → эволюция на расширенном пространстве
```

**Примеры новых фич от SLM:**
```
SLM анализирует 1000 проигранных позиций и находит:
"Бот недооценивает контроль мастей в средней фазе, 
когда у него нет джокера и bid = 3"

→ Предлагает новую фичу: `suitControlPressure`
→ Эволюция находит оптимальные веса для этой фичи
```

**Плюсы:**
- ✅ Не влияет на runtime производительность
- ✅ Улучшает эвристическую систему косвенно
- ✅ SLM работает в своём сильном аспекте (анализ паттернов)
- ✅ Можно запускать оффлайн (не в игре)
- ✅ Генерирует interpretable insights

**Минусы:**
- ⚠️ Требует создания infrastructure для анализа
- ⚠️ SLM может предлагать бесполезные фичи (нужен filtering)

**Реализация:**
```swift
// В CLI training tool (JockerSelfPlayTools):
struct SLMPatternAnalyzer {
    func analyzeLostDecks(_ games: [GameRecord]) async -> [PatternInsight] {
        // Группируем проигранные позиции
        // SLM находит общие паттерны
        // Предлагает новые фичи/adjustments
    }
}

struct PatternInsight {
    let description: String
    let suggestedFeature: String
    let estimatedImpact: Float
    let examplePositions: [GameState]
}
```

**Сложность:** ⭐⭐⭐⭐ (высокая)
**Время реализации:** 4-6 недель
**Ожидаемый прирост качества:** +10-15% win rate

---

### Стратегия 4: **Гибридная система** (Рекомендуемая)

**Концепция:** Комбинация Стратегии 1 и 3 с постепенным переходом к большему весу SLM.

**Фаза 1: SLM Advisor + Enhanced Self-Play** (1-2 месяца)
- Внедрить SLM advisor в runtime (Стратегия 1)
- Использовать SLM для анализа self-play данных (Стратегия 3)
- SLM weight = 0.2-0.3 (консервативно)

**Фаза 2: SLM Feature Discovery** (2-3 месяца)
- SLM генерирует новые эвристические фичи
- Эволюция находит оптимальные веса
- SLM weight = 0.3-0.4

**Фаза 3: SLM Policy Distillation** (3-4 месяца)
- SLM обучается через imitation learning на лучших self-play games
- Знания SLM дистиллируются в эвристики (policy distillation)
- SLM weight = 0.4-0.5 (если производительность позволяет)

---

## 🏗️ Техническая реализация

### Вариант A: Foundation Models Framework (iOS 26+)

**Плюсы:**
- ✅ Простейшая интеграция (3 строки кода)
- ✅ Официальная поддержка Apple
- ✅ Автоматические обновления модели

**Минусы:**
- ❌ Только iOS 26+ (исключает iPhone 15 и старше)
- ❌ Фиксированная модель (нельзя файнтюнить)
- ❌ 4096 token context limit
- ❌ 1.0-1.5GB RAM всегда
- ❌ Запрещён параллелизм

**Код:**
```swift
import FoundationModels

struct AppleSLMAdvisor: SLMAdvisor {
    private let session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession()
    }
    
    func analyzePosition(_ context: BotTurnContext) async -> SLMRecommendation {
        let prompt = buildPrompt(from: context)
        
        do {
            // Structured output через @Generable
            let response = try await session.respond(
                to: prompt,
                generating: SLMRecommendation.self
            )
            return response
        } catch {
            // Fallback на эвристику
            return heuristicFallback(context)
        }
    }
}

@Generable
struct SLMRecommendation: Codable {
    var suggestedCardRank: Int
    var suggestedCardSuit: Int
    var confidence: Float
    var reasoning: String
}
```

### Вариант B: Core ML + кастомная SLM (iOS 17+)

**Плюсы:**
- ✅ Работает на iOS 17+ (охватывает больше устройств)
- ✅ Можно файнтюнить модель
- ✅ Контроль над размером/квантованием
- ✅ Можно выбрать модель под задачу

**Минусы:**
- ❌ Сложнее интеграция (конвертация модели)
- ❌ Нужно управлять жизненным циклом модели
- ❌ Файл модели в бандле (~1-2GB) или загрузка

**Модели для конвертации:**
```bash
# Конвертация Gemma-2B в Core ML
pip install coremltools transformers
python convert_to_coreml.py \
    --model google/gemma-2-2b \
    --quantization 4-bit \
    --output Gemma2B_CoreML.mlpackage
```

**Код:**
```swift
import CoreML

struct CoreMLSLMAdvisor: SLMAdvisor {
    private let model: Gemma2B_CoreML
    
    func analyzePosition(_ context: BotTurnContext) async -> SLMRecommendation {
        let input = encodeContext(context)
        
        let output = try await model.prediction(
            input: input,
            configuration: MLModelConfiguration()
        )
        
        return decodeRecommendation(output)
    }
}
```

### Вариант C: MLX + кастомная SLM (iOS 18+)

**Плюсы:**
- ✅ Самая высокая производительность на Apple Silicon
- ✅ Поддержка разных моделей из коробки
- ✅ Активное комьюнити

**Минусы:**
- ❌ iOS 18+ только
- ❌ Swift обёртки ещё незрелые
- ❌ Требует MLX expertise

---

## 📋 Рекомендации

### Что я рекомендую (приоритизация):

#### 🔴 КРИТИЧНО — Начать с этого:

**1. Инфраструктура для SLM (неделя 1-2)**
- [ ] Добавить feature flag: `enableSLMAdvisor: Bool` в `BotTuning`
- [ ] Создать протокол `SLMAdvisor` с mock-реализацией
- [ ] Добавить метрики: `slmLatency`, `slmAccuracy`, `slmAgreementRate`
- [ ] Создать benchmark для измерения влияния SLM

**2. Выбрать технологию (неделя 2)**
- [ ] Протестировать Foundation Models (если таргет iOS 26+)
- [ ] ИЛИ конвертировать Gemma-2B/Qwen-1.5B в Core ML
- [ ] Benchmark на реальных устройствах (iPhone 15, 16, 17)
- [ ] Измерить latency, RAM usage, точность

**3. SLM Advisor MVP (неделя 3-4)**
- [ ] Реализовать `buildPrompt()` из `BotTurnContext`
- [ ] Реализовать парсинг ответа SLM
- [ ] Интегрировать в `BotTurnCandidateEvaluatorService`
- [ ] Начать с SLM weight = 0.2
- [ ] A/B тестирование против baseline

#### 🟡 ВАЖНО — После MVP:

**4. SLM для Self-Play Analysis (неделя 5-8)**
- [ ] Создать `SLMPatternAnalyzer` для CLI tools
- [ ] Анализировать проигранные позиции
- [ ] Генерировать hypotheses для новых фич
- [ ] Интегрировать в evolution pipeline

**5. Progressive Enhancement (месяц 2-3)**
- [ ] Увеличивать SLM weight (0.2 → 0.3 → 0.4)
- [ ] Monitor regression tests
- [ ] Adaptive SLM weight по сложности ситуации

#### 🟢 ОПЦИОНАЛЬНО — Долгосрочно:

**6. SLM Policy Distillation (месяц 3-4)**
- [ ] Imitation learning на self-play данных
- [ ] Distill SLM knowledge в эвристики
- [ ] Создать hybrid policy network

---

## ⚠️ Риски и ограничения

### Технические риски:

| Риск | Вероятность | Влияние | Митигация |
|------|------------|---------|-----------|
| Высокий latency (>500ms) | 🔴 Высокая | Бот тормит | Caching, async preloading |
| RAM > 2GB на iPhone | 🟡 Средняя | Crash на 4GB iPhone | Model quantization, fallback |
| SLM даёт плохие рекомендации | 🟡 Средняя | Качество падает | Low SLM weight, validation |
| iOS version fragmentation | 🔴 Высокая | Не работает на старых | Feature flag, graceful degradation |
| Apple меняет API | 🟡 Средняя | Breaking changes | Abstraction layer |

### Продуктовые риски:

| Риск | Вероятность | Влияние | Митигация |
|------|------------|---------|-----------|
| Увеличение размера приложения | 🔴 Высокая | Пользователи не скачают | Download модели по запросу |
| Батарея садится быстрее | 🟡 Средняя | UX ухудшается | Отключать на low battery |
| SLM не улучшает игру | 🟡 Средняя | Потрачено время | A/B тесты, rollback plan |

---

## 📊 Ожидаемые метрики

### До интеграции (baseline):
- Win rate: ~55-60% (против random)
- Score diff: +2-3 очка/игра
- Latency: <50ms (pure heuristic)
- RAM: <50MB

### После интеграции (цель):
- Win rate: **65-70%** (+10%)
- Score diff: **+5-7 очков/игра** (+100%)
- Latency: **100-300ms** (приемлемо для AI хода)
- RAM: **+1-2GB** (только когда SLM активен)

---

## 🎓 Примеры промптов для SLM

### Prompt для выбора карты:

```
Ты играешь в карточную игру "Джокер". Выбери лучшую карту для хода.

ТВОЯ РУКА: [♠A, ♠K, ♥7, ♦Q, ♣3]
КОЗЫРЬ: ♠
ТВОЙ BID: 3 взятки
ТЕКУЩИЙ СЧЁТ: 2-1 (ты лидируешь)
КАРТЫ НА СТОЛЕ: [♥A (противник 1), ♥K (противник 2)]
ОБЯЗАН СЛЕДОВАТЬ МАСТИ: ♥

КОНТЕКСТ БЛОКА:
- Блок 3 из 6
- Твоя премия: на кону (нужно точно 3 взятки)
- Противник слева: агрессивный (80% overbid)
- Фаза: средняя (3/6 карт осталось)

Выбери карту и объясни почему.
Формат: {"card": "♥7", "confidence": 0.85, "reasoning": "..."}
```

### Prompt для анализа позиции (self-play):

```
Проанализируй эту проигранную позицию из 1000 сыгранных игр.
Бот проиграл несмотря на сильную руку. Найди паттерны.

ПОЗИЦИЯ:
- Бот заказал 4, взял только 2
- В руке были: [♠A, ♠K, ♠Q, ♥A]
- Кошмарный розыгрыш: потратил джокера рано

ЧТО БОТ СДЕЛАЛ НЕПРАВИЛЬНО?
Какие фичи нужно добавить в оценку?
Формат: {"mistake_type": "...", "suggested_feature": "...", "impact": "high"}
```

---

## 🔬 Альтернативные подходы

Если SLM окажется слишком сложным, рассмотрим:

### A. Tiny Neural Network (Core ML)
- Маленькая нейронка (10-50KB) для scoring кандидатов
- Обучается на self-play данных
- Работает мгновенно, минимальный RAM
- **Но:** требует feature engineering

### B. Gradient Boosting (XGBoost → Core ML)
- Классический ML для предсказания win probability
- Очень быстрый, очень маленький
- **Но:** не capture сложные паттерны

### C. Lookup Tables + Interpolation
- Pre-computed best moves для типовых позиций
- Interpolation для unseen позиций
- **Но:** экспоненциальный рост таблицы

---

## 📅 Roadmap

### Q2 2026 (Апрель-Июнь):
- [ ] Research & prototyping (Стратегия 1)
- [ ] Foundation Models тестирование
- [ ] SLM Advisor MVP
- [ ] Initial A/B тесты

### Q3 2026 (Июль-Сентябрь):
- [ ] SLM Self-Play Analysis (Стратегия 3)
- [ ] Feature discovery pipeline
- [ ] Enhanced evolution с SLM фичами
- [ ] Benchmark на разных устройствах

### Q4 2026 (Октябрь-Декабрь):
- [ ] Progressive enhancement
- [ ] Policy distillation research
- [ ] Production deployment (если метрики хорошие)
- [ ] User feedback сбор

---

## 🎯 Заключение

**Рекомендация:** Начать с **Стратегии 4 (Гибридной)**, Фаза 1.

**Почему:**
1. ✅低风险 — эвристика всегда fallback
2. ✅ Измеримо — можно точно оценить impact
3. ✅ Постепенно — увеличиваем SLM weight по мере доверия
4. ✅ Гибко — можно отключить SLM для старых iOS
5. ✅ Будущее-proof — готовит базу для более глубокой интеграции

**Первые шаги:**
1. Создать `SLMAdvisor` протокол
2. Протестировать Foundation Models на iPhone с iOS 26
3. Собрать baseline latency/RAM метрики
4. Реализовать MVP интеграцию
5. A/B тест против current hard бота

**Ожидаемый результат:** +5-10% win rate в первые 2 месяца, +10-15% через 6 месяцев.

---

## 📚 Ссылки и ресурсы

### Apple документация:
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels)
- [WWDC 2025: Meet Foundation Models](https://developer.apple.com/videos/play/wwdc2025/286)
- [Core ML Tools](https://coremltools.readme.io/)

### Модели:
- [Gemma-2 (Google)](https://huggingface.co/google/gemma-2-2b)
- [Phi-3 (Microsoft)](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct)
- [Qwen-1.5](https://huggingface.co/Qwen/Qwen-1.5-1.8B)
- [MLX-quantized models для iOS](https://huggingface.co/collections/Susant-Achary/mlx-quantized-models-3-4-5-6-bit-mac-and-ios)

### Инструменты:
- [MLX Framework (Apple)](https://github.com/ml-explore/mlx)
- [Core ML Tools](https://github.com/apple/coremltools)
- [LLM on iPhone examples](https://github.com/ml-explore/mlx-examples)
