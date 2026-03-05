# Полный план покрытия тестами (весь проект)

**Дата:** 2026-03-05  
**Статус:** Актуализированный рабочий план  
**Версия:** 1.1

---

## Актуализация плана (2026-03-05)

### Оценка полноты текущего плана

Итоговая оценка полноты: **7/10**.

Что уже хорошо:
- покрыты основные области runtime AI, модели, flow, UI-логика и интеграционные тесты;
- есть фазирование, приоритизация и критерии завершения;
- учтены regression-гейты (`joker-pack`, `stage6b-pack-all`).

Что было неполным/устаревшим и требует корректировки:
- структура AI слоя устарела: фактически в `Game/Services/AI` уже **22** файла, включая `BotHandStrengthModel.swift` и константные split-файлы;
- не отражены границы таргетов `Jocker` vs `JockerSelfPlayTools` для self-play тестов;
- команды в Приложении A частично не существуют (`make test-all`, `make bot-tests`, `make flow-tests`, `make models-tests`, `make coverage`);
- не зафиксирован операционный протокол запуска на concrete simulator destination (в окружении наблюдались падения `CoreSimulatorService` на generic destination);
- не учтены новые покрытые области (например, `BotHandStrengthModelTests.swift`, расширенные `BotBiddingServiceTests.swift`, `BotTrumpSelectionServiceTests.swift`, `BotTurnCardHeuristicsServiceTests.swift`, `BotTurnRoundProjectionServiceTests.swift`);
- в матрице отсутствует политика исключений для low-value файлов (константы/тонкие обёртки), из-за чего «общее покрытие 80%» выглядит нереалистично и не risk-based.

### Фактическая структура (кратко, для калибровки плана)

- `Game/Services/AI`: 22 файла.
- `Game/Services/Flow`: 3 файла.
- `Game/Scenes`: 10 файлов.
- `ViewControllers`: 27 файлов.
- `Game/Nodes`: 8 файлов.
- `Models`: 35 файлов.
- Тестовые файлы `*Tests.swift` в `JockerTests`: 39 файлов.

### Политика покрытия (добавлено)

Чтобы план был достижимым и полезным для качества:
- покрытие измеряем прежде всего по **logic-heavy слоям**: Runtime AI, Rules, Scoring, Flow, Results resolvers/builders;
- для UI/SpriteKit файлов основная цель: unit на pure-логику + ограниченный integration/smoke, без искусственного доведения строкового покрытия;
- для констант/тонких wiring-файлов допускаем **coverage-by-integration** вместо прямых unit-тестов.

Категории с прямым unit-покрытием как обязательные:
- `Bot*Service`, `Bot*Model` (кроме pure constants);
- `Rules`, `Scoring`, `GameState`/core gameplay модели;
- `ScoreTable*Resolver/Builder/Provider`;
- `GameTurnService`, `GameRoundService`, `GameSceneCoordinator`.

Категории с coverage-by-integration:
- `Bot*Constants.swift`, `Bot*MatchContextConstants.swift`, `Bot*HeuristicsConstants.swift`, `Bot*RankingConstants.swift`;
- `AppDelegate.swift`, `GameColors.swift`;
- SpriteKit visual components без собственной бизнес-логики.

### Обновлённый P0/P1 backlog (приоритет для закрытия пробелов)

Уже закрыто в текущем состоянии:
- [x] `BotHandStrengthModelTests.swift`
- [x] расширение `BotBiddingServiceTests.swift` (forbidden-aware + blind Monte-Carlo invariants)
- [x] расширение `BotTrumpSelectionServiceTests.swift` (multi-factor + weak-hand no-trump guard)
- [x] расширение `BotTurnCardHeuristicsServiceTests.swift` (phase/position/history threat context)
- [x] расширение `BotTurnRoundProjectionServiceTests.swift` (consistency с unified hand strength)
- [x] строгие regression-наборы по stage6b/joker (через targeted strict tests)

#### P0 (обязательное закрытие)
- [x] `HandFeatureExtractorTests.swift` (новый файл): базовые/граничные кейсы, longest suit, high-card count, jokers.
- [x] `BotMatchContextBuilderTests.swift` (новый файл): premium/penalty snapshot, opponent model snapshot, no-evidence neutrality.
- [ ] `GameRoundServiceTests.swift` (новый файл): completeRound, block finalization invariants, score/premium side-effects.
- [ ] `UserDefaultsGameStatisticsStoreTests.swift` (новый файл): persist/load, aggregation per scope.
- [ ] `TrickNodeTests.swift` (новый файл): legality, lead suit/trump/joker constraints.

#### P1 (высокий приоритет)
- [x] `BotOpponentModelTests.swift` (новый файл): hasEvidence, snapshot lookups, bounds.
- [ ] `BotMatchContext.swift` model tests (new/extend): consistency invariants.
- [ ] `TrumpSelectionRulesTests.swift` (новый файл): chooser seat, staged-deal mode.
- [ ] `DealHistory*` model tests (группа): codable/hashable/equality invariants.
- [ ] `ScoreTableGridRendererTests.swift` (новый файл): grid generation layout invariants.
- [ ] `ScoreTableLabelManagerTests.swift` (новый файл): label lifecycle/update invariants.

### Регрессионный протокол (добавлено)

Минимальный gate после каждой пачки тестов:
1. `xcodebuild -quiet -project Jocker/Jocker.xcodeproj -scheme Jocker -destination 'generic/platform=iOS Simulator' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build-for-testing`
2. `make stage6b-pack-all` (или manual strict set на конкретный simulator id при проблемах CoreSimulatorService)
3. `make joker-pack` (или manual strict set на конкретный simulator id при проблемах CoreSimulatorService)

