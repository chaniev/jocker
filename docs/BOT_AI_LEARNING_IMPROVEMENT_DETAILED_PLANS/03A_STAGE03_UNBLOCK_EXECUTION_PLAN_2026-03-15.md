# Execution Plan: Stage 03 Unblock + Stage 06 Diagnostic Slice

**Дата:** 2026-03-15  
**Горизонт:** ближайшие 1-2 рабочих дня  
**Цель:** не запускать ещё один "слепой" длинный canonical run, пока `runtimePolicy-only` selector и сам self-play search остаются шумными

## Статус реализации на 2026-03-15

- По коду реализованы:
  - selector hardening для `runtimePolicy-only` output candidate;
  - runtime-policy strength refinement для top candidate variants (`patch50` / `patch75`) при primary A/B selection;
  - промежуточный `medium` profile и `make stage3-scope-validate-medium`;
  - go/no-go правило перед новым `compare-v1`;
  - diversity telemetry;
  - stagnation detection в log-only режиме.
- Ещё не закрыто:
  - положительный `medium` validation run;
  - новый canonical `compare-v1`;
  - полный Xcode test build, который сейчас блокируется внешней compile-ошибкой в app target.
- Актуальный результат rerun на `2026-03-15`:
  - `medium` run `.derivedData/stage3-runtime-scope-runs/20260315-140905/` завершился с `critical-runtime holdout finalFitness = -0.036827`;
  - selector действительно расширил option set (`runtimePolicyPrimaryAB+strengthRefinement`), но всё равно выбрал full-strength `seed_20260222`;
  - conservative variants (`seed_20260222_patch50`, `seed_20260222_patch75`) проиграли уже на primary, поэтому текущий blocker остаётся в качестве самого runtime patch / scoring objective, а не только в selector fallback logic.

## Исходная точка

- Stage 03 по коду реализован, но canonical gate шага 9 остаётся открытым.
- Последний canonical run провалился на `critical-runtime`: holdout `finalFitness = -0.066821`, что хуже `old-scope = -0.058870`.
- Smoke после правки был ложноположительным: selector выбрал тот же `seed_20260220`, но canonical не подтвердил перенос на holdout.

## Что не делать в эти 1-2 дня

- Не идти в Stage 04, 07 или 08 до повторной проверки Stage 03.
- Не запускать `compare-v1`, пока не появится промежуточный `medium` profile и не будет ужесточён selector.

## День 1

### 1. Ужесточить выбор output-candidate для `runtimePolicy-only`

**Файлы**

- `Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`
- `Jocker/JockerTests/Bot/BotSelfPlayEvolutionEngineTests.swift`

**Изменения**

- Добавить минимальный порог переключения `minimumPrimaryEffectMargin` для выбора кандидата не по `selectedSeed`.
- Добавить fallback-правило:
  - если лучший кандидат по `primaryFinalFitnessEffectSize` не превосходит `selected_seed_*` хотя бы на `0.03`, не переключать output-candidate;
  - если лучший кандидат положителен, но все варианты лежат в шумовом коридоре `< 0.03`, оставлять `selectedSeed`.
- В summary/log печатать:
  - `outputCandidateSelectionMargin`
  - `outputCandidateFallbackReason`
  - `outputCandidatePreferredBaseline`
  - `outputCandidateRank.<label>`

**Команды**

```bash
./scripts/train_bot_tuning.sh --compile-only
./scripts/run_stage3_runtime_scope_validation.sh --profile smoke
```

**Done condition**

- `critical-runtime` smoke проходит без регресса относительно текущего smoke baseline.
- В `train_bot_tuning.log` видно, почему selector оставил или переключил candidate.

### 2. Добавить промежуточный `medium` profile между `smoke` и `compare-v1`

**Файлы**

- `scripts/run_bot_ab_comparison_snapshot.sh`
- `scripts/run_stage3_runtime_scope_validation.sh`
- `Makefile`

**Целевая конфигурация `medium`**

- `seed_list=20260220,20260221,20260222,20260223`
- `holdout_seed_list=20260226,20260227,20260228,20260301`
- `population_size=6`
- `generations=4`
- `games_per_candidate=4`
- `rounds_per_game=16`
- `ab_validation_games_per_candidate=4`

**Изменения**

- Добавить `medium` в help/validation обоих harness scripts.
- Добавить make-target `stage3-scope-validate-medium`.

**Команды**

```bash
./scripts/run_bot_ab_comparison_snapshot.sh --profile medium --list-config
./scripts/run_stage3_runtime_scope_validation.sh --profile medium --dry-run
make stage3-scope-validate-medium
```

**Done condition**

- `medium` профиль запускается без ручных override-аргументов.
- Есть `summary.txt` по `old-scope` и `critical-runtime`.

