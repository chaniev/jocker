#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_bot_baseline_snapshot.sh [параметры] [-- <доп. аргументы train_bot_tuning.sh>]

Назначение:
  Stage 0 baseline harness для AI-метрик.
  Запускает `scripts/train_bot_tuning.sh` в режиме baseline-only (`--run-mode baselineOnly`)
  на фиксированных seed и сохраняет артефакты прогона (лог, точную команду, summary, извлеченные метрики)
  в отдельную папку.

Важно:
  - По умолчанию baseline собирается без A/B валидации (`--ab-validate false`).
  - Для multi-seed baseline используются `ensembleAverageBest*` метрики из `train_bot_tuning.sh`.
    При `--run-mode baselineOnly` это эквивалент baseline-метрикам по seed-list.
  - Расширенные Stage-0 операционные метрики (`premiumCaptureRate`, `blindSuccessRate`, и т.п.)
    этим harness пока не собираются — сохраняются только доступные self-play baseline метрики.

Параметры:
  --profile <baseline-v1|smoke>   Профиль запуска (по умолчанию: baseline-v1)
  --difficulty <easy|normal|hard> Базовый пресет (по умолчанию: hard)
  --seed-list <a,b,c>             Явный seed-list (переопределяет профиль)
  --games-per-candidate <int>     Переопределить число игр на seed
  --rounds-per-game <int>         Переопределить rounds-per-game
  --show-progress <true|false>    Прокинуть в train script (по умолчанию: false)
  --ab-validate <true|false>      Прокинуть в train script (по умолчанию: false)
  --output-root <path>            Корневая папка артефактов
                                  (по умолчанию: .derivedData/bot-baseline-runs)
  --train-script <path>           Путь к scripts/train_bot_tuning.sh
                                  (по умолчанию: scripts/train_bot_tuning.sh)
  --list-config                   Показать итоговую конфигурацию и выйти
  --dry-run                       Напечатать команду запуска и выйти
  -h, --help                      Показать справку

Примеры:
  scripts/run_bot_baseline_snapshot.sh --list-config
  scripts/run_bot_baseline_snapshot.sh --profile smoke
  scripts/run_bot_baseline_snapshot.sh --profile baseline-v1 --show-progress true
  scripts/run_bot_baseline_snapshot.sh --seed-list 20260220,20260221 --games-per-candidate 4 -- --fitness-underbid-loss-weight 0.85
EOF
}

require_value() {
  local value="$1"
  local flag="$2"
  if [[ -z "$value" ]]; then
    echo "Missing value for $flag" >&2
    exit 1
  fi
}

require_int() {
  local value="$1"
  local flag="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Invalid integer for $flag: $value" >&2
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

resolve_abs_path() {
  local path="$1"
  local root="$2"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$root" "$path"
  fi
}

extract_metric() {
  local key="$1"
  local file="$2"
  local line
  line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    return 1
  fi
  printf '%s\n' "${line#*=}"
}

profile="baseline-v1"
difficulty="hard"
seed_list=""
games_per_candidate=""
rounds_per_game=""
show_progress="false"
ab_validate="false"
output_root=".derivedData/bot-baseline-runs"
train_script_path="scripts/train_bot_tuning.sh"
list_config=false
dry_run=false
extra_train_args=()

while (($# > 0)); do
  case "$1" in
    --profile)
      profile="${2:-}"
      require_value "$profile" "--profile"
      shift 2
      ;;
    --difficulty)
      difficulty="${2:-}"
      require_value "$difficulty" "--difficulty"
      shift 2
      ;;
    --seed-list)
      seed_list="${2:-}"
      require_value "$seed_list" "--seed-list"
      shift 2
      ;;
    --games-per-candidate)
      games_per_candidate="${2:-}"
      require_value "$games_per_candidate" "--games-per-candidate"
      shift 2
      ;;
    --rounds-per-game)
      rounds_per_game="${2:-}"
      require_value "$rounds_per_game" "--rounds-per-game"
      shift 2
      ;;
    --show-progress)
      show_progress="${2:-}"
      require_value "$show_progress" "--show-progress"
      shift 2
      ;;
    --ab-validate)
      ab_validate="${2:-}"
      require_value "$ab_validate" "--ab-validate"
      shift 2
      ;;
    --output-root)
      output_root="${2:-}"
      require_value "$output_root" "--output-root"
      shift 2
      ;;
    --train-script)
      train_script_path="${2:-}"
      require_value "$train_script_path" "--train-script"
      shift 2
      ;;
    --list-config)
      list_config=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --)
      shift
      extra_train_args+=("$@")
      break
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

