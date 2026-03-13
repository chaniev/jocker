# Детальный план 06. Устойчивость эволюционного поиска без преждевременного усложнения

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.5 / приоритет P2  
**Порядок выполнения:** 6  
**Предусловия:** завершены этапы 01, 03 и 05  
**Статус:** не начат  
**Статус gate:** diversity telemetry, stagnation detection, adaptive mutation, immigrants и restart отсутствуют

## Цель

Повысить устойчивость self-play evolution через измерение diversity, adaptive mutation, random immigrants и controlled restart, не вводя speciation на этой стадии.

## Статус на 2026-03-13

- В текущем engine есть только базовые `mutationChance` / `mutationMagnitude` и early stopping; stage-06 telemetry и механизмы устойчивости не добавлены.
- По коду и скриптам отсутствуют поля `stagnationWindow`, `minimumMeaningfulImprovement`, `baseMutationRate`, `immigrantRatio`, `eliteArchive` и связанный progress/reporting.
- Machine-readable артефактов для diversity/stagnation telemetry тоже нет.

## Шаги выполнения

### 1. Добавить diversity telemetry

1. Ввести в progress reporting следующие метрики:
   - средняя дистанция до элиты;
   - средняя попарная дистанция по genome values;
   - доля уникальных genome signatures;
   - число поколений без улучшения.
2. Считать эти метрики на каждом поколении.
3. Печатать их в summary поколения и в итоговый отчёт.
4. Сохранять их в machine-readable артефактах.

### 2. Ввести stagnation detection как отдельный gate

1. Добавить в public config параметры:
   - `stagnationWindow`
   - `minimumMeaningfulImprovement`
2. Детектировать стагнацию только по `finalFitness`.
3. Логировать состояние стагнации без изменения mutation rate на первом rollout.
4. Прогнать canonical profile в режиме `telemetry + stagnation detection only`.
5. Зафиксировать baseline telemetry для следующих изменений.

### 3. Ввести adaptive mutation rate

1. Добавить в public config параметры:
   - `baseMutationRate`
   - `minMutationRate`
   - `maxMutationRate`
   - `lowDiversityThreshold`
2. Увеличивать mutation rate при стагнации или низком diversity.
3. Возвращать mutation rate к `baseMutationRate` после восстановления прогресса.
4. Печатать mutation rate на каждом поколении.
5. Добавить tests на соблюдение upper/lower bounds.

### 4. Добавить random immigrants

1. Добавить в public config параметр `immigrantRatio`.
2. На каждом поколении заменять фиксированную долю популяции новыми случайными genome values внутри допустимых bounds.
3. Не затрагивать элит, перенесённых напрямую.
4. Помечать immigrants в summary поколения отдельным счётчиком.
5. Добавить tests на долю immigrants и соблюдение bounds.

### 5. Добавить controlled restart from elite archive

1. Ввести `eliteArchive` с ограниченным размером.
2. Сохранять в archive лучшие genome values поколений.
3. При достижении `stagnationWindow` выполнять частичный restart популяции вокруг точек из `eliteArchive`.
4. Не перезаписывать archive слабейшими кандидатами.
5. Логировать каждое событие restart с причиной и составом новой популяции.

### 6. Обновить selection и progress reporting

1. Оставить текущую схему selection без speciation.
2. Подключить diversity telemetry, mutation rate, immigrants и restart events к общему progress report.
3. Выводить в summary поколения:
   - diversity metrics;
   - mutation rate;
   - immigrant count;
   - restart status.
4. Сохранять эти поля в machine-readable summary.

### 7. Провести controlled validation

1. Прогнать canonical profile с `telemetry + stagnation detection only`.
2. Прогнать тот же профиль с adaptive mutation.
3. Прогнать тот же профиль с adaptive mutation + immigrants.
4. Прогнать тот же профиль с full stability pack.
5. Сравнить holdout quality, diversity metrics и training time.
6. Зафиксировать итоговый выигрыш или отсутствие эффекта.

## Проверки

1. Diversity metrics считаются на каждом поколении.
2. Stagnation detection работает до включения adaptive mutation.
3. Mutation rate не выходит за bounds.
4. Immigrants создаются в заданной доле.
5. Restart срабатывает только по конфигурируемому триггеру.
6. Holdout quality не деградирует после включения stability-механизмов.

## Критерии завершения

1. Population diversity измеряется и сохраняется в артефактах.
2. Stagnation detection внедрён и validated отдельно до adaptive mutation.
3. Adaptive mutation, immigrants и restart реализованы как конфигурируемые механизмы.
4. Алгоритм не использует speciation на этой стадии.
5. Full stability pack проходит holdout validation.
6. По итогам этапа видна реальная динамика diversity и стагнации.