Self-play gate для AI-изменений:
1. `./scripts/run_bot_ab_comparison_snapshot.sh --profile compare-v1 -- --tuning-scope all --early-stop-patience 4 --early-stop-min-improvement 0.010 --early-stop-warmup-generations 4`
2. `make bt-hard-final-esab`
3. `make bot-compare`

Acceptance для promotion tuned preset:
- holdout `fitness_Badv > 0`,
- holdout `winRate_Badv > 0`,
- holdout `scoreDiff_Badv > 0`,
- `joker-pack` + `stage6b-pack-all` green.

---

## 📊 Общая статистика проекта (исторический baseline)

Ниже сохранён исходный baseline-срез от 2026-02-26 как reference.
Для оперативного планирования использовать секцию «Актуализация плана (2026-03-05)».

### Структура проекта

```
Jocker/
├── App/                          # AppDelegate, SceneDelegate
├── Core/                         # GameColors
├── Game/
│   ├── Coordinator/              # GameSceneCoordinator, GameEnvironment
│   ├── Nodes/                    # Card-ноды, PlayerNode, TrickNode
│   ├── Scenes/                   # GameScene + extensions
│   └── Services/
│       ├── AI/                   # Bot-сервисы (11 файлов)
│       ├── Flow/                 # GameTurnService, GameAnimationService, etc.
│       ├── History/              # DealHistoryStore, DealHistoryExportService
│       ├── Settings/             # GamePlayersSettingsStore
│       └── Statistics/           # GameStatisticsStore
├── Models/
│   ├── Bot/                      # Bot-модели (4 файла)
│   ├── Cards/                    # Card, Deck, Suit, Rank (4 файла)
│   ├── Gameplay/                 # GameState, Rules, etc. (10 файлов)
│   ├── History/                  # Deal-история (5 файлов)
│   ├── Joker/                    # Joker-модели (4 файла)
│   ├── Players/                  # Player-модели (3 файла)
│   └── Statistics/               # Statistics-модели (4 файла)
├── Scoring/                      # ScoreManager, ScoreCalculator, PremiumRules
└── ViewControllers/
    ├── Bidding/                  # 5 файлов
    ├── GameFlow/                 # 2 файла
    └── Results/                  # 16 файлов
```

### Текущее покрытие тестами

| Категория | Файлов | С тестами | Без тестов | Покрытие |
|-----------|--------|-----------|------------|----------|
| **AI сервисы** | 11 | 9 | 2 | 82% |
| **Flow сервисы** | 5 | 2 | 3 | 40% |
| **History сервисы** | 2 | 2 | 0 | 100% |
| **Settings сервисы** | 1 | 1 | 0 | 100% |
| **Statistics сервисы** | 2 | 1 | 1 | 50% |
| **Модели (все)** | 34 | 4 | 30 | 12% |
| **Scoring** | 3 | 3 | 0 | 100% |
| **ViewControllers** | 23 | 0 | 23 | 0% |
| **Nodes** | 8 | 0 | 8 | 0% |
| **Scenes** | 5 | 1 | 4 | 20% |
| **Coordinator** | 2 | 0 | 2 | 0% |
| **Core/App** | 2 | 0 | 2 | 0% |
| **ИТОГО** | **100** | **23** | **77** | **23%** |

---

## 📈 Детальная матрица покрытия

### ✅ Хорошее покрытие (>80%)

| Файл | Тесты | Кол-во тестов | Статус |
|------|-------|---------------|--------|
| `BotTurnStrategyService.swift` | `BotTurnStrategyServiceTests.swift` | ~15 | ✅ |
| `BotTurnCandidateEvaluatorService.swift` | `BotTurnCandidateEvaluatorServiceTests.swift` | ~8 | ✅ |
| `BotTurnCandidateRankingService.swift` | `BotTurnCandidateRankingServiceTests*.swift` | ~25 | ✅ |
| `BotTurnCardHeuristicsService.swift` | `BotTurnCardHeuristicsServiceTests.swift` | ~8 | ✅ |
| `BotTurnRoundProjectionService.swift` | `BotTurnRoundProjectionServiceTests.swift` | ~8 | ✅ |
| `BotBiddingService.swift` | `BotBiddingServiceTests.swift` | ~8 | ✅ |
| `BotTrumpSelectionService.swift` | `BotTrumpSelectionServiceTests.swift` | ~5 | ✅ |
| `ScoreCalculator.swift` | `ScoreCalculatorTests.swift` | ~6 | ✅ |
| `ScoreManager.swift` | `ScoreManagerTests.swift` | ~8 | ✅ |
| `PremiumRules.swift` | `PremiumRulesTests.swift` | ~6 | ✅ |
| `DealHistoryStore.swift` | `DealHistoryStoreTests.swift` | ~6 | ✅ |
| `DealHistoryExportService.swift` | `DealHistoryExportServiceTests.swift` | ~4 | ✅ |
| `GamePlayersSettingsStore.swift` | `GamePlayersSettingsStoreTests.swift` | ~3 | ✅ |

### ⚠️ Частичное покрытие (30-80%)

