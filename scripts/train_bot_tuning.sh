#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/train_bot_tuning.sh [параметры]

Назначение:
  Запускает офлайн-обучение BotTuning через self-play
  (эволюция коэффициентов бота по fitness-метрике).

Параметры:
  --difficulty <easy|normal|hard>   Базовый пресет, от которого начинается эволюция
                                     (по умолчанию: hard).
  --seed <uint64>                   Seed генератора случайных чисел; одинаковый seed
                                     дает воспроизводимый результат (по умолчанию: 20260220).
  --seed-list <a,b,c>               Список seed через запятую для multi-seed ensemble.
                                     Если задан, параметр --seed игнорируется.
  --ensemble-method <median|mean>   Способ агрегации итоговых коэффициентов по seed
                                     (по умолчанию: median).
  --population-size <int>           Размер популяции в поколении; больше = стабильнее поиск,
                                     но дольше выполнение (по умолчанию: 12).
  --generations <int>               Количество поколений эволюции; больше = глубже поиск,
                                     но дольше запуск (по умолчанию: 10).
  --games-per-candidate <int>       Кол-во self-play игр для оценки одного кандидата;
                                     больше = менее шумная оценка fitness (по умолчанию: 20).
  --rounds-per-game <int>           Кол-во раундов в одной симулированной игре
                                     (по умолчанию: 8).
  --player-count <int>              Число игроков в симуляции (в коде нормализуется к 3..4;
                                     по умолчанию: 4).
  --cards-min <int>                 Минимум карт на раунд (по умолчанию: 2).
  --cards-max <int>                 Максимум карт на раунд (по умолчанию: 9).
  --elite-count <int>               Сколько лучших кандидатов переносить без изменений
                                     в следующее поколение (по умолчанию: 3).
  --mutation-chance <double>        Вероятность мутации параметра [0..1]
                                     (по умолчанию: 0.34).
  --mutation-magnitude <double>     Сила мутации (амплитуда изменения параметров)
                                     (по умолчанию: 0.16).
  --selection-pool-ratio <double>   Доля лучших кандидатов для выбора родителей;
                                     в коде ограничивается диапазоном [0.2..1.0]
                                     (по умолчанию: 0.55).
  --use-full-match-rules <true|false>
                                     Включить симуляцию полной партии по блокам 1..4
                                     с blind и премиями (по умолчанию: true).
  --rotate-candidate-across-seats <true|false>
                                     Оценивать кандидата на всех местах за столом для
                                     каждого seed-сценария (по умолчанию: true).
  --fitness-win-rate-weight <double>
                                     Вес компоненты win-rate в fitness (по умолчанию: 1.0).
  --fitness-score-diff-weight <double>
                                     Вес компоненты разницы очков vs соперники
                                     в fitness (по умолчанию: 1.0).
  --fitness-underbid-loss-weight <double>
                                     Вес компоненты потерь от недозаказа
                                     в fitness (по умолчанию: 0.85).
  --fitness-trump-density-underbid-weight <double>
                                     Вес компоненты недозаказа в руках
                                     с высокой плотностью козырей (по умолчанию: 0.60).
  --fitness-notrump-control-underbid-weight <double>
                                     Вес компоненты недозаказа в no-trump контрольных
                                     руках (старшие/длинная масть/джокер) (по умолчанию: 0.70).
  --fitness-premium-assist-weight <double>
                                     Вес компоненты штрафа за "подаренные" соперникам
                                     премии (по умолчанию: 0.55).
  --fitness-premium-penalty-target-weight <double>
                                     Вес компоненты штрафа за получение штрафа как цель
                                     чужой премии (по умолчанию: 1.10).
  --score-diff-normalization <double>
                                     Делитель для компоненты разницы очков;
                                     больше значение = меньше вклад scoreDiff
                                     (по умолчанию: 450).
  --underbid-loss-normalization <double>
                                     Делитель для компоненты underbidLoss;
                                     больше значение = меньше вклад
                                     штрафа за недозаказ (по умолчанию: 6000).
  --trump-density-underbid-normalization <double>
                                     Делитель для компоненты недозаказа
                                     в "козырной плотности" (по умолчанию: 2800).
  --notrump-control-underbid-normalization <double>
                                     Делитель для компоненты недозаказа
                                     в no-trump контрольных руках (по умолчанию: 2200).
  --premium-assist-normalization <double>
                                     Делитель для компоненты "подаренных" премий
                                     соперникам (по умолчанию: 1800).
  --premium-penalty-target-normalization <double>
                                     Делитель для компоненты штрафа как цели
                                     чужой премии (по умолчанию: 1600).
  --show-progress <true|false>       Показывать live-прогресс обучения
                                     (по умолчанию: true).
  --progress-candidate-step <int>    Частота прогресса по кандидатам внутри поколения:
                                     1 = печатать после каждого кандидата,
                                     5 = после каждого 5-го и в конце поколения
                                     (по умолчанию: 1).
  --output <path>                   Путь для сохранения полного лога запуска.
  -h, --help                        Показать эту справку.

