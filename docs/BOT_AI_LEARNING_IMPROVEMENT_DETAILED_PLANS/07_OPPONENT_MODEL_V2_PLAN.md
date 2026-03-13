# Детальный план 07. Opponent model v2 поверх существующего MVP

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.7 / приоритет P2  
**Порядок выполнения:** 7  
**Предусловия:** завершены этапы 01, 03 и 04  
**Статус:** не начат в целевом виде  
**Статус gate:** существует только MVP foundation уровня 6a/6b; v2 model, match-level memory, confidence/decay и обучение новых сигналов не реализованы

## Цель

Расширить opponent model до версии 2, добавив match-level память, confidence-gating и отдельные сигналы для joker/premium-стиля соперников, и встроить эти сигналы в каноническую opponent-modeling policy.

## Статус на 2026-03-13

- `BotOpponentModel` по-прежнему хранит только block-level `snapshots` с простыми rate-метриками (`blindBidRate`, `exactBidRate`, `overbidRate`, `underbidRate`, `averageBidAggression`).
- `BotMatchContextBuilder` собирает наблюдения только из текущего блока; match-level память, decay и отдельные joker/premium-style сигналы отсутствуют.
- `OpponentPressureAdjuster` работает на MVP-style signal без confidence-gating, volatility damping и memory weights.
- `scripts/run_stage6b_ranking_guardrails.sh` уже страхует текущий MVP/no-evidence path, но это ещё не реализация opponent model v2 из данного плана.

## Шаги выполнения

### 1. Расширить модель наблюдений

1. В `BotOpponentModel.swift` разделить наблюдения на:
   - `currentBlockObservations`
   - `currentMatchObservations`
2. Добавить в модель следующие сигналы:
   - joker usage style;
   - premium deny tendency;
   - premium save tendency;
   - aggression score;
   - volatility score;
   - confidence score.
3. Для каждого сигнала задать нейтральное состояние по умолчанию.
4. Добавить unit tests на нейтральное состояние новой модели.

### 2. Расширить сбор наблюдений

1. В `BotMatchContextBuilder.swift` собирать block-level и match-level наблюдения отдельно.
2. Накопление match-level наблюдений вести в рамках одного матча.
3. Block-level наблюдения делать приоритетными над match-level при достаточном количестве данных.
4. Ввести decay для match-level наблюдений, чтобы старые события влияли слабее новых.
5. Обновить источники истории и runtime context так, чтобы builder получал все новые сигналы.

### 3. Канонизировать opponent-modeling policy

1. В секции `opponentModeling` добавить явные поля для:
   - confidence thresholds;
   - memory weights;
   - observation decay;
   - joker-style pressure;
   - premium-style pressure;
   - volatility damping.
2. Подключить эти поля к `hard` baseline.
3. Подключить difficulty patch-функции к новым полям.
4. Оставить все thresholds и weights внутри одной policy-секции.

### 4. Подключить v2-сигналы к `OpponentPressureAdjuster`

1. Применять joker-style pressure только при confidence выше порога.
2. Применять premium deny/save pressure только при confidence выше порога.
3. Ослаблять pressure для high-volatility opponents.
4. Применять decay к match-level наблюдениям перед расчётом давления.
5. Сохранять нейтральное поведение при отсутствии достаточных наблюдений.
6. Добавить service-level tests на каждую ветку применения.

### 5. Добавить scenario-based validation для opponent archetypes

1. Сформировать отдельные scenario families для:
   - агрессивного соперника;
   - хаотичного соперника;
   - premium-deny соперника;
   - premium-save соперника;
   - joker-heavy соперника.
2. Прогнать baseline и model v2 на каждом archetype.
3. Зафиксировать изменения в blind/joker/premium-related метриках.
4. Зафиксировать holdout-эффект по archetype families.

### 6. Раскрыть opponent model v2 для обучения

1. Добавить в genome или patch-config коэффициенты для:
   - confidence thresholds;
   - memory weights;
   - observation decay;
   - opponent pressure scales.
2. Ограничить эти параметры bounds-механизмами этапа 03.
3. Подключить эти параметры к machine-readable summary.
4. Провести отдельный A/B compare baseline vs opponent-model-v2.

## Проверки

1. `BotOpponentModel` имеет нейтральное состояние по умолчанию.
2. Block-level и match-level сигналы собираются и используются раздельно.
3. Decay применяется к match-level наблюдениям.
4. `OpponentPressureAdjuster` применяет давление только при достаточной confidence.
5. Scenario-based validation показывает эффект на archetype families.
6. Новые policy-параметры сериализуются и видны в training summary.

## Критерии завершения

1. Opponent model хранит block-level и match-level память.
2. В model v2 есть confidence, aggression, volatility, joker-style и premium-style сигналы.
3. Match-level память использует decay и не доминирует над свежими наблюдениями.
4. Все новые thresholds и weights живут в одной opponent-modeling policy-секции.
5. No-evidence path остаётся нейтральным.
6. Model v2 проходит archetype-based holdout validation.