| Файл | Тесты | Кол-во тестов | Статус |
|------|-------|---------------|--------|
| `BotRankNormalization.swift` | `BotRankNormalizationTests.swift` | ~4 | ⚠️ 40% |
| `BotTuning.swift` | `BotTuningTests.swift` | ~6 | ⚠️ 50% |
| `BotSelfPlayEvolutionEngine.swift` | `BotSelfPlayEvolutionEngineTests.swift` | ~4 | ⚠️ 40% |
| `GameState.swift` | `GameStateTests.swift` | ~5 | ⚠️ 50% |
| `GameTurnService.swift` | `GameTurnServiceTests.swift` | ~2 | ⚠️ 30% |
| `TrickTakingResolver.swift` | `TrickTakingResolverTests.swift` | ~8 | ⚠️ 60% |
| `BiddingRules.swift` | `BiddingRulesTests.swift` | ~4 | ⚠️ 50% |
| `GameStatisticsStore.swift` | `GameStatisticsStoreTests.swift` | ~6 | ⚠️ 50% |
| `GameSceneInteractionState.swift` | `GameSceneInteractionStateTests.swift` | ~4 | ⚠️ 50% |
| `GameSceneInteractionTransitionPolicy.swift` | `GameSceneInteractionTransitionPolicyTests.swift` | ~5 | ⚠️ 50% |

### ❌ Без покрытия (<30%)

| Файл | Приоритет | Сложность |
|------|-----------|-----------|
| **AI сервисы** | | |
| `BotMatchContextBuilder.swift` | P1 | Низкая |
| `HandFeatureExtractor.swift` | P1 | Низкая |
| **Flow сервисы** | | |
| `GameAnimationService.swift` | P3 | Высокая (SpriteKit) |
| `GameRoundService.swift` | P2 | Средняя |
| `UserDefaultsGameStatisticsStore.swift` | P3 | Низкая |
| **Модели** | | |
| `BotMatchContext.swift` | P2 | Низкая |
| `BotOpponentModel.swift` | P1 | Низкая |
| `Card.swift` | P2 | Низкая |
| `Deck.swift` | P2 | Низкая |
| `Suit.swift` | P3 | Низкая |
| `Rank.swift` | P3 | Низкая |
| `GameBlock.swift` | P3 | Низкая |
| `GameBlockFormatter.swift` | P3 | Низкая |
| `GameConstants.swift` | P3 | Низкая |
| `GamePhase.swift` | P3 | Низкая |
| `GameState.swift` (доп. тесты) | P2 | Средняя |
| `BiddingRules.swift` (доп. тесты) | P2 | Средняя |
| `TrickTakingResolver.swift` (доп. тесты) | P2 | Средняя |
| `TrumpSelectionRules.swift` | P2 | Средняя |
| `BlockResult.swift` | P3 | Низкая |
| `RoundResult.swift` | P3 | Низкая |
| `DealHistory.swift` | P2 | Низкая |
| `DealHistoryKey.swift` | P3 | Низкая |
| `DealTrainingMoveSample.swift` | P3 | Низкая |
| `DealTrickHistory.swift` | P2 | Низкая |
| `DealTrickMove.swift` | P3 | Низкая |
| `JokerLeadDeclaration.swift` | P2 | Низкая |
| `JokerPlayDecision.swift` | P2 | Низкая |
| `JokerPlayStyle.swift` | P3 | Низкая |
| `PlayedTrickCard.swift` | P2 | Низкая |
| `GamePlayersSettings.swift` | P3 | Низкая |
| `PlayerControlType.swift` | P3 | Низкая |
| `PlayerInfo.swift` | P2 | Низкая |
| `GameFinalPlayerSummary.swift` | P2 | Низкая |
| `GameStatisticsPlayerRecord.swift` | P3 | Низкая |
| `GameStatisticsScope.swift` | P3 | Низкая |
| `GameStatisticsSnapshot.swift` | P3 | Низкая |
| **ViewControllers (23 файла)** | | |
| `BidSelectionModalBaseViewController.swift` | P4 | Высокая (UI) |
| `BidSelectionViewController.swift` | P4 | Высокая (UI) |
| `JokerModeSelectionViewController.swift` | P4 | Высокая (UI) |
| `PreDealBlindSelectionViewController.swift` | P4 | Высокая (UI) |
| `TrumpSelectionViewController.swift` | P4 | Высокая (UI) |
| `GameParametersViewController.swift` | P4 | Высокая (UI) |
| `PlayerSelectionViewController.swift` | P4 | Высокая (UI) |
| `DealHistoryViewController.swift` | P4 | Высокая (UI) |
| `GameResultsViewController.swift` | P4 | Высокая (UI) |
| `ScoreTableGridRenderer.swift` | P3 | Средняя |
| `ScoreTableInProgressRoundSnapshotProvider.swift` | P2 | Средняя |
| `ScoreTableLabelFrameResolver.swift` | P2 | Средняя |
| `ScoreTableLabelManager.swift` | P3 | Средняя |
| `ScoreTablePremiumDecorator.swift` | P3 | Средняя |
| `ScoreTableRenderSnapshotBuilder.swift` | P2 | Средняя |
| `ScoreTableRowNavigationResolver.swift` | P3 | Средняя |
| `ScoreTableRowPresentationResolver.swift` | P3 | Средняя |
| `ScoreTableRowTextRenderer.swift` | P3 | Средняя |
| `ScoreTableScrollOffsetResolver.swift` | P2 | Средняя |
| `ScoreTableTapTargetResolver.swift` | P3 | Средняя |
| `ScoreTableView.swift` | P4 | Высокая (UI) |
| `ScoreTableViewController.swift` | P4 | Высокая (UI) |
| `GameViewController.swift` | P4 | Высокая (UI) |
| **Nodes (8 файлов)** | | |
| `CardHandNode.swift` | P3 | Высокая (SpriteKit) |
| `CardNode.swift` | P3 | Высокая (SpriteKit) |
| `GameButton.swift` | P3 | Средняя |
| `PlayerNode.swift` | P3 | Высокая (SpriteKit) |
| `PokerTableNode.swift` | P3 | Высокая (SpriteKit) |
| `TrickNode.swift` | P2 | Средняя |
| `TrumpIndicator.swift` | P3 | Высокая (SpriteKit) |
| `TurnIndicatorNode.swift` | P3 | Средняя |
| **Scenes (4 файла без тестов)** | | |
| `GameScene.swift` | P3 | Высокая (интеграция) |
| `GameScene+DealingFlow.swift` | P3 | Высокая |
| `GameScene+BiddingFlow.swift` | P3 | Высокая |
| `GameScene+ModalFlow.swift` | P3 | Высокая |
| `GameScene+PlayingFlow.swift` | P2 | Высокая (частично в Flow tests) |
| **Coordinator (2 файла)** | | |
| `GameSceneCoordinator.swift` | P2 | Средняя |
| `GameEnvironment.swift` | P3 | Низкая |
| **Core/App (2 файла)** | | |
| `GameColors.swift` | P4 | Низкая |
| `AppDelegate.swift` | P4 | Низкая |