### 3. Ввести go/no-go правило перед canonical

**Файл**

- `docs/BOT_AI_LEARNING_IMPROVEMENT_DETAILED_PLANS/03_RUNTIME_POLICY_EVOLUTION_SCOPE_PLAN.md`

**Изменения**

- Зафиксировать, что `compare-v1` можно запускать только если:
  - `critical-runtime` на `medium` даёт holdout `finalFitness > 0`;
  - `deltaVsOld.holdout.finalFitnessEffectSize > 0`;
  - selector не переключился по шумовому преимуществу `< 0.03`.

**Команды**

```bash
sed -n '1,120p' .derivedData/stage3-runtime-scope-runs/<medium-run>/summary.txt
```

**Done condition**

- Есть формальный stop/go gate до нового 10+ часового прогона.

## День 2

### 4. Реализовать Stage 06.1: diversity telemetry

**Файлы**

- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+PublicTypes.swift`
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift`
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Genome.swift`
- `Jocker/Jocker/Game/Services/AI/TrainingRunResultFormatter.swift`
- `Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`
- `Jocker/JockerTests/Bot/BotSelfPlayEvolutionEngineTests.swift`

**Telemetry-поля**

- `avgDistanceToElite`
- `avgPairwiseDistance`
- `uniqueGenomeRatio`
- `generationsWithoutImprovement`

**Изменения**

- Считать telemetry на каждом поколении.
- Печатать telemetry в progress и в финальном summary.
- Делать вывод deterministic и пригодным для diff между runs.

**Команды**

```bash
./scripts/train_bot_tuning.sh --compile-only
./scripts/run_training_pipeline_smoke.sh
make stage3-scope-validate-medium
```

**Done condition**

- В `train_bot_tuning.log` и `summary.txt` видны diversity/stagnation-поля.
- `medium` run воспроизводимо публикует telemetry без падений runner.

### 5. Реализовать Stage 06.2: stagnation detection в log-only режиме

**Файлы**

- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+PublicTypes.swift`
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift`
- `Jocker/Jocker/Game/Services/AI/TrainingRunResultFormatter.swift`
- `Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`
- `Jocker/JockerTests/Bot/BotSelfPlayEvolutionEngineTests.swift`

**Конфиг первого rollout**

- `stagnationWindow = 3`
- `minimumMeaningfulImprovement = 0.02`
- без изменения `mutationChance` и `mutationMagnitude`

**Изменения**

- Добавить параметры в public config и CLI runner.
- Логировать:
  - `isStagnating`
  - `stagnationWindow`
  - `minimumMeaningfulImprovement`
  - `lastMeaningfulImprovementGeneration`
- Ничего не менять в mutation policy на этом шаге.

**Команды**

```bash
./scripts/train_bot_tuning.sh --compile-only
make stage3-scope-validate-medium
```

**Done condition**

- На `medium` run видно, залипает ли поиск и в каком поколении это происходит.
- Нет поведенческих изменений, кроме новых полей и логирования.

### 6. Повторить validation ladder только после шагов 1-5

**Порядок**

1. `smoke`
2. `medium`
3. `compare-v1` только при go-сигнале с `medium`

**Команды**

```bash
./scripts/run_stage3_runtime_scope_validation.sh --profile smoke
./scripts/run_stage3_runtime_scope_validation.sh --profile medium
./scripts/run_stage3_runtime_scope_validation.sh --profile compare-v1
```

**Go criteria для `compare-v1`**

- `critical-runtime` holdout `finalFitness > 0`
- `critical-runtime` holdout лучше `old-scope`
- telemetry не показывает полного коллапса diversity к середине прогона
- selector не опирается на margin `< 0.03`

**No-go action**

- Если `medium` снова отрицательный, не запускать canonical.
- Вместо этого возвращаться к selector/fallback logic и только потом повторять `medium`.

## Рабочий порядок по приоритету

1. `BotTrainingRunner.swift`: selector threshold + fallback + logging
2. `run_bot_ab_comparison_snapshot.sh` и `run_stage3_runtime_scope_validation.sh`: новый `medium` profile
3. `Makefile`: target для `medium`
4. `BotSelfPlayEvolutionEngine+*`: diversity telemetry
5. `BotSelfPlayEvolutionEngine+*`: stagnation detection log-only
6. `medium` rerun
7. `compare-v1` rerun только при выполнении gate

## Ожидаемый результат к концу 1-2 дней

- Либо Stage 03 получает осмысленный шанс на повторный canonical run с меньшим риском шума.
- Либо `medium` заранее подтверждает, что проблема глубже selector-level, и тогда следующий цикл уже идёт в adaptive mutation / immigrants без потери ещё одного длинного canonical прогона.