case "$profile" in
  baseline-v1)
    profile_seed_list="20260220,20260221,20260222,20260223,20260224,20260225"
    profile_games_per_candidate="8"
    profile_rounds_per_game="24"
    ;;
  smoke)
    profile_seed_list="20260220,20260221"
    profile_games_per_candidate="2"
    profile_rounds_per_game="12"
    ;;
  *)
    echo "Unknown profile: $profile (use baseline-v1|smoke)" >&2
    exit 1
    ;;
esac

seed_list="${seed_list:-$profile_seed_list}"
games_per_candidate="${games_per_candidate:-$profile_games_per_candidate}"
rounds_per_game="${rounds_per_game:-$profile_rounds_per_game}"

require_seed_list "$seed_list" "--seed-list"
require_int "$games_per_candidate" "--games-per-candidate"
require_int "$rounds_per_game" "--rounds-per-game"
require_bool "$show_progress" "--show-progress"
require_bool "$ab_validate" "--ab-validate"

case "$difficulty" in
  easy|normal|hard) ;;
  *)
    echo "Invalid difficulty: $difficulty (use easy|normal|hard)" >&2
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
train_script_abs="$(resolve_abs_path "$train_script_path" "$repo_root")"
output_root_abs="$(resolve_abs_path "$output_root" "$repo_root")"
if [[ ! -f "$train_script_abs" ]]; then
  echo "train_bot_tuning.sh not found: $train_script_abs" >&2
  exit 1
fi

if [[ ! -x "$train_script_abs" ]]; then
  echo "train_bot_tuning.sh is not executable: $train_script_abs" >&2
  exit 1
fi

timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
log_path="$run_dir/train_bot_tuning.log"
summary_path="$run_dir/summary.txt"
metrics_path="$run_dir/baseline-metrics.txt"
command_path="$run_dir/command.txt"
sandbox_home="$run_dir/sandbox-home"
module_cache_dir="$sandbox_home/.cache/clang/ModuleCache"
start_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

cmd=(
  "$train_script_abs"
  --difficulty "$difficulty"
  --seed-list "$seed_list"
  --run-mode baselineOnly
  --population-size 2
  --elite-count 1
  --games-per-candidate "$games_per_candidate"
  --rounds-per-game "$rounds_per_game"
  --player-count 4
  --cards-min 1
  --cards-max 9
  --use-full-match-rules true
  --rotate-candidate-across-seats true
  --show-progress "$show_progress"
  --ab-validate "$ab_validate"
  --output "$log_path"
)