---

## 🎯 Целевое покрытие по приоритетам

| Приоритет | Категория | Целевое покрытие | Срок |
|-----------|-----------|------------------|------|
| **P0** | AI ядро (критичное) | 95% | 2 недели |
| **P1** | AI вспомогательное + Модели | 90% | 4 недели |
| **P2** | Flow сервисы + Gameplay модели | 85% | 6 недель |
| **P3** | Nodes + Scenes + ViewControllers (логика) | 70% | 8 недель |
| **P4** | UI тесты + Infrastructure | 50% | 10 недель |

---

## 📋 Детальный план работ

### Фаза 1: Критические AI пробелы (2 недели)

#### Шаг 1.1: HandFeatureExtractorTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Bot/HandFeatureExtractorTests.swift`

```swift
final class HandFeatureExtractorTests: XCTestCase {
    private let extractor = HandFeatureExtractor()
    
    // 1-10: Базовые тесты
    func testExtract_fromEmptyHand_returnsZeroFeatures()
    func testExtract_fromJokersOnly_returnsJokerCountOnly()
    func testExtract_fromRegularCardsOnly_returnsCorrectSuitCounts()
    func testExtract_highCardCount_countsQueenKingAceOnly()
    func testExtract_longestSuitCount_returnsMaxSuitLength()
    func testExtract_mixedHand_returnsAllFeaturesCorrectly()
    func testExtract_duplicateCards_handlesCorrectly()
    func testExtract_allSuitsRepresented_returnsCorrectCounts()
    func testExtract_singleSuit_returnsCorrectLengthAndZeroOthers()
    func testExtract_performance_doesNotDegradeWithHandSize()
}
```

**Критерии:**
- [x] 10+ тестов проходят
- [ ] Покрытие ≥ 95%

---

#### Шаг 1.2: BotMatchContextBuilderTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Bot/BotMatchContextBuilderTests.swift`

```swift
final class BotMatchContextBuilderTests: XCTestCase {
    private let builder = BotMatchContextBuilder()
    
    // 1-10: Premium/penalty context
    func testBuildContext_withoutPremium_returnsNilPremiumSnapshot()
    func testBuildContext_premiumCandidate_detectedCorrectly()
    func testBuildContext_zeroPremiumCandidate_detectedCorrectly()
    func testBuildContext_penaltyTargetRisk_calculatedFromPremiumCandidates()
    func testBuildContext_leftNeighborPremiumCandidate_flagSetCorrectly()
    func testBuildContext_opponentPremiumCandidatesCount_excludesSelf()
    func testBuildContext_completedRoundsCount_accurateForBlockProgress()
    func testBuildContext_opponentModel_snapshotsBuiltFromRoundResults()
    func testBuildContext_opponentModel_zeroEvidenceAtBlockStart()
    func testBuildContext_fullIntegration_allFieldsPopulatedCorrectly()
}
```

**Критерии:**
- [x] 10+ тестов проходят
- [ ] Покрытие ≥ 90%

---

#### Шаг 1.3: BotOpponentModelTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Bot/BotOpponentModelTests.swift`

```swift
final class BotOpponentModelTests: XCTestCase {
    
    // 1-10: Model structure tests
    func testOpponentSnapshot_hasEvidence_returnsTrueWhenObservedRoundsGreaterThanZero()
    func testOpponentSnapshot_hasEvidence_returnsFalseWhenObservedRoundsIsZero()
    func testSnapshot_for_returnsCorrectSnapshotByPlayerIndex()
    func testSnapshot_for_returnsNilForUnknownPlayerIndex()
    func testLeftNeighborIndex_calculatedCorrectlyForFourPlayers()
    func testLeftNeighborIndex_returnsNilWhenOpponentsAreNil()
    func testOpponentSnapshot_blindBidRate_isWithinZeroToOne()
    func testOpponentSnapshot_averageBidAggression_isWithinExpectedRange()
    func testSnapshots_isImmutableAfterInitialization()
    func testEquatable_conformance_worksCorrectly()
}
```

**Критерии:**
- [x] 10+ тестов проходят
- [ ] Покрытие ≥ 90%

---

### Фаза 2: Модели и правила (3 недели)

#### Шаг 2.1: CardModelTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Models/CardModelTests.swift`

```swift
final class CardModelTests: XCTestCase {
    
    // Card.swift
    func testCardSuit_returnsNilForJoker()
    func testCardRank_returnsNilForJoker()
    func testCardIsJoker_returnsTrueForJoker()
    func testCardComparable_sortsRegularBeforeJoker()
    func testCardDescription_joker_returnsEmojiAndName()
    func testCardFullName_regular_returnsRankAndSuit()
    func testCardBeats_jokerBeatsEverything()
    func testCardBeats_trumpBeatsNonTrump()
    func testCardBeats_sameSuitHigherRankWins()
    func testCardEquality_sameSuitAndRank_equal()
}
```