Примеры:
  scripts/train_bot_tuning.sh
  scripts/train_bot_tuning.sh --seed 123456 --generations 14 --games-per-candidate 40
  scripts/train_bot_tuning.sh --seed-list 20260220,20260221,20260222 --ensemble-method median
  scripts/train_bot_tuning.sh --show-progress true --progress-candidate-step 2
  scripts/train_bot_tuning.sh --difficulty normal --output .derivedData/bot-train.log
  scripts/train_bot_tuning.sh --games-per-candidate 24 --use-full-match-rules true --rotate-candidate-across-seats true
EOF
}

require_int() {
  local value="$1"
  local flag="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Invalid integer for $flag: $value" >&2
    exit 1
  fi
}

require_double() {
  local value="$1"
  local flag="$2"
  if [[ ! "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Invalid decimal for $flag: $value" >&2
    exit 1
  fi
}

require_bool() {
  local value="$1"
  local flag="$2"
  case "$value" in
    true|false) ;;
    *)
      echo "Invalid boolean for $flag: $value (use true|false)" >&2
      exit 1
      ;;
  esac
}

require_seed_list() {
  local value="$1"
  local flag="$2"
  if [[ ! "$value" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo "Invalid seed list for $flag: $value (expected comma-separated uint64)" >&2
    exit 1
  fi
}

difficulty="hard"
seed="20260220"
seed_list=""
ensemble_method="median"
population_size="12"
generations="10"
games_per_candidate="20"
rounds_per_game="8"
player_count="4"
cards_min="2"
cards_max="9"
elite_count="3"
mutation_chance="0.34"
mutation_magnitude="0.16"
selection_pool_ratio="0.55"
use_full_match_rules="true"
rotate_candidate_across_seats="true"
fitness_win_rate_weight="1.0"
fitness_score_diff_weight="1.0"
fitness_underbid_loss_weight="0.85"
fitness_trump_density_underbid_weight="0.60"
fitness_notrump_control_underbid_weight="0.70"
fitness_premium_assist_weight="0.55"
fitness_premium_penalty_target_weight="1.10"
score_diff_normalization="450"
underbid_loss_normalization="6000"
trump_density_underbid_normalization="2800"
notrump_control_underbid_normalization="2200"
premium_assist_normalization="1800"
premium_penalty_target_normalization="1600"
show_progress="true"
progress_candidate_step="1"
output_path=""

while (($# > 0)); do
  case "$1" in
    --difficulty)
      difficulty="${2:-}"
      shift 2
      ;;
    --seed)
      seed="${2:-}"
      shift 2
      ;;
    --seed-list)
      seed_list="${2:-}"
      shift 2
      ;;
    --ensemble-method)
      ensemble_method="${2:-}"
      shift 2
      ;;
    --population-size)
      population_size="${2:-}"
      shift 2
      ;;
    --generations)
      generations="${2:-}"
      shift 2
      ;;
    --games-per-candidate)
      games_per_candidate="${2:-}"
      shift 2
      ;;
    --rounds-per-game)
      rounds_per_game="${2:-}"
      shift 2
      ;;
    --player-count)
      player_count="${2:-}"
      shift 2
      ;;
    --cards-min)
      cards_min="${2:-}"
      shift 2
      ;;
    --cards-max)
      cards_max="${2:-}"
      shift 2
      ;;
    --elite-count)
      elite_count="${2:-}"
      shift 2
      ;;
    --mutation-chance)
      mutation_chance="${2:-}"
      shift 2
      ;;
    --mutation-magnitude)
      mutation_magnitude="${2:-}"
      shift 2
      ;;
    --selection-pool-ratio)
      selection_pool_ratio="${2:-}"
      shift 2
      ;;
    --use-full-match-rules)
      use_full_match_rules="${2:-}"
      shift 2
      ;;
    --rotate-candidate-across-seats)
      rotate_candidate_across_seats="${2:-}"
      shift 2
      ;;
    --fitness-win-rate-weight)
      fitness_win_rate_weight="${2:-}"
      shift 2
      ;;
    --fitness-score-diff-weight)
      fitness_score_diff_weight="${2:-}"
      shift 2
      ;;
    --fitness-underbid-loss-weight)
      fitness_underbid_loss_weight="${2:-}"
      shift 2
      ;;
    --fitness-trump-density-underbid-weight)
      fitness_trump_density_underbid_weight="${2:-}"
      shift 2
      ;;
    --fitness-notrump-control-underbid-weight)
      fitness_notrump_control_underbid_weight="${2:-}"
      shift 2
      ;;
    --fitness-premium-assist-weight)
      fitness_premium_assist_weight="${2:-}"
      shift 2
      ;;
    --fitness-premium-penalty-target-weight)
      fitness_premium_penalty_target_weight="${2:-}"
      shift 2
      ;;
    --score-diff-normalization)
      score_diff_normalization="${2:-}"
      shift 2
      ;;
    --underbid-loss-normalization)
      underbid_loss_normalization="${2:-}"
      shift 2
      ;;
    --trump-density-underbid-normalization)
      trump_density_underbid_normalization="${2:-}"
      shift 2
      ;;
    --notrump-control-underbid-normalization)
      notrump_control_underbid_normalization="${2:-}"
      shift 2
      ;;
    --premium-assist-normalization)
      premium_assist_normalization="${2:-}"
      shift 2
      ;;
    --premium-penalty-target-normalization)
      premium_penalty_target_normalization="${2:-}"
      shift 2
      ;;
    --show-progress)
      show_progress="${2:-}"
      shift 2
      ;;
    --progress-candidate-step)
      progress_candidate_step="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