if ((${#extra_train_args[@]} > 0)); then
  cmd+=("${extra_train_args[@]}")
fi

print_config() {
  echo "profile=$profile"
  echo "difficulty=$difficulty"
  echo "seed_list=$seed_list"
  echo "games_per_candidate=$games_per_candidate"
  echo "rounds_per_game=$rounds_per_game"
  echo "show_progress=$show_progress"
  echo "ab_validate=$ab_validate"
  echo "output_root=$output_root_abs"
  echo "train_script=$train_script_abs"
  echo "extra_train_args_count=${#extra_train_args[@]}"
}

if [[ "$list_config" == true ]]; then
  print_config
  exit 0
fi

mkdir -p "$run_dir"
mkdir -p "$module_cache_dir"

{
  printf 'Command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'
} > "$command_path"

if [[ "$dry_run" == true ]]; then
  echo "=== Stage 0 Baseline Snapshot (dry-run) ==="
  print_config
  cat "$command_path"
  echo "artifacts_dir=$run_dir"
  exit 0
fi

echo "=== Stage 0 Baseline Snapshot ==="
echo "Profile: $profile"
echo "Difficulty: $difficulty"
echo "Seeds: $seed_list"
echo "Games per candidate: $games_per_candidate"
echo "Rounds per game: $rounds_per_game"
echo "Artifacts dir: $run_dir"
echo "Command file: $command_path"

set +e
HOME="$sandbox_home" \
CLANG_MODULE_CACHE_PATH="$module_cache_dir" \
SWIFT_MODULECACHE_PATH="$module_cache_dir" \
"${cmd[@]}"
run_exit_code=$?
set -e

end_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
status="failed"
if [[ "$run_exit_code" -eq 0 ]]; then
  status="passed"
fi

metric_source="baseline(single-seed)"
if grep -q '^seedList=\[' "$log_path" 2>/dev/null; then
  metric_source="ensembleAverageBest (baselineOnly => baseline multi-seed aggregate)"
fi

metric_or_empty() {
  local key="$1"
  local path="$2"
  extract_metric "$key" "$path" 2>/dev/null || true
}

run_mode="$(metric_or_empty 'mode' "$log_path")"
generation_count="$(metric_or_empty 'generationCount' "$log_path")"
baseline_win_rate="$(metric_or_empty 'ensembleAverageBestWinRate' "$log_path")"
baseline_score_diff="$(metric_or_empty 'ensembleAverageBestScoreDiff' "$log_path")"
baseline_underbid_loss="$(metric_or_empty 'ensembleAverageBestUnderbidLoss' "$log_path")"
baseline_premium_assist_loss="$(metric_or_empty 'ensembleAverageBestPremiumAssistLoss' "$log_path")"
baseline_premium_penalty_target_loss="$(metric_or_empty 'ensembleAverageBestPremiumPenaltyTargetLoss' "$log_path")"
baseline_premium_capture_rate="$(metric_or_empty 'ensembleAverageBestPremiumCaptureRate' "$log_path")"
baseline_blind_success_rate="$(metric_or_empty 'ensembleAverageBestBlindSuccessRate' "$log_path")"
baseline_joker_wish_win_rate="$(metric_or_empty 'ensembleAverageBestJokerWishWinRate' "$log_path")"
baseline_early_joker_spend_rate="$(metric_or_empty 'ensembleAverageBestEarlyJokerSpendRate' "$log_path")"
baseline_penalty_target_rate="$(metric_or_empty 'ensembleAverageBestPenaltyTargetRate' "$log_path")"
baseline_bid_accuracy_rate="$(metric_or_empty 'ensembleAverageBestBidAccuracyRate' "$log_path")"
baseline_overbid_rate="$(metric_or_empty 'ensembleAverageBestOverbidRate' "$log_path")"
baseline_blind_bid_rate_block4="$(metric_or_empty 'ensembleAverageBestBlindBidRateBlock4' "$log_path")"
baseline_average_blind_bid_size="$(metric_or_empty 'ensembleAverageBestAverageBlindBidSize' "$log_path")"
baseline_blind_bid_when_behind_rate="$(metric_or_empty 'ensembleAverageBestBlindBidWhenBehindRate' "$log_path")"
baseline_blind_bid_when_leading_rate="$(metric_or_empty 'ensembleAverageBestBlindBidWhenLeadingRate' "$log_path")"
baseline_early_lead_wish_joker_rate="$(metric_or_empty 'ensembleAverageBestEarlyLeadWishJokerRate' "$log_path")"
baseline_left_neighbor_premium_assist_rate="$(metric_or_empty 'ensembleAverageBestLeftNeighborPremiumAssistRate' "$log_path")"

if [[ -z "$baseline_win_rate" ]]; then
  metric_source="baseline(single-seed)"
  baseline_win_rate="$(metric_or_empty 'baselineWinRate' "$log_path")"
  baseline_score_diff="$(metric_or_empty 'baselineAverageScoreDiff' "$log_path")"
  baseline_underbid_loss="$(metric_or_empty 'baselineAverageUnderbidLoss' "$log_path")"
  baseline_premium_assist_loss="$(metric_or_empty 'baselineAveragePremiumAssistLoss' "$log_path")"
  baseline_premium_penalty_target_loss="$(metric_or_empty 'baselineAveragePremiumPenaltyTargetLoss' "$log_path")"
  baseline_premium_capture_rate="$(metric_or_empty 'baselinePremiumCaptureRate' "$log_path")"
  baseline_blind_success_rate="$(metric_or_empty 'baselineBlindSuccessRate' "$log_path")"
  baseline_joker_wish_win_rate="$(metric_or_empty 'baselineJokerWishWinRate' "$log_path")"
  baseline_early_joker_spend_rate="$(metric_or_empty 'baselineEarlyJokerSpendRate' "$log_path")"
  baseline_penalty_target_rate="$(metric_or_empty 'baselinePenaltyTargetRate' "$log_path")"
  baseline_bid_accuracy_rate="$(metric_or_empty 'baselineBidAccuracyRate' "$log_path")"
  baseline_overbid_rate="$(metric_or_empty 'baselineOverbidRate' "$log_path")"
  baseline_blind_bid_rate_block4="$(metric_or_empty 'baselineBlindBidRateBlock4' "$log_path")"
  baseline_average_blind_bid_size="$(metric_or_empty 'baselineAverageBlindBidSize' "$log_path")"
  baseline_blind_bid_when_behind_rate="$(metric_or_empty 'baselineBlindBidWhenBehindRate' "$log_path")"
  baseline_blind_bid_when_leading_rate="$(metric_or_empty 'baselineBlindBidWhenLeadingRate' "$log_path")"
  baseline_early_lead_wish_joker_rate="$(metric_or_empty 'baselineEarlyLeadWishJokerRate' "$log_path")"
  baseline_left_neighbor_premium_assist_rate="$(metric_or_empty 'baselineLeftNeighborPremiumAssistRate' "$log_path")"
fi

{
  echo "status=$status"
  echo "mode=${run_mode:-}"
  echo "generationCount=${generation_count:-}"
  echo "metric_source=$metric_source"
  echo "winRate=${baseline_win_rate:-}"
  echo "averageScoreDiff=${baseline_score_diff:-}"
  echo "averageUnderbidLoss=${baseline_underbid_loss:-}"
  echo "averagePremiumAssistLoss=${baseline_premium_assist_loss:-}"
  echo "averagePremiumPenaltyTargetLoss=${baseline_premium_penalty_target_loss:-}"
  echo "premiumCaptureRate=${baseline_premium_capture_rate:-}"
  echo "blindSuccessRate=${baseline_blind_success_rate:-}"
  echo "jokerWishWinRate=${baseline_joker_wish_win_rate:-}"
  echo "earlyJokerSpendRate=${baseline_early_joker_spend_rate:-}"
  echo "penaltyTargetRate=${baseline_penalty_target_rate:-}"
  echo "bidAccuracyRate=${baseline_bid_accuracy_rate:-}"
  echo "overbidRate=${baseline_overbid_rate:-}"
  echo "blindBidRateBlock4=${baseline_blind_bid_rate_block4:-}"
  echo "averageBlindBidSize=${baseline_average_blind_bid_size:-}"
  echo "blindBidWhenBehindRate=${baseline_blind_bid_when_behind_rate:-}"
  echo "blindBidWhenLeadingRate=${baseline_blind_bid_when_leading_rate:-}"
  echo "earlyLeadWishJokerRate=${baseline_early_lead_wish_joker_rate:-}"
  echo "leftNeighborPremiumAssistRate=${baseline_left_neighbor_premium_assist_rate:-}"
  echo "supported_metrics=winRate,averageScoreDiff,averageUnderbidLoss,averagePremiumAssistLoss,averagePremiumPenaltyTargetLoss,premiumCaptureRate,blindSuccessRate,jokerWishWinRate,earlyJokerSpendRate,penaltyTargetRate,bidAccuracyRate,overbidRate,blindBidRateBlock4,averageBlindBidSize,blindBidWhenBehindRate,blindBidWhenLeadingRate,earlyLeadWishJokerRate,leftNeighborPremiumAssistRate"
  echo "pending_stage0_metrics="
} > "$metrics_path"

cat > "$summary_path" <<EOF
status=$status
exit_code=$run_exit_code
started_at_utc=$start_iso
finished_at_utc=$end_iso
profile=$profile
difficulty=$difficulty
seed_list=$seed_list
games_per_candidate=$games_per_candidate
rounds_per_game=$rounds_per_game
run_mode=${run_mode:-}
generation_count=${generation_count:-}
show_progress=$show_progress
ab_validate=$ab_validate
train_script=$train_script_abs
artifacts_dir=$run_dir
command_file=$command_path
log_file=$log_path
metrics_file=$metrics_path
sandbox_home=$sandbox_home
clang_module_cache_path=$module_cache_dir
EOF

echo "=== Baseline snapshot finished ($status) ==="
echo "Summary: $summary_path"
echo "Metrics: $metrics_path"
echo "Log: $log_path"

exit "$run_exit_code"