**Критерии:**
- [ ] 10 тестов проходят
- [ ] Покрытие ≥ 90%

---

#### Шаг 2.2: DeckTests (2-3 часа)

**Файл:** `Jocker/JockerTests/Models/DeckTests.swift`

```swift
final class DeckTests: XCTestCase {
    
    func testDeckInit_containsExpectedCardCount()
    func testDeckContains_allSuitsAndRanksPresent()
    func testDeckContains_exactlyTwoJokers()
    func testDeckShuffle_changesOrder()
    func testDeckCount_afterShuffle_sameCount()
}
```

**Критерии:**
- [ ] 5 тестов проходят
- [ ] Покрытие ≥ 90%

---

#### Шаг 2.3: SuitRankTests (2-3 часа)

**Файл:** `Jocker/JockerTests/Models/SuitRankTests.swift`

```swift
final class SuitRankTests: XCTestCase {
    
    // Suit.swift
    func testSuit_allCases_hasFourSuits()
    func testSuitComparable_ordersByRawValue()
    func testSuitDescription_returnsEmoji()
    
    // Rank.swift
    func testRank_allCases_hasExpectedCount()
    func testRankComparable_ordersByRawValue()
    func testRankSymbol_returnsCorrectSymbol()
    func testRankName_returnsCorrectName()
}
```

**Критерии:**
- [ ] 7 тестов проходят
- [ ] Покрытие ≥ 85%

---

#### Шаг 2.4: GameplayModelsTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Models/GameplayModelsTests.swift`

```swift
final class GameplayModelsTests: XCTestCase {
    
    // GameState.swift
    func testGameStateInit_createsExpectedPlayerCount()
    func testGameStateStartGame_setsInitialPhase()
    func testGameStateStartNewRound_resetsPlayerData()
    func testGameStateSetPlayerNames_appliesTrimming()
    
    // GameBlock.swift
    func testGameBlock_allCases_hasFourBlocks()
    func testGameBlockFormatter_formatBlock_returnsExpectedString()
    
    // GameConstants.swift
    func testGameConstants_deals_forPlayerCount_returnsExpectedDeals()
    func testGameConstants_cardsPerPlayer_forBlockRound_returnsExpected()
    
    // BlockResult.swift
    func testBlockResult_initialization_storesValues()
    
    // RoundResult.swift
    func testRoundResult_initialization_storesValues()
}
```

**Критерии:**
- [ ] 12 тестов проходят
- [ ] Покрытие ≥ 85%

---

#### Шаг 2.5: RulesTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Models/RulesTests.swift`

```swift
final class RulesTests: XCTestCase {
    
    // TrickTakingResolver.swift (дополнение)
    func testWinnerPlayerIndex_emptyPlayedCards_returnsNil()
    func testWinnerPlayerIndex_singleCard_returnsThatPlayer()
    func testWinnerPlayerIndex_multipleCards_returnsHighest()
    func testWinnerPlayerIndex_trumpBeatsNonTrump()
    func testWinnerPlayerIndex_jokerFaceUpBeatsAll()
    func testWinnerPlayerIndex_jokerFaceDownCannotWin()
    func testWinnerPlayerIndex_leadJokerWish_winsUnlessOverridden()
    func testWinnerPlayerIndex_leadJokerAbove_usesRequestedSuit()
    func testWinnerPlayerIndex_leadJokerTakes_usesLowestOfSuit()
    
    // BiddingRules.swift (дополнение)
    func testBiddingRules_forbiddenBidLogic()
    func testBiddingRules_blindBidValidation()
    
    // TrumpSelectionRules.swift
    func testTrumpSelectionRules_minimumCardsToDeclare()
    func testTrumpSelectionRules_playerChoiceStageBonus()
}
```

**Критерии:**
- [ ] 13 тестов проходят
- [ ] Покрытие ≥ 90%

---

#### Шаг 2.6: JokerModelsTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Models/JokerModelsTests.swift`

```swift
final class JokerModelsTests: XCTestCase {
    
    // JokerLeadDeclaration.swift
    func testJokerLeadDeclaration_equatable()
    func testJokerLeadDeclaration_description_wish()
    func testJokerLeadDeclaration_description_above()
    func testJokerLeadDeclaration_description_takes()
    
    // JokerPlayDecision.swift
    func testJokerPlayDecision_defaultNonLead()
    func testJokerPlayDecision_faceUpWithDeclaration()
    func testJokerPlayDecision_equatable()
    
    // JokerPlayStyle.swift
    func testJokerPlayStyle_allCases()
    func testJokerPlayStyle_description()
    
    // PlayedTrickCard.swift
    func testPlayedTrickCard_initialization()
    func testPlayedTrickCard_equatable()
}
```

**Критерии:**
- [ ] 11 тестов проходят
- [ ] Покрытие ≥ 90%

---

#### Шаг 2.7: HistoryModelsTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Models/HistoryModelsTests.swift`

```swift
final class HistoryModelsTests: XCTestCase {
    
    // DealHistory.swift
    func testDealHistory_initialization()
    func testDealHistory_codable()
    
    // DealHistoryKey.swift
    func testDealHistoryKey_initialization()
    func testDealHistoryKey_hashable()
    
    // DealTrainingMoveSample.swift
    func testDealTrainingMoveSample_initialization()
    
    // DealTrickHistory.swift
    func testDealTrickHistory_initialization()
    
    // DealTrickMove.swift
    func testDealTrickMove_initialization()
}
```

