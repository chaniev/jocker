#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/train_bot_tuning.sh [options]

Runs BotTuning self-play evolution in a standalone dev workflow.

Options:
  --difficulty <easy|normal|hard>   Base preset to evolve (default: hard)
  --seed <uint64>                   RNG seed (default: 20260220)
  --population-size <int>           Population size (default: 12)
  --generations <int>               Number of generations (default: 10)
  --games-per-candidate <int>       Self-play games per candidate (default: 20)
  --rounds-per-game <int>           Rounds per simulated game (default: 8)
  --player-count <int>              Player count in simulation (default: 4)
  --cards-min <int>                 Min cards per round (default: 2)
  --cards-max <int>                 Max cards per round (default: 9)
  --elite-count <int>               Number of elite candidates kept (default: 3)
  --mutation-chance <double>        Mutation chance [0..1] (default: 0.34)
  --mutation-magnitude <double>     Mutation magnitude (default: 0.16)
  --selection-pool-ratio <double>   Parent selection pool ratio (default: 0.55)
  --output <path>                   Optional output log file
  -h, --help                        Show this help

Examples:
  scripts/train_bot_tuning.sh
  scripts/train_bot_tuning.sh --seed 123456 --generations 14 --games-per-candidate 40
  scripts/train_bot_tuning.sh --difficulty normal --output .derivedData/bot-train.log
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
    selectionPoolRatio: $selection_pool_ratio
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
print("baselineFitness=\\(fmt(result.baselineFitness))")
print("bestFitness=\\(fmt(result.bestFitness))")
print("improvement=\\(fmt(result.improvement))")
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
  "$repo_root/Jocker/Jocker/Models/CardColor.swift"
  "$repo_root/Jocker/Jocker/Models/Suit.swift"
  "$repo_root/Jocker/Jocker/Models/Rank.swift"
  "$repo_root/Jocker/Jocker/Models/Card.swift"
  "$repo_root/Jocker/Jocker/Models/Deck.swift"
  "$repo_root/Jocker/Jocker/Models/PlayedTrickCard.swift"
  "$repo_root/Jocker/Jocker/Models/JokerLeadDeclaration.swift"
  "$repo_root/Jocker/Jocker/Models/JokerPlayStyle.swift"
  "$repo_root/Jocker/Jocker/Models/JokerPlayDecision.swift"
  "$repo_root/Jocker/Jocker/Models/TrickTakingResolver.swift"
  "$repo_root/Jocker/Jocker/Models/BotDifficulty.swift"
  "$repo_root/Jocker/Jocker/Models/BotTuning.swift"
  "$repo_root/Jocker/Jocker/Models/RoundResult.swift"
  "$repo_root/Jocker/Jocker/Scoring/ScoreCalculator.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/CardNode.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/TrickNode.swift"
  "$repo_root/Jocker/Jocker/Game/Services/BotBiddingService.swift"
  "$repo_root/Jocker/Jocker/Game/Services/BotTrumpSelectionService.swift"
  "$repo_root/Jocker/Jocker/Game/Services/BotTurnStrategyService.swift"
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
