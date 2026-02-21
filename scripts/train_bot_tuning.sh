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
  --score-diff-normalization <double>
                                     Делитель для компоненты разницы очков;
                                     больше значение = меньше вклад scoreDiff
                                     (по умолчанию: 450).
  --output <path>                   Путь для сохранения полного лога запуска.
  -h, --help                        Показать эту справку.

Примеры:
  scripts/train_bot_tuning.sh
  scripts/train_bot_tuning.sh --seed 123456 --generations 14 --games-per-candidate 40
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

difficulty="hard"
seed="20260220"
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
score_diff_normalization="450"
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
    --score-diff-normalization)
      score_diff_normalization="${2:-}"
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
require_double "$score_diff_normalization" "--score-diff-normalization"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
build_dir="$repo_root/.derivedData/dev-tools/bot-training"
runner_main="$build_dir/main.swift"
runner_bin="$build_dir/bot_training_runner"

mkdir -p "$build_dir"

cat > "$runner_main" <<SWIFT
import Foundation

func fmt(_ value: Double) -> String {
    return String(format: "%.6f", value)
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
    scoreDiffNormalization: $score_diff_normalization
)

let seed: UInt64 = $seed
let result = BotTuning.evolveViaSelfPlay(
    baseTuning: baseTuning,
    config: config,
    seed: seed
)

let turn = result.bestTuning.turnStrategy
let bidding = result.bestTuning.bidding
let trump = result.bestTuning.trumpSelection

print("=== Bot Self-Play Training ===")
print("difficulty=\\(baseDifficulty.rawValue)")
print("seed=\\(seed)")
print("useFullMatchRules=\\(config.useFullMatchRules)")
print("rotateCandidateAcrossSeats=\\(config.rotateCandidateAcrossSeats)")
print("fitnessWinRateWeight=\\(fmt(config.fitnessWinRateWeight))")
print("fitnessScoreDiffWeight=\\(fmt(config.fitnessScoreDiffWeight))")
print("scoreDiffNormalization=\\(fmt(config.scoreDiffNormalization))")
print("baselineFitness=\\(fmt(result.baselineFitness))")
print("bestFitness=\\(fmt(result.bestFitness))")
print("improvement=\\(fmt(result.improvement))")
print("baselineWinRate=\\(fmt(result.baselineWinRate))")
print("bestWinRate=\\(fmt(result.bestWinRate))")
print("baselineAverageScoreDiff=\\(fmt(result.baselineAverageScoreDiff))")
print("bestAverageScoreDiff=\\(fmt(result.bestAverageScoreDiff))")
print("generationBestFitness=[\\(result.generationBestFitness.map(fmt).joined(separator: ", "))]")
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