**Критерии:**
- [ ] 7 тестов проходят
- [ ] Покрытие ≥ 85%

---

#### Шаг 2.8: PlayerStatisticsModelsTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Models/PlayerStatisticsModelsTests.swift`

```swift
final class PlayerStatisticsModelsTests: XCTestCase {
    
    // Player-модели
    func testGamePlayersSettings_initialization()
    func testPlayerControlType_allCases()
    func testPlayerInfo_initialization()
    func testPlayerInfo_resetForNewRound()
    
    // Statistics-модели
    func testGameFinalPlayerSummary_initialization()
    func testGameStatisticsPlayerRecord_initialization()
    func testGameStatisticsScope_allCases()
    func testGameStatisticsSnapshot_initialization()
}
```

**Критерии:**
- [ ] 8 тестов проходят
- [ ] Покрытие ≥ 85%

---

### Фаза 3: Flow сервисы (2 недели)

#### Шаг 3.1: GameRoundServiceTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Flow/GameRoundServiceTests.swift`

```swift
final class GameRoundServiceTests: XCTestCase {
    
    private let service = GameRoundService()
    
    func testCompleteRound_recordsAllPlayerResults()
    func testCompleteRound_calculatesWinnerCorrectly()
    func testCompleteRound_handlesBlindRound_doublesScore()
    func testCompleteRound_updatesScoreManager()
    func testCompleteRound_returnsRoundResult()
    func testCompleteRound_withIncompleteData_handlesGracefully()
}
```

**Критерии:**
- [ ] 6 тестов проходят
- [ ] Покрытие ≥ 85%

---

#### Шаг 3.2: GameSceneCoordinatorTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Coordinator/GameSceneCoordinatorTests.swift`

```swift
final class GameSceneCoordinatorTests: XCTestCase {
    
    private let coordinator = GameSceneCoordinator()
    
    func testCoordinator_startGame_createsGameState()
    func testCoordinator_startRound_setsPhase()
    func testCoordinator_handleBidding_completesBiddingPhase()
    func testCoordinator_handleTrumpSelection_setsTrump()
    func testCoordinator_handlePlaying_completesRound()
    func testCoordinator_completeBlock_finalizesBlock()
    func testCoordinator_completeGame_setsGameEndPhase()
}
```

**Критерии:**
- [ ] 7 тестов проходят
- [ ] Покрытие ≥ 80%

---

#### Шаг 3.3: GameEnvironmentTests (2-3 часа)

**Файл:** `Jocker/JockerTests/Coordinator/GameEnvironmentTests.swift`

```swift
final class GameEnvironmentTests: XCTestCase {
    
    func testGameEnvironment_initialization()
    func testGameEnvironment_dependencyInjection()
}
```

**Критерии:**
- [ ] 2 теста проходят
- [ ] Покрытие ≥ 90%

---

### Фаза 4: ScoreTable логика (2 недели)

#### Шаг 4.1: ScoreTableResolverTests (8-10 часов)

**Файл:** `Jocker/JockerTests/Results/ScoreTableResolverTests.swift`

```swift
final class ScoreTableResolverTests: XCTestCase {
    
    // ScoreTableLabelFrameResolver.swift (дополнение)
    func testLabelFrameResolver_allColumnWidths()
    func testLabelFrameResolver_pinnedHeader_scrolling()
    
    // ScoreTableRowNavigationResolver.swift (дополнение)
    func testRowNavigationResolver_scrollToRow()
    func testRowNavigationResolver_visibleRange()
    
    // ScoreTableRowPresentationResolver.swift
    func testRowPresentationResolver_cellConfiguration()
    func testRowPresentationResolver_premiumIndicator()
    
    // ScoreTableRowTextRenderer.swift
    func testRowTextRenderer_scoreFormatting()
    func testRowTextRenderer_tricksFormatting()
    
    // ScoreTableScrollOffsetResolver.swift
    func testScrollOffsetResolver_calculateOffset()
    func testScrollOffsetResolver_boundaryConditions()
    
    // ScoreTableTapTargetResolver.swift
    func testTapTargetResolver_hitTesting()
}
```

**Критерии:**
- [ ] 12 тестов проходят
- [ ] Покрытие ≥ 80%

---

#### Шаг 4.2: ScoreTableBuilderTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Results/ScoreTableBuilderTests.swift`

```swift
final class ScoreTableBuilderTests: XCTestCase {
    
    // ScoreTableRenderSnapshotBuilder.swift
    func testSnapshotBuilder_buildSnapshot_emptyData()
    func testSnapshotBuilder_buildSnapshot_withData()
    func testSnapshotBuilder_buildSnapshot_premiumMarking()
    func testSnapshotBuilder_buildSnapshot_inProgressRound()
    
    // ScoreTableLabelManager.swift
    func testLabelManager_createLabels()
    func testLabelManager_updateColumnWidths()
    
    // ScoreTablePremiumDecorator.swift (дополнение)
    func testPremiumDecorator_addPremiumIndicators()
    func testPremiumDecorator_updateLayoutMetrics()
}
```

**Критерии:**
- [ ] 8 тестов проходят
- [ ] Покрытие ≥ 80%

---

#### Шаг 4.3: ScoreTableProviderTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Results/ScoreTableProviderTests.swift`

```swift
final class ScoreTableProviderTests: XCTestCase {
    
    // ScoreTableInProgressRoundSnapshotProvider.swift (дополнение)
    func testInProgressProvider_snapshotWithPartialData()
    func testInProgressProvider_snapshotWithFullData()
    
    // ScoreTableGridRenderer.swift
    func testGridRenderer_renderGrid()
    func testGridRenderer_renderCellBorders()
}
```

