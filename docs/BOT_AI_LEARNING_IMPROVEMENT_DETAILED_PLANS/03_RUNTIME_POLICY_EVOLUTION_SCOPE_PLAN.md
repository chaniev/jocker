# Детальный план 03. Расширение пространства эволюции на `runtimePolicy`

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.3 / приоритет P1  
**Порядок выполнения:** 3  
**Предусловия:** завершены этапы 01 и 02

## Цель

Расширить genome self-play так, чтобы он тюнинговал основные runtime policy-кластеры бота через ограниченный набор групповых multipliers, а не только текущий узкий subset `turnStrategy`/`bidding`/`trumpSelection`.

## Шаги выполнения

### 1. Канонизировать `BotRuntimePolicy`

1. Добавить unit tests на все difficulty presets `BotRuntimePolicy`.
2. Разделить preset-код `BotRuntimePolicy` по секциям:
   - `BotRuntimePolicy+RankingPreset.swift`
   - `BotRuntimePolicy+BiddingPreset.swift`
   - `BotRuntimePolicy+EvaluatorPreset.swift`
   - `BotRuntimePolicy+RolloutPreset.swift`
   - `BotRuntimePolicy+HeuristicsPreset.swift`
   - `BotRuntimePolicy+OpponentModelingPreset.swift`
3. Оставить в `BotRuntimePolicy.swift` только типы, `preset(for:)` и patch-функции difficulty.
4. Перевести `BotRuntimePolicy.Bidding` на каноническое хранение nested policy-структур:
   - `bidSelection`
   - `blindPolicy`
   - `blindMonteCarlo`
5. Удалить из `Bidding` все projection-методы и дублирующие scalar-поля.
6. Переписать difficulty presets как patch-функции поверх `hard` baseline.

### 2. Канонизировать `BotTuning`

1. Добавить unit tests на difficulty presets `BotTuning`.
2. Перенести joker-policy на уровень `BotTuning.TurnStrategy`.
3. Удалить верхнеуровневый computed property для joker-policy.
4. Собрать `BotTuning` через `hard` baseline и patch-функции для `normal` и `easy`.
5. Вынести общие builders для `TurnStrategy`, `Bidding`, `TrumpSelection` и `Timing`.
6. Оставить внешний API `BotTuning(difficulty:)` без изменения сигнатуры.

### 3. Синхронизировать training tooling с канонической моделью

1. Обновить training runner так, чтобы он читал только канонические поля `BotRuntimePolicy` и `BotTuning`.
2. Удалить из training code ручное конструирование старой формы `Bidding`.
3. Удалить из training code доступ к верхнеуровневой joker-policy.
4. Переписать агрегацию tuning values на секционные builders и patch-функции.

### 4. Ввести отдельный слой `RuntimePolicyEvolutionPatch`

1. Создать структуру `RuntimePolicyEvolutionPatch`.
2. Сделать её единственной точкой применения genome к `BotRuntimePolicy`.
3. Наложение patch выполнять поверх канонического preset, а не через сборку policy с нуля.
4. Применение patch ограничить только секциями, открытыми для обучения.

### 5. Расширить `EvolutionGenome`

1. Добавить в `EvolutionGenome` следующие genes:
   - `rankingMatchCatchUpScale`
   - `rankingPremiumScale`
   - `rankingPenaltyAvoidScale`
   - `jokerDeclarationScale`
   - `rolloutActivationScale`
   - `rolloutAdjustmentScale`
   - `endgameActivationScale`
   - `endgameAdjustmentScale`
   - `opponentPressureScale`
2. Для каждого gene задать:
   - нейтральное значение `1.0`;
   - минимальную границу;
   - максимальную границу;
   - mutation delta.
3. Обновить crossover и mutation так, чтобы значения не выходили за bounds.

### 6. Ввести scope flags для runtimePolicy-групп

1. Добавить в public config отдельные флаги:
   - `tuneRankingPolicy`
   - `tuneRolloutPolicy`
   - `tuneEndgamePolicy`
   - `tuneOpponentModelingPolicy`
   - `tuneJokerDeclarationPolicy`
2. Обновить `applyingEvolutionScopeMask`, чтобы он маскировал genes по этим флагам.
3. В canonical training profile включить по умолчанию только:
   - `tuneRankingPolicy`
   - `tuneRolloutPolicy`
   - `tuneOpponentModelingPolicy`
4. Оставить `tuneEndgamePolicy` и `tuneJokerDeclarationPolicy` выключенными до завершения первой holdout-валидации.

### 7. Зафиксировать identity semantics

1. Оставить `EvolutionGenome.identity` полностью нейтральным.
2. Добавить тест, что `identity` не меняет `BotRuntimePolicy`.
3. Добавить тест, что мутация одного gene меняет только одну policy-группу.
4. Добавить тест, что секции вне scope остаются неизменными.

### 8. Обновить артефакты training run

1. Выводить в summary значения всех новых genes.
2. Выводить diff относительно baseline preset.
3. Выводить секционный breakdown применённого runtime-policy patch.
4. Сохранять эти значения в machine-readable артефактах training run.

### 9. Провести валидацию нового genome scope

1. Прогнать old genome scope на canonical profile.
2. Прогнать runtimePolicy scope только с критическими группами:
   - ranking
   - rollout
   - opponent modeling
3. Сравнить результаты на training seeds.
4. Сравнить результаты на holdout seeds.
5. После успешной holdout-проверки включить `endgame` и `jokerDeclaration` группы.
6. Повторить training и holdout сравнение для полного scope.
7. Зафиксировать итоговый effect size в summary.

## Проверки

1. Unit tests на presets `BotRuntimePolicy` и `BotTuning` проходят.
2. Identity genome не меняет baseline policy.
3. Mutation и crossover соблюдают bounds.
4. Scope flags корректно маскируют genes по policy-группам.
5. Training runner печатает и сериализует новые runtime genes.
6. Expanded genome scope проходит holdout-проверку.

## Критерии завершения

1. `BotRuntimePolicy` и `BotTuning` имеют каноническую внутреннюю форму без дублирующих проекций.
2. Training tooling синхронизирован с этой формой.
3. `EvolutionGenome` управляет как минимум девятью runtime policy-кластерами.
4. Scope flags позволяют включать runtime policy-группы поэтапно.
5. Patch применяется поверх baseline preset и не пересобирает policy вручную.
6. Новый genome scope даёт измеримый эффект на holdout.