case "$difficulty" in
  easy|normal|hard) ;;
  *)
    echo "Invalid difficulty: $difficulty (use easy|normal|hard)" >&2
    exit 1
    ;;
esac

require_int "$seed" "--seed"
if [[ -n "$seed_list" ]]; then
  require_seed_list "$seed_list" "--seed-list"
fi
require_int "$population_size" "--population-size"
require_int "$generations" "--generations"
require_int "$games_per_candidate" "--games-per-candidate"
require_int "$rounds_per_game" "--rounds-per-game"
require_int "$player_count" "--player-count"
require_int "$cards_min" "--cards-min"
require_int "$cards_max" "--cards-max"
require_int "$elite_count" "--elite-count"
require_double "$mutation_chance" "--mutation-chance"
require_double "$mutation_magnitude" "--mutation-magnitude"
require_double "$selection_pool_ratio" "--selection-pool-ratio"
require_bool "$use_full_match_rules" "--use-full-match-rules"
require_bool "$rotate_candidate_across_seats" "--rotate-candidate-across-seats"
require_double "$fitness_win_rate_weight" "--fitness-win-rate-weight"
require_double "$fitness_score_diff_weight" "--fitness-score-diff-weight"
require_double "$fitness_underbid_loss_weight" "--fitness-underbid-loss-weight"
require_double "$fitness_trump_density_underbid_weight" "--fitness-trump-density-underbid-weight"
require_double "$fitness_notrump_control_underbid_weight" "--fitness-notrump-control-underbid-weight"
require_double "$fitness_premium_assist_weight" "--fitness-premium-assist-weight"
require_double "$fitness_premium_penalty_target_weight" "--fitness-premium-penalty-target-weight"
require_double "$score_diff_normalization" "--score-diff-normalization"
require_double "$underbid_loss_normalization" "--underbid-loss-normalization"
require_double "$trump_density_underbid_normalization" "--trump-density-underbid-normalization"
require_double "$notrump_control_underbid_normalization" "--notrump-control-underbid-normalization"
require_double "$premium_assist_normalization" "--premium-assist-normalization"
require_double "$premium_penalty_target_normalization" "--premium-penalty-target-normalization"
require_bool "$show_progress" "--show-progress"
require_int "$progress_candidate_step" "--progress-candidate-step"
if [[ "$progress_candidate_step" -lt 1 ]]; then
  echo "Invalid value for --progress-candidate-step: $progress_candidate_step (must be >= 1)" >&2
  exit 1
fi

case "$ensemble_method" in
  median|mean) ;;
  *)
    echo "Invalid ensemble method: $ensemble_method (use median|mean)" >&2
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
build_dir="$repo_root/.derivedData/dev-tools/bot-training"
runner_main="$build_dir/main.swift"
runner_bin="$build_dir/bot_training_runner"

mkdir -p "$build_dir"

cat > "$runner_main" <<SWIFT
import Foundation
import Darwin

func fmt(_ value: Double) -> String {
    return String(format: "%.6f", value)
}