**Критерии:**
- [ ] 4 теста проходят
- [ ] Покрытие ≥ 80%

---

### Фаза 5: Nodes и SpriteKit (3 недели)

#### Шаг 5.1: TrickNodeTests (4-6 часов)

**Файл:** `Jocker/JockerTests/Nodes/TrickNodeTests.swift`

```swift
final class TrickNodeTests: XCTestCase {
    
    private let trickNode = TrickNode()
    
    func testTrickNode_playCard_addsCard()
    func testTrickNode_playCard_fromMultiplePlayers()
    func testTrickNode_canPlayCard_validMove()
    func testTrickNode_canPlayCard_invalidMove()
    func testTrickNode_clearResetsPlayedCards()
    func testTrickNode_playedCardsCount()
}
```

**Критерии:**
- [ ] 6 тестов проходят
- [ ] Покрытие ≥ 80%

---

#### Шаг 5.2: GameButtonTests (2-3 часа)

**Файл:** `Jocker/JockerTests/Nodes/GameButtonTests.swift`

```swift
final class GameButtonTests: XCTestCase {
    
    func testGameButton_initialization()
    func testGameButton_actionClosure()
    func testGameButton_enabledDisabled()
}
```

**Критерии:**
- [ ] 3 теста проходят
- [ ] Покрытие ≥ 75%

---

#### Шаг 5.3: TurnIndicatorNodeTests (2-3 часа)

**Файл:** `Jocker/JockerTests/Nodes/TurnIndicatorNodeTests.swift`

```swift
final class TurnIndicatorNodeTests: XCTestCase {
    
    func testTurnIndicator_showForPlayer()
    func testTurnIndicator_hide()
    func testTurnIndicator_animate()
}
```

**Критерии:**
- [ ] 3 теста проходят
- [ ] Покрытие ≥ 75%

---

### Фаза 6: AI дополнительные тесты (1 неделя)

#### Шаг 6.1: BotTuningTests (дополнение) (4-6 часов)

**Файл:** `Jocker/JockerTests/Bot/BotTuningTests.swift` (дополнение)

```swift
extension BotTuningTests {
    func testPresets_allHaveReasonableBounds()
    func testTurnStrategy_coefficients_nonNegative()
    func testBidding_coefficients_withinExpectedRange()
    func testTiming_delays_positive()
    func testSelfPlayEvolution_deterministic_sameSeed()
    func testSelfPlayEvolution_fitnessCalculation_correct()
    func testSelfPlayEvolutionMutation_appliesChanges()
    func testSelfPlayEvolutionCrossover_combinesParents()
    func testTuningScopeMask_turnStrategyOnly_affectsCorrectFields()
    func testSelfPlayEvolution_fullCycle_reportsMetrics()
}
```

**Критерии:**
- [ ] 10 тестов проходят
- [ ] Покрытие ≥ 80%

---

#### Шаг 6.2: BotRankNormalizationTests (дополнение) (2-3 часа)

**Файл:** `Jocker/JockerTests/Bot/BotRankNormalizationTests.swift` (дополнение)

```swift
extension BotRankNormalizationTests {
    func testNormalizedForBidding_boundaryRanks()
    func testNormalizedForFutureProjection_boundaryRanks()
    func testNormalizedForTrumpSelection_boundaryRanks()
    func testIsHighCard_allRanks_queenKingAceOnly()
    func testNormalization_monotonic_higherRankHigherNormalized()
    func testNormalization_performance_batchCall()
}
```

**Критерии:**
- [ ] 6 тестов проходят
- [ ] Покрытие ≥ 95%

---

### Фаза 7: Интеграционные тесты (2 недели)

#### Шаг 7.1: FullGameFlowTests (8-10 часов)

**Файл:** `Jocker/JockerTests/Flow/FullGameFlowTests.swift`

```swift
final class FullGameFlowTests: XCTestCase {
    
    func testFullGame_fourPlayers_completesAllBlocks()
    func testFullGame_threePlayers_completesAllBlocks()
    func testFullGame_withBlindBids_doublesScores()
    func testFullGame_withPremium_awardsCorrectly()
    func testFullGame_withPenalty_appliesCorrectly()
    func testFullGame_statisticsRecorded()
}
```

**Критерии:**
- [ ] 6 тестов проходят
- [ ] Интеграция всех сервисов

---

#### Шаг 7.2: BotIntegrationTests (6-8 часов)

**Файл:** `Jocker/JockerTests/Bot/BotIntegrationTests.swift`

```swift
final class BotIntegrationTests: XCTestCase {
    
    func testBeliefStateLegalAware_integration_improvesAccuracy()
    func testBlockPlanningUtility_integration_appliesPlan()
    func testOpponentIntentionUtility_integration_adjustsUtility()
    func testRolloutEvaluator_integration_usesLookahead()
    func testEndgameSolverStrategy_integration_solvesEndgame()
    func testCompositeUtilityRanking_integration_multiplicative()
    func testGoalOrientedJokerHeuristics_integration_evaluatesGoals()
    func testHandStrengthConsistency_biddingAndProjection_aligned()
    func testFullRuntimePipeline_allServicesIntegrated()
    func testRegressionSuite_noDegradationFromBaseline()
}
```

**Критерии:**
- [ ] 10 тестов проходят
- [ ] Все guardrails зелёные

---

## 📈 Итоговые метрики

### Целевое покрытие по завершении

| Категория | Текущее | Целевое | Delta |
|-----------|---------|---------|-------|
| AI сервисы | 82% | 95% | +13% |
| Flow сервисы | 40% | 85% | +45% |
| Models | 12% | 90% | +78% |
| Scoring | 100% | 100% | 0% |
| ViewControllers (логика) | 0% | 70% | +70% |
| Nodes | 0% | 60% | +60% |
| Scenes | 20% | 70% | +50% |
| Coordinator | 0% | 80% | +80% |
| **ОБЩЕЕ** | **23%** | **80%** | **+57%** |

### Количество тестов

| Категория | Текущее | Целевое | Delta |
|-----------|---------|---------|-------|
| Bot тесты | ~123 | ~180 | +57 |
| Flow тесты | ~25 | ~50 | +25 |
| Models тесты | ~10 | ~70 | +60 |
| Results тесты | ~30 | ~50 | +20 |
| Nodes тесты | 0 | ~15 | +15 |
| Integration тесты | ~5 | ~20 | +15 |
| **ИТОГО** | **~193** | **~385** | **+192** |

---

## 🗺️ Дорожная карта

```
Неделя 1-2:  Фаза 1 (Критические AI пробелы)
             ├─ HandFeatureExtractorTests
             ├─ BotMatchContextBuilderTests
             └─ BotOpponentModelTests

Неделя 3-5:  Фаза 2 (Модели и правила)
             ├─ CardModelTests, DeckTests, SuitRankTests
             ├─ GameplayModelsTests
             ├─ RulesTests
             ├─ JokerModelsTests
             ├─ HistoryModelsTests
             └─ PlayerStatisticsModelsTests

Неделя 6-7:  Фаза 3 (Flow сервисы)
             ├─ GameRoundServiceTests
             ├─ GameSceneCoordinatorTests
             └─ GameEnvironmentTests

Неделя 8-9:  Фаза 4 (ScoreTable логика)
             ├─ ScoreTableResolverTests
             ├─ ScoreTableBuilderTests
             └─ ScoreTableProviderTests

Неделя 10-12: Фаза 5 (Nodes и SpriteKit)
             ├─ TrickNodeTests
             ├─ GameButtonTests
             └─ TurnIndicatorNodeTests

Неделя 13:   Фаза 6 (AI дополнительные тесты)
             ├─ BotTuningTests (дополнение)
             └─ BotRankNormalizationTests (дополнение)

Неделя 14-15: Фаза 7 (Интеграционные тесты)
             ├─ FullGameFlowTests
             └─ BotIntegrationTests
```

**Итого:** 15 недель (~380-450 часов)

---

## ✅ Критерии завершения

### Обязательные (P0-P2)
- [ ] Все AI сервисы покрыты ≥ 90%
- [ ] Все модели покрыты ≥ 85%
- [ ] Все Flow сервисы покрыты ≥ 80%
- [ ] Все guardrails (`joker-pack`, `stage6b-pack-all`) зелёные
- [ ] CI стабильность ≥ 99%

### Желательные (P3-P4)
- [ ] Nodes покрыты ≥ 60%
- [ ] ViewControllers логика покрыта ≥ 70%
- [ ] Интеграционные тесты проходят
- [ ] Общее покрытие ≥ 80%

---

## 🔗 Связанные документы

- `BOT_AI_IMPROVEMENT_PLAN.md` — стадийный план улучшений AI
- `BOT_AI_TEST_SCENARIOS.md` — детерминированные сценарии
- `BOT_AI_IMPROVEMENT_PROPOSALS_UNIFIED.md` — актуальный unified backlog и self-play protocol
- `BOT_AI_TEST_COVERAGE_PLAN.md` — план покрытия AI тестами (предыдущая версия)

---

## 📝 Приложения

### A. Команды для запуска тестов

```bash
# Build-for-testing (базовый gate)
xcodebuild -quiet -project Jocker/Jocker.xcodeproj -scheme Jocker \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build-for-testing

# Полный тестовый прогон scheme Jocker
xcodebuild -project Jocker/Jocker.xcodeproj -scheme Jocker \
  -destination 'id=<SIMULATOR_ID>' -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO test-without-building

# Точечный прогон по Bot suite
xcodebuild -project Jocker/Jocker.xcodeproj -scheme Jocker \
  -destination 'id=<SIMULATOR_ID>' -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO test-without-building \
  -only-testing:JockerTests/BotBiddingServiceTests \
  -only-testing:JockerTests/BotTurnRoundProjectionServiceTests \
  -only-testing:JockerTests/BotTrumpSelectionServiceTests \
  -only-testing:JockerTests/BotTurnCardHeuristicsServiceTests \
  -only-testing:JockerTests/BotHandStrengthModelTests

# Joker regression pack
make joker-pack

# Stage 6b guardrails
make stage6b-pack-all

# Self-play checkpoints
make bot-baseline
make bot-compare
make bt-hard-final-esab
```

### B. Приоритизация файлов для тестирования

| Приоритет | Файлов | Часы |
|-----------|--------|------|
| P0 | 5 | 40-50 |
| P1 | 15 | 80-100 |
| P2 | 25 | 120-150 |
| P3 | 30 | 100-120 |
| P4 | 25 | 40-60 |

### C. Шаблон для нового теста

```swift
//
//  <Feature>Tests.swift
//  JockerTests
//

import XCTest
@testable import Jocker

final class <Feature>Tests: XCTestCase {
    private let sut = <Feature>() // System Under Test
    
    override func setUp() {
        super.setUp()
        // Setup
    }
    
    override func tearDown() {
        // Teardown
        super.tearDown()
    }
    
    func test<Feature>_<Scenario>_<ExpectedBehavior>() {
        // Arrange
        let input = ...
        
        // Act
        let result = sut.method(input)
        
        // Assert
        XCTAssertEqual(result, expected)
    }
}
```