func fmtDuration(_ seconds: Double?) -> String {
    guard let seconds else { return "--:--:--" }
    let clamped = max(0, Int(seconds.rounded()))
    let h = clamped / 3600
    let m = (clamped % 3600) / 60
    let s = clamped % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

func average(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    return values.reduce(0.0, +) / Double(values.count)
}

func median(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count % 2 == 0 {
        return (sorted[mid - 1] + sorted[mid]) / 2.0
    }
    return sorted[mid]
}

func aggregate(_ values: [Double], method: String) -> Double {
    switch method {
    case "mean":
        return average(values)
    default:
        return median(values)
    }
}

func aggregateTunings(_ tunings: [BotTuning], method: String) -> BotTuning {
    guard let template = tunings.first else {
        return BotTuning(difficulty: .hard)
    }

    let holdWeight = aggregate(tunings.map { \$0.turnStrategy.holdFromDistributionWeight }, method: method)
    let clampedHoldWeight = min(max(holdWeight, 0.55), 0.97)
    let powerWeight = 1.0 - clampedHoldWeight

    let turn = BotTuning.TurnStrategy(
        utilityTieTolerance: template.turnStrategy.utilityTieTolerance,
        chaseWinProbabilityWeight: aggregate(tunings.map { \$0.turnStrategy.chaseWinProbabilityWeight }, method: method),
        chaseThreatPenaltyWeight: aggregate(tunings.map { \$0.turnStrategy.chaseThreatPenaltyWeight }, method: method),
        chaseSpendJokerPenalty: aggregate(tunings.map { \$0.turnStrategy.chaseSpendJokerPenalty }, method: method),
        chaseLeadWishBonus: template.turnStrategy.chaseLeadWishBonus,
        dumpAvoidWinWeight: aggregate(tunings.map { \$0.turnStrategy.dumpAvoidWinWeight }, method: method),
        dumpThreatRewardWeight: aggregate(tunings.map { \$0.turnStrategy.dumpThreatRewardWeight }, method: method),
        dumpSpendJokerPenalty: aggregate(tunings.map { \$0.turnStrategy.dumpSpendJokerPenalty }, method: method),
        dumpFaceUpNonLeadJokerPenalty: template.turnStrategy.dumpFaceUpNonLeadJokerPenalty,
        dumpLeadTakesNonTrumpBonus: template.turnStrategy.dumpLeadTakesNonTrumpBonus,
        holdFromDistributionWeight: clampedHoldWeight,
        powerConfidenceWeight: powerWeight,
        futureJokerPower: aggregate(tunings.map { \$0.turnStrategy.futureJokerPower }, method: method),
        futureRegularBasePower: template.turnStrategy.futureRegularBasePower,
        futureRegularRankWeight: template.turnStrategy.futureRegularRankWeight,
        futureTrumpBaseBonus: template.turnStrategy.futureTrumpBaseBonus,
        futureTrumpRankWeight: template.turnStrategy.futureTrumpRankWeight,
        futureHighRankBonus: template.turnStrategy.futureHighRankBonus,
        futureLongSuitBonusPerCard: template.turnStrategy.futureLongSuitBonusPerCard,
        futureTricksScale: aggregate(tunings.map { \$0.turnStrategy.futureTricksScale }, method: method),
        threatFaceDownLeadJoker: template.turnStrategy.threatFaceDownLeadJoker,
        threatFaceDownNonLeadJoker: template.turnStrategy.threatFaceDownNonLeadJoker,
        threatLeadTakesJoker: template.turnStrategy.threatLeadTakesJoker,
        threatLeadAboveJoker: template.turnStrategy.threatLeadAboveJoker,
        threatLeadWishJoker: template.turnStrategy.threatLeadWishJoker,
        threatNonLeadFaceUpJoker: template.turnStrategy.threatNonLeadFaceUpJoker,
        threatTrumpBonus: aggregate(tunings.map { \$0.turnStrategy.threatTrumpBonus }, method: method),
        threatHighRankBonus: aggregate(tunings.map { \$0.turnStrategy.threatHighRankBonus }, method: method),
        powerFaceDownJoker: template.turnStrategy.powerFaceDownJoker,
        powerLeadTakesJoker: template.turnStrategy.powerLeadTakesJoker,
        powerLeadAboveJoker: template.turnStrategy.powerLeadAboveJoker,
        powerLeadWishJoker: template.turnStrategy.powerLeadWishJoker,
        powerNonLeadFaceUpJoker: template.turnStrategy.powerNonLeadFaceUpJoker,
        powerTrumpBonus: template.turnStrategy.powerTrumpBonus,
        powerLeadSuitBonus: template.turnStrategy.powerLeadSuitBonus,
        powerNormalizationValue: template.turnStrategy.powerNormalizationValue
    )

    let bidding = BotTuning.Bidding(
        expectedJokerPower: aggregate(tunings.map { \$0.bidding.expectedJokerPower }, method: method),
        expectedRankWeight: aggregate(tunings.map { \$0.bidding.expectedRankWeight }, method: method),
        expectedTrumpBaseBonus: aggregate(tunings.map { \$0.bidding.expectedTrumpBaseBonus }, method: method),
        expectedTrumpRankWeight: aggregate(tunings.map { \$0.bidding.expectedTrumpRankWeight }, method: method),
        expectedHighRankBonus: aggregate(tunings.map { \$0.bidding.expectedHighRankBonus }, method: method),
        expectedLongSuitBonusPerCard: aggregate(tunings.map { \$0.bidding.expectedLongSuitBonusPerCard }, method: method),
        expectedTrumpDensityBonus: aggregate(tunings.map { \$0.bidding.expectedTrumpDensityBonus }, method: method),
        expectedNoTrumpHighCardBonus: aggregate(tunings.map { \$0.bidding.expectedNoTrumpHighCardBonus }, method: method),
        expectedNoTrumpJokerSynergy: aggregate(tunings.map { \$0.bidding.expectedNoTrumpJokerSynergy }, method: method),
        blindDesperateBehindThreshold: template.bidding.blindDesperateBehindThreshold,
        blindCatchUpBehindThreshold: template.bidding.blindCatchUpBehindThreshold,
        blindSafeLeadThreshold: template.bidding.blindSafeLeadThreshold,
        blindDesperateTargetShare: template.bidding.blindDesperateTargetShare,
        blindCatchUpTargetShare: template.bidding.blindCatchUpTargetShare
    )

    let trumpSelection = BotTuning.TrumpSelection(
        cardBasePower: aggregate(tunings.map { \$0.trumpSelection.cardBasePower }, method: method),
        minimumPowerToDeclareTrump: aggregate(tunings.map { \$0.trumpSelection.minimumPowerToDeclareTrump }, method: method)
    )

    return BotTuning(
        difficulty: template.difficulty,
        turnStrategy: turn,
        bidding: bidding,
        trumpSelection: trumpSelection,
        timing: template.timing
    )
}

let baseDifficulty = BotDifficulty(rawValue: "$difficulty") ?? .hard
let baseTuning = BotTuning(difficulty: baseDifficulty)
let config = BotTuning.SelfPlayEvolutionConfig(
    populationSize: $population_size,
    generations: $generations,
    gamesPerCandidate: $games_per_candidate,
    roundsPerGame: $rounds_per_game,
    playerCount: $player_count,
    cardsPerRoundRange: $cards_min...$cards_max,
    eliteCount: $elite_count,
    mutationChance: $mutation_chance,
    mutationMagnitude: $mutation_magnitude,
    selectionPoolRatio: $selection_pool_ratio,
    useFullMatchRules: $use_full_match_rules,
    rotateCandidateAcrossSeats: $rotate_candidate_across_seats,
    fitnessWinRateWeight: $fitness_win_rate_weight,
    fitnessScoreDiffWeight: $fitness_score_diff_weight,
    fitnessUnderbidLossWeight: $fitness_underbid_loss_weight,
    fitnessTrumpDensityUnderbidWeight: $fitness_trump_density_underbid_weight,
    fitnessNoTrumpControlUnderbidWeight: $fitness_notrump_control_underbid_weight,
    fitnessPremiumAssistWeight: $fitness_premium_assist_weight,
    fitnessPremiumPenaltyTargetWeight: $fitness_premium_penalty_target_weight,
    scoreDiffNormalization: $score_diff_normalization,
    underbidLossNormalization: $underbid_loss_normalization,
    trumpDensityUnderbidNormalization: $trump_density_underbid_normalization,
    noTrumpControlUnderbidNormalization: $notrump_control_underbid_normalization,
    premiumAssistNormalization: $premium_assist_normalization,
    premiumPenaltyTargetNormalization: $premium_penalty_target_normalization
)

let seed: UInt64 = $seed
let seedListRaw = "$seed_list"
let ensembleMethod = "$ensemble_method"
let showProgress = $show_progress
let progressCandidateStep = max(1, $progress_candidate_step)
let parsedSeedList: [UInt64] = seedListRaw
    .split(separator: ",")
    .compactMap { UInt64(\$0) }
let runSeeds: [UInt64] = parsedSeedList.isEmpty ? [seed] : parsedSeedList

struct SeedRun {
    let seed: UInt64
    let result: BotTuning.SelfPlayEvolutionResult
}

func logProgress(
    seed: UInt64,
    event: BotTuning.SelfPlayEvolutionProgress,
    candidateStep: Int
) {
    switch event.stage {
    case .started:
        print(
            "[progress] seed=\\(seed) started " +
            "work=\\(event.totalWorkUnits) units"
        )
    case .baselineCompleted:
        print(
            "[progress] seed=\\(seed) baseline " +
            "fitness=\\(fmt(event.currentFitness ?? 0.0)) " +
            "elapsed=\\(fmtDuration(event.elapsedSeconds)) " +
            "eta=\\(fmtDuration(event.estimatedRemainingSeconds))"
        )
    case .generationStarted:
        let generation = (event.generationIndex ?? 0) + 1
        print(
            "[progress] seed=\\(seed) generation " +
            "\\(generation)/\\(event.totalGenerations) started"
        )
    case .candidateEvaluated:
        let generation = (event.generationIndex ?? 0) + 1
        let candidate = event.evaluatedCandidatesInGeneration ?? 0
        let shouldPrint = candidate == 1 ||
            candidate == event.populationSize ||
            (candidate % candidateStep == 0)
        guard shouldPrint else { return }
        print(
            "[progress] seed=\\(seed) g=\\(generation)/\\(event.totalGenerations) " +
            "candidate=\\(candidate)/\\(event.populationSize) " +
            "fitness=\\(fmt(event.currentFitness ?? 0.0)) " +
            "genBest=\\(fmt(event.generationBestFitness ?? 0.0)) " +
            "overallBest=\\(fmt(event.overallBestFitness ?? 0.0)) " +
            "elapsed=\\(fmtDuration(event.elapsedSeconds)) " +
            "eta=\\(fmtDuration(event.estimatedRemainingSeconds))"
        )
    case .generationCompleted:
        let generation = (event.generationIndex ?? 0) + 1
        print(
            "[progress] seed=\\(seed) generation " +
            "\\(generation)/\\(event.totalGenerations) done " +
            "genBest=\\(fmt(event.generationBestFitness ?? 0.0)) " +
            "overallBest=\\(fmt(event.overallBestFitness ?? 0.0)) " +
            "elapsed=\\(fmtDuration(event.elapsedSeconds)) " +
            "eta=\\(fmtDuration(event.estimatedRemainingSeconds))"
        )
    case .finished:
        print(
            "[progress] seed=\\(seed) finished " +
            "overallBest=\\(fmt(event.overallBestFitness ?? 0.0)) " +
            "elapsed=\\(fmtDuration(event.elapsedSeconds))"
        )
    }
    fflush(stdout)
}

let seedRuns: [SeedRun] = runSeeds.map { runSeed in
    let runResult = BotTuning.evolveViaSelfPlay(
        baseTuning: baseTuning,
        config: config,
        seed: runSeed,
        progress: showProgress
            ? { event in
                logProgress(seed: runSeed, event: event, candidateStep: progressCandidateStep)
            }
            : nil
    )
    return SeedRun(seed: runSeed, result: runResult)
}

guard let selectedRun = seedRuns.max(by: { \$0.result.bestFitness < \$1.result.bestFitness }) else {
    fatalError("Failed to run self-play evolution")
}

let tunedForOutput: BotTuning
if seedRuns.count > 1 {
    tunedForOutput = aggregateTunings(seedRuns.map { \$0.result.bestTuning }, method: ensembleMethod)
} else {
    tunedForOutput = selectedRun.result.bestTuning
}

let turn = tunedForOutput.turnStrategy
let bidding = tunedForOutput.bidding
let trump = tunedForOutput.trumpSelection

print("=== Bot Self-Play Training ===")
print("difficulty=\\(baseDifficulty.rawValue)")
if seedRuns.count == 1 {
    print("seed=\\(selectedRun.seed)")
} else {
    print("seedList=[\\(runSeeds.map(String.init).joined(separator: ", "))]")
    print("ensembleMethod=\\(ensembleMethod)")
    print("ensembleRuns=\\(seedRuns.count)")
}
print("useFullMatchRules=\\(config.useFullMatchRules)")
print("rotateCandidateAcrossSeats=\\(config.rotateCandidateAcrossSeats)")
print("fitnessWinRateWeight=\\(fmt(config.fitnessWinRateWeight))")
print("fitnessScoreDiffWeight=\\(fmt(config.fitnessScoreDiffWeight))")
print("fitnessUnderbidLossWeight=\\(fmt(config.fitnessUnderbidLossWeight))")
print("fitnessTrumpDensityUnderbidWeight=\\(fmt(config.fitnessTrumpDensityUnderbidWeight))")
print("fitnessNoTrumpControlUnderbidWeight=\\(fmt(config.fitnessNoTrumpControlUnderbidWeight))")
print("fitnessPremiumAssistWeight=\\(fmt(config.fitnessPremiumAssistWeight))")
print("fitnessPremiumPenaltyTargetWeight=\\(fmt(config.fitnessPremiumPenaltyTargetWeight))")
print("scoreDiffNormalization=\\(fmt(config.scoreDiffNormalization))")
print("underbidLossNormalization=\\(fmt(config.underbidLossNormalization))")
print("trumpDensityUnderbidNormalization=\\(fmt(config.trumpDensityUnderbidNormalization))")
print("noTrumpControlUnderbidNormalization=\\(fmt(config.noTrumpControlUnderbidNormalization))")
print("premiumAssistNormalization=\\(fmt(config.premiumAssistNormalization))")
print("premiumPenaltyTargetNormalization=\\(fmt(config.premiumPenaltyTargetNormalization))")
print("showProgress=\\(showProgress)")
print("progressCandidateStep=\\(progressCandidateStep)")
if seedRuns.count > 1 {
    let perSeedFitness = seedRuns.map { "\\(\$0.seed):\\(fmt(\$0.result.bestFitness))" }.joined(separator: ", ")
    print("perSeedBestFitness=[\\(perSeedFitness)]")
    print("ensembleAverageBestFitness=\\(fmt(average(seedRuns.map { \$0.result.bestFitness })))")
    print("ensembleAverageBestWinRate=\\(fmt(average(seedRuns.map { \$0.result.bestWinRate })))")
    print("ensembleAverageBestScoreDiff=\\(fmt(average(seedRuns.map { \$0.result.bestAverageScoreDiff })))")
    print("ensembleAverageBestUnderbidLoss=\\(fmt(average(seedRuns.map { \$0.result.bestAverageUnderbidLoss })))")
    print("ensembleAverageBestTrumpDensityUnderbidLoss=\\(fmt(average(seedRuns.map { \$0.result.bestAverageTrumpDensityUnderbidLoss })))")
    print("ensembleAverageBestNoTrumpControlUnderbidLoss=\\(fmt(average(seedRuns.map { \$0.result.bestAverageNoTrumpControlUnderbidLoss })))")
    print("ensembleAverageBestPremiumAssistLoss=\\(fmt(average(seedRuns.map { \$0.result.bestAveragePremiumAssistLoss })))")
    print("ensembleAverageBestPremiumPenaltyTargetLoss=\\(fmt(average(seedRuns.map { \$0.result.bestAveragePremiumPenaltyTargetLoss })))")
}
print("selectedSeed=\\(selectedRun.seed)")
print("baselineFitness=\\(fmt(selectedRun.result.baselineFitness))")
print("bestFitness=\\(fmt(selectedRun.result.bestFitness))")
print("improvement=\\(fmt(selectedRun.result.improvement))")
print("baselineWinRate=\\(fmt(selectedRun.result.baselineWinRate))")
print("bestWinRate=\\(fmt(selectedRun.result.bestWinRate))")
print("baselineAverageScoreDiff=\\(fmt(selectedRun.result.baselineAverageScoreDiff))")
print("bestAverageScoreDiff=\\(fmt(selectedRun.result.bestAverageScoreDiff))")
print("baselineAverageUnderbidLoss=\\(fmt(selectedRun.result.baselineAverageUnderbidLoss))")
print("bestAverageUnderbidLoss=\\(fmt(selectedRun.result.bestAverageUnderbidLoss))")
print("baselineAverageTrumpDensityUnderbidLoss=\\(fmt(selectedRun.result.baselineAverageTrumpDensityUnderbidLoss))")
print("bestAverageTrumpDensityUnderbidLoss=\\(fmt(selectedRun.result.bestAverageTrumpDensityUnderbidLoss))")
print("baselineAverageNoTrumpControlUnderbidLoss=\\(fmt(selectedRun.result.baselineAverageNoTrumpControlUnderbidLoss))")
print("bestAverageNoTrumpControlUnderbidLoss=\\(fmt(selectedRun.result.bestAverageNoTrumpControlUnderbidLoss))")
print("baselineAveragePremiumAssistLoss=\\(fmt(selectedRun.result.baselineAveragePremiumAssistLoss))")
print("bestAveragePremiumAssistLoss=\\(fmt(selectedRun.result.bestAveragePremiumAssistLoss))")
print("baselineAveragePremiumPenaltyTargetLoss=\\(fmt(selectedRun.result.baselineAveragePremiumPenaltyTargetLoss))")
print("bestAveragePremiumPenaltyTargetLoss=\\(fmt(selectedRun.result.bestAveragePremiumPenaltyTargetLoss))")
print("generationBestFitness=[\\(selectedRun.result.generationBestFitness.map(fmt).joined(separator: ", "))]")
print("")
print("=== Suggested Tuned Values ===")
print("turnStrategy.chaseWinProbabilityWeight=\\(fmt(turn.chaseWinProbabilityWeight))")
print("turnStrategy.chaseThreatPenaltyWeight=\\(fmt(turn.chaseThreatPenaltyWeight))")
print("turnStrategy.chaseSpendJokerPenalty=\\(fmt(turn.chaseSpendJokerPenalty))")
print("turnStrategy.dumpAvoidWinWeight=\\(fmt(turn.dumpAvoidWinWeight))")
print("turnStrategy.dumpThreatRewardWeight=\\(fmt(turn.dumpThreatRewardWeight))")
print("turnStrategy.dumpSpendJokerPenalty=\\(fmt(turn.dumpSpendJokerPenalty))")
print("turnStrategy.holdFromDistributionWeight=\\(fmt(turn.holdFromDistributionWeight))")
print("turnStrategy.powerConfidenceWeight=\\(fmt(turn.powerConfidenceWeight))")
print("turnStrategy.futureJokerPower=\\(fmt(turn.futureJokerPower))")
print("turnStrategy.futureTricksScale=\\(fmt(turn.futureTricksScale))")
print("turnStrategy.threatTrumpBonus=\\(fmt(turn.threatTrumpBonus))")
print("turnStrategy.threatHighRankBonus=\\(fmt(turn.threatHighRankBonus))")
print("bidding.expectedJokerPower=\\(fmt(bidding.expectedJokerPower))")
print("bidding.expectedRankWeight=\\(fmt(bidding.expectedRankWeight))")
print("bidding.expectedTrumpBaseBonus=\\(fmt(bidding.expectedTrumpBaseBonus))")
print("bidding.expectedTrumpRankWeight=\\(fmt(bidding.expectedTrumpRankWeight))")
print("bidding.expectedHighRankBonus=\\(fmt(bidding.expectedHighRankBonus))")
print("bidding.expectedLongSuitBonusPerCard=\\(fmt(bidding.expectedLongSuitBonusPerCard))")
print("bidding.expectedTrumpDensityBonus=\\(fmt(bidding.expectedTrumpDensityBonus))")
print("bidding.expectedNoTrumpHighCardBonus=\\(fmt(bidding.expectedNoTrumpHighCardBonus))")
print("bidding.expectedNoTrumpJokerSynergy=\\(fmt(bidding.expectedNoTrumpJokerSynergy))")
print("trumpSelection.cardBasePower=\\(fmt(trump.cardBasePower))")
print("trumpSelection.minimumPowerToDeclareTrump=\\(fmt(trump.minimumPowerToDeclareTrump))")
SWIFT

swift_sources=(
  "$runner_main"
  "$repo_root/Jocker/Jocker/Core/GameColors.swift"
  "$repo_root/Jocker/Jocker/Models/Cards/CardColor.swift"
  "$repo_root/Jocker/Jocker/Models/Cards/Suit.swift"
  "$repo_root/Jocker/Jocker/Models/Cards/Rank.swift"
  "$repo_root/Jocker/Jocker/Models/Cards/Card.swift"
  "$repo_root/Jocker/Jocker/Models/Cards/Deck.swift"
  "$repo_root/Jocker/Jocker/Models/Joker/PlayedTrickCard.swift"
  "$repo_root/Jocker/Jocker/Models/Joker/JokerLeadDeclaration.swift"
  "$repo_root/Jocker/Jocker/Models/Joker/JokerPlayStyle.swift"
  "$repo_root/Jocker/Jocker/Models/Joker/JokerPlayDecision.swift"
  "$repo_root/Jocker/Jocker/Models/Gameplay/GameBlock.swift"
  "$repo_root/Jocker/Jocker/Models/Gameplay/GameConstants.swift"
  "$repo_root/Jocker/Jocker/Models/Gameplay/TrickTakingResolver.swift"
  "$repo_root/Jocker/Jocker/Models/Bot/BotDifficulty.swift"
  "$repo_root/Jocker/Jocker/Models/Bot/BotTuning.swift"
  "$repo_root/Jocker/Jocker/Models/Gameplay/RoundResult.swift"
  "$repo_root/Jocker/Jocker/Scoring/ScoreCalculator.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/CardNode.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/TrickNode.swift"
  "$repo_root/Jocker/Jocker/Game/Services/AI/BotBiddingService.swift"
  "$repo_root/Jocker/Jocker/Game/Services/AI/BotTrumpSelectionService.swift"
  "$repo_root/Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift"
)

echo "Compiling bot training runner..."
swiftc -O "${swift_sources[@]}" -o "$runner_bin"

echo "Running self-play evolution..."
if [[ -n "$output_path" ]]; then
  output_dir="$(dirname "$output_path")"
  mkdir -p "$output_dir"
  "$runner_bin" | tee "$output_path"
  echo "Saved run log to: $output_path"
else
  "$runner_bin"
fi
