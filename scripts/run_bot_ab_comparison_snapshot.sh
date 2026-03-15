#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_bot_ab_comparison_snapshot.sh [параметры] [-- <доп. аргументы train_bot_tuning.sh>]

Назначение:
  Stage 0 companion harness для воспроизводимого сравнения baseline vs candidate.
  Запускает `scripts/train_bot_tuning.sh` с фиксированным профилем обучения и включенной
  A/B валидацией (`A=basePreset`, `B=tunedOutput`), сохраняет артефакты прогона и
  извлекает ключевые summary-метрики A/B (primary/holdout).

Важно:
  - "candidate" в этом harness = `tunedOutput` из текущего training run.
  - Для `baseline vs candidate` таблицы используются `summary.mean ...` из секций
    `=== A/B Validation :: <label> ===`, где:
      * Baseline = `AvB` (A=basePreset против B=tunedOutput)
      * Candidate = `BvA` (B=tunedOutput против A=basePreset)
      * Delta = `Badv` (candidate advantage)

Параметры:
  --profile <compare-v1|medium|smoke>
                                    Профиль запуска (по умолчанию: compare-v1)
  --difficulty <easy|normal|hard>   Базовый пресет (по умолчанию: hard)
  --seed-list <a,b,c>               Seed-list обучения (переопределяет профиль)
  --holdout-seed-list <a,b,c>       Holdout seed-list для A/B (переопределяет профиль)
  --population-size <int>           Переопределить размер популяции
  --generations <int>               Переопределить число поколений
  --games-per-candidate <int>       Переопределить число игр на кандидата (training)
  --rounds-per-game <int>           Переопределить rounds-per-game
  --ab-validation-games-per-candidate <int>
                                    Переопределить games-per-candidate для A/B validation
  --show-progress <true|false>      Прокинуть в train script (по умолчанию: false)
  --output-root <path>              Корневая папка артефактов
                                    (по умолчанию: .derivedData/bot-ab-runs)
  --train-script <path>             Путь к scripts/train_bot_tuning.sh
                                    (по умолчанию: scripts/train_bot_tuning.sh)
  --list-config                     Показать итоговую конфигурацию и выйти
  --dry-run                         Напечатать команду запуска и выйти
  -h, --help                        Показать справку

Примеры:
  scripts/run_bot_ab_comparison_snapshot.sh --list-config
  scripts/run_bot_ab_comparison_snapshot.sh --profile smoke
  scripts/run_bot_ab_comparison_snapshot.sh --profile medium
  scripts/run_bot_ab_comparison_snapshot.sh --profile compare-v1 --show-progress true
  scripts/run_bot_ab_comparison_snapshot.sh --generations 6 --games-per-candidate 6 --ab-validation-games-per-candidate 4
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

extract_ab_section() {
  local label="$1"
  local source_file="$2"
  local output_file="$3"
  awk -v label="$label" '
    $0 == ("=== A/B Validation :: " label " ===") { in_section = 1; print; next }
    /^=== A\/B Validation :: / && in_section { exit }
    in_section { print }
  ' "$source_file" > "$output_file"
}

write_ab_metrics_file() {
  local label="$1"
  local section_file="$2"
  local metrics_file="$3"

  if [[ ! -s "$section_file" ]]; then
    {
      echo "available=false"
      echo "label=$label"
    } > "$metrics_file"
    return 0
  fi

  {
    echo "available=true"
    echo "label=$label"
    awk '
      /^summary\.mean / {
        metric = $2
        delete values
        for (i = 3; i <= NF; i++) {
          split($i, kv, "=")
          if (length(kv[1]) > 0 && length(kv[2]) > 0) {
            values[kv[1]] = kv[2]
            print metric "_" kv[1] "=" kv[2]
            if (metric == "finalFitness") {
              print "fitness_" kv[1] "=" kv[2]
            }
          }
        }
        if (!("Badv" in values) && ("BvA" in values) && ("AvB" in values)) {
          delta = values["BvA"] - values["AvB"]
          printf "%s_Badv=%.6f\n", metric, delta
          if (metric == "finalFitness") {
            printf "fitness_Badv=%.6f\n", delta
          }
        }
      }
    ' "$section_file"
  } > "$metrics_file"
}

metrics_kv_or_na() {
  local key="$1"
  local file="$2"
  extract_metric "$key" "$file" 2>/dev/null || printf 'N/A\n'
}

append_runner_diagnostic_metrics() {
  local source_file="$1"
  grep -E '^(runtimeGene\.|runtimePolicyPatch\.|runtimePolicyDiff\.|runtimeGeneSource=|outputCandidate|stagnationWindow=|minimumMeaningfulImprovement=|finalAverageDistanceToElite=|finalAveragePairwiseDistance=|finalUniqueGenomeRatio=|finalGenerationsWithoutImprovement=|lastMeaningfulImprovementGeneration=|isStagnating=|generationAverageDistanceToElite=|generationAveragePairwiseDistance=|generationUniqueGenomeRatio=|generationGenerationsWithoutImprovement=)' "$source_file" || true
}

write_comparison_table() {
  local output_file="$1"
  local primary_metrics_file="$2"
  local holdout_metrics_file="$3"
  local profile_name="$4"
  local run_status="$5"
  local train_seed_list="$6"
  local holdout_seed_list="$7"

  {
    echo "# Stage 0 A/B Comparison Snapshot"
    echo
    echo "- status: \`$run_status\`"
    echo "- profile: \`$profile_name\`"
    echo "- semantics: \`A=basePreset\`, \`B=tunedOutput\`; Baseline column uses \`AvB\`, Candidate column uses \`BvA\`, Delta uses \`Badv\`"
    echo "- training seeds: \`$train_seed_list\`"
    echo "- holdout seeds: \`${holdout_seed_list:-[]}\`"
    echo

    render_ab_table_section() {
      local label="$1"
      local metrics_file="$2"
      local available
      available="$(metrics_kv_or_na "available" "$metrics_file")"

      echo "## ${label}"
      echo
      if [[ "$available" != "true" ]]; then
        echo "_No parsed A/B section for ${label}._"
        echo
        return 0
      fi

      echo "| Metric | Baseline (AvB) | Candidate (BvA) | Delta (Badv) | Direction |"
      echo "|--------|----------------|-----------------|--------------|-----------|"

      render_row() {
        local metric="$1"
        local direction="$2"
        local baseline candidate delta
        baseline="$(metrics_kv_or_na "${metric}_AvB" "$metrics_file")"
        candidate="$(metrics_kv_or_na "${metric}_BvA" "$metrics_file")"
        delta="$(metrics_kv_or_na "${metric}_Badv" "$metrics_file")"
        printf '| `%s` | `%s` | `%s` | `%s` | %s |\n' \
          "$metric" "$baseline" "$candidate" "$delta" "$direction"
      }

      render_row "finalFitness" "higher better"
      render_row "legacyFitness" "higher better"
      render_row "primaryFitness" "higher better"
      render_row "guardrailPenalty" "lower better"
      render_row "winRate" "higher better"
      render_row "scoreDiff" "higher better"
      render_row "underbidLoss" "lower better"
      render_row "trumpDensityUnderbidLoss" "lower better"
      render_row "noTrumpControlUnderbidLoss" "lower better"
      render_row "premiumAssistLoss" "lower better"
      render_row "premiumPenaltyTargetLoss" "lower better"
      echo
    }

    render_ab_table_section "Primary A/B Validation" "$primary_metrics_file"
    render_ab_table_section "Holdout A/B Validation" "$holdout_metrics_file"
  } > "$output_file"
}

profile="compare-v1"
difficulty="hard"
seed_list=""
holdout_seed_list=""
population_size=""
generations=""
games_per_candidate=""
rounds_per_game=""
ab_validation_games_per_candidate=""
show_progress="false"
output_root=".derivedData/bot-ab-runs"
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
    --holdout-seed-list)
      holdout_seed_list="${2:-}"
      require_value "$holdout_seed_list" "--holdout-seed-list"
      shift 2
      ;;
    --population-size)
      population_size="${2:-}"
      require_value "$population_size" "--population-size"
      shift 2
      ;;
    --generations)
      generations="${2:-}"
      require_value "$generations" "--generations"
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
    --ab-validation-games-per-candidate)
      ab_validation_games_per_candidate="${2:-}"
      require_value "$ab_validation_games_per_candidate" "--ab-validation-games-per-candidate"
      shift 2
      ;;
    --show-progress)
      show_progress="${2:-}"
      require_value "$show_progress" "--show-progress"
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
  compare-v1)
    profile_seed_list="20260220,20260221,20260222,20260223,20260224,20260225"
    profile_holdout_seed_list="20260226,20260227,20260228,20260301,20260302,20260303"
    profile_population_size="10"
    profile_generations="10"
    profile_games_per_candidate="8"
    profile_rounds_per_game="24"
    profile_ab_validation_games_per_candidate="8"
    ;;
  medium)
    profile_seed_list="20260220,20260221,20260222,20260223"
    profile_holdout_seed_list="20260226,20260227,20260228,20260301"
    profile_population_size="6"
    profile_generations="4"
    profile_games_per_candidate="4"
    profile_rounds_per_game="16"
    profile_ab_validation_games_per_candidate="4"
    ;;
  smoke)
    profile_seed_list="20260220,20260221"
    profile_holdout_seed_list="20260226,20260227"
    profile_population_size="4"
    profile_generations="2"
    profile_games_per_candidate="2"
    profile_rounds_per_game="12"
    profile_ab_validation_games_per_candidate="2"
    ;;
  *)
    echo "Unknown profile: $profile (use compare-v1|medium|smoke)" >&2
    exit 1
    ;;
esac

seed_list="${seed_list:-$profile_seed_list}"
holdout_seed_list="${holdout_seed_list:-$profile_holdout_seed_list}"
population_size="${population_size:-$profile_population_size}"
generations="${generations:-$profile_generations}"
games_per_candidate="${games_per_candidate:-$profile_games_per_candidate}"
rounds_per_game="${rounds_per_game:-$profile_rounds_per_game}"
ab_validation_games_per_candidate="${ab_validation_games_per_candidate:-$profile_ab_validation_games_per_candidate}"

require_seed_list "$seed_list" "--seed-list"
if [[ -n "$holdout_seed_list" ]]; then
  require_seed_list "$holdout_seed_list" "--holdout-seed-list"
fi
require_int "$population_size" "--population-size"
require_int "$generations" "--generations"
require_int "$games_per_candidate" "--games-per-candidate"
require_int "$rounds_per_game" "--rounds-per-game"
require_int "$ab_validation_games_per_candidate" "--ab-validation-games-per-candidate"
require_bool "$show_progress" "--show-progress"

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
comparison_table_path="$run_dir/comparison-table.md"
training_metrics_path="$run_dir/training-metrics.txt"
primary_section_path="$run_dir/ab-primary-section.txt"
holdout_section_path="$run_dir/ab-holdout-section.txt"
primary_metrics_path="$run_dir/ab-primary-metrics.txt"
holdout_metrics_path="$run_dir/ab-holdout-metrics.txt"
command_path="$run_dir/command.txt"
sandbox_home="$run_dir/sandbox-home"
module_cache_dir="$sandbox_home/.cache/clang/ModuleCache"
start_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

cmd=(
  "$train_script_abs"
  --difficulty "$difficulty"
  --seed-list "$seed_list"
  --ensemble-method median
  --population-size "$population_size"
  --generations "$generations"
  --games-per-candidate "$games_per_candidate"
  --rounds-per-game "$rounds_per_game"
  --player-count 4
  --cards-min 1
  --cards-max 9
  --elite-count 2
  --mutation-chance 0.32
  --mutation-magnitude 0.18
  --selection-pool-ratio 0.55
  --use-full-match-rules true
  --rotate-candidate-across-seats true
  --show-progress "$show_progress"
  --ab-validate true
  --ab-validation-seed-list "$seed_list"
  --ab-validation-games-per-candidate "$ab_validation_games_per_candidate"
  --output "$log_path"
)

if [[ -n "$holdout_seed_list" ]]; then
  cmd+=(--ab-validation-holdout-seed-list "$holdout_seed_list")
fi

if ((${#extra_train_args[@]} > 0)); then
  cmd+=("${extra_train_args[@]}")
fi

print_config() {
  echo "profile=$profile"
  echo "difficulty=$difficulty"
  echo "seed_list=$seed_list"
  echo "holdout_seed_list=$holdout_seed_list"
  echo "population_size=$population_size"
  echo "generations=$generations"
  echo "games_per_candidate=$games_per_candidate"
  echo "rounds_per_game=$rounds_per_game"
  echo "ab_validation_games_per_candidate=$ab_validation_games_per_candidate"
  echo "show_progress=$show_progress"
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
  echo "=== Stage 0 A/B Comparison Snapshot (dry-run) ==="
  print_config
  cat "$command_path"
  echo "artifacts_dir=$run_dir"
  exit 0
fi

echo "=== Stage 0 A/B Comparison Snapshot ==="
echo "Profile: $profile"
echo "Difficulty: $difficulty"
echo "Training seeds: $seed_list"
echo "Holdout seeds: $holdout_seed_list"
echo "Population size: $population_size"
echo "Generations: $generations"
echo "Games per candidate: $games_per_candidate"
echo "A/B validation games per candidate: $ab_validation_games_per_candidate"
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

selected_seed="$(extract_metric 'selectedSeed' "$log_path" 2>/dev/null || true)"
run_mode="$(extract_metric 'mode' "$log_path" 2>/dev/null || true)"
generation_count="$(extract_metric 'generationCount' "$log_path" 2>/dev/null || true)"
completed_generations="$(extract_metric 'completedGenerations' "$log_path" 2>/dev/null || true)"
improvement="$(extract_metric 'improvement' "$log_path" 2>/dev/null || true)"
best_fitness="$(extract_metric 'bestFitness' "$log_path" 2>/dev/null || true)"
baseline_fitness="$(extract_metric 'baselineFitness' "$log_path" 2>/dev/null || true)"
baseline_legacy_fitness="$(extract_metric 'baselineLegacyFitness' "$log_path" 2>/dev/null || true)"
best_legacy_fitness="$(extract_metric 'bestLegacyFitness' "$log_path" 2>/dev/null || true)"
baseline_primary_fitness="$(extract_metric 'baselinePrimaryFitness' "$log_path" 2>/dev/null || true)"
best_primary_fitness="$(extract_metric 'bestPrimaryFitness' "$log_path" 2>/dev/null || true)"
baseline_guardrail_penalty="$(extract_metric 'baselineGuardrailPenalty' "$log_path" 2>/dev/null || true)"
best_guardrail_penalty="$(extract_metric 'bestGuardrailPenalty' "$log_path" 2>/dev/null || true)"
baseline_final_fitness="$(extract_metric 'baselineFinalFitness' "$log_path" 2>/dev/null || true)"
best_final_fitness="$(extract_metric 'bestFinalFitness' "$log_path" 2>/dev/null || true)"
ab_primary_seeds_line="$(extract_metric 'abValidationPrimarySeeds' "$log_path" 2>/dev/null || true)"
ab_holdout_seeds_line="$(extract_metric 'abValidationHoldoutSeeds' "$log_path" 2>/dev/null || true)"

extract_ab_section "primary" "$log_path" "$primary_section_path"
extract_ab_section "holdout" "$log_path" "$holdout_section_path"
write_ab_metrics_file "primary" "$primary_section_path" "$primary_metrics_path"
write_ab_metrics_file "holdout" "$holdout_section_path" "$holdout_metrics_path"

primary_final_fitness_badv="$(extract_metric 'finalFitness_Badv' "$primary_metrics_path" 2>/dev/null || true)"
primary_legacy_fitness_badv="$(extract_metric 'legacyFitness_Badv' "$primary_metrics_path" 2>/dev/null || true)"
primary_primary_fitness_badv="$(extract_metric 'primaryFitness_Badv' "$primary_metrics_path" 2>/dev/null || true)"
primary_guardrail_penalty_badv="$(extract_metric 'guardrailPenalty_Badv' "$primary_metrics_path" 2>/dev/null || true)"
holdout_final_fitness_badv="$(extract_metric 'finalFitness_Badv' "$holdout_metrics_path" 2>/dev/null || true)"
holdout_legacy_fitness_badv="$(extract_metric 'legacyFitness_Badv' "$holdout_metrics_path" 2>/dev/null || true)"
holdout_primary_fitness_badv="$(extract_metric 'primaryFitness_Badv' "$holdout_metrics_path" 2>/dev/null || true)"
holdout_guardrail_penalty_badv="$(extract_metric 'guardrailPenalty_Badv' "$holdout_metrics_path" 2>/dev/null || true)"

{
  echo "status=$status"
  echo "mode=${run_mode:-}"
  echo "generationCount=${generation_count:-}"
  echo "selectedSeed=${selected_seed:-}"
  echo "completedGenerations=${completed_generations:-}"
  echo "baselineFitness=${baseline_fitness:-${baseline_final_fitness:-}}"
  echo "bestFitness=${best_fitness:-${best_final_fitness:-}}"
  echo "baselineLegacyFitness=${baseline_legacy_fitness:-}"
  echo "bestLegacyFitness=${best_legacy_fitness:-}"
  echo "baselinePrimaryFitness=${baseline_primary_fitness:-}"
  echo "bestPrimaryFitness=${best_primary_fitness:-}"
  echo "baselineGuardrailPenalty=${baseline_guardrail_penalty:-}"
  echo "bestGuardrailPenalty=${best_guardrail_penalty:-}"
  echo "baselineFinalFitness=${baseline_final_fitness:-${baseline_fitness:-}}"
  echo "bestFinalFitness=${best_final_fitness:-${best_fitness:-}}"
  echo "improvement=${improvement:-}"
  echo "abPrimaryFinalFitnessEffectSize=${primary_final_fitness_badv:-}"
  echo "abPrimaryLegacyFitnessEffectSize=${primary_legacy_fitness_badv:-}"
  echo "abPrimaryPrimaryFitnessEffectSize=${primary_primary_fitness_badv:-}"
  echo "abPrimaryGuardrailPenaltyEffectSize=${primary_guardrail_penalty_badv:-}"
  echo "abHoldoutFinalFitnessEffectSize=${holdout_final_fitness_badv:-}"
  echo "abHoldoutLegacyFitnessEffectSize=${holdout_legacy_fitness_badv:-}"
  echo "abHoldoutPrimaryFitnessEffectSize=${holdout_primary_fitness_badv:-}"
  echo "abHoldoutGuardrailPenaltyEffectSize=${holdout_guardrail_penalty_badv:-}"
  append_runner_diagnostic_metrics "$log_path"
} > "$training_metrics_path"

write_comparison_table \
  "$comparison_table_path" \
  "$primary_metrics_path" \
  "$holdout_metrics_path" \
  "$profile" \
  "$status" \
  "$seed_list" \
  "$holdout_seed_list"

{
  echo "status=$status"
  echo "exit_code=$run_exit_code"
  echo "started_at_utc=$start_iso"
  echo "finished_at_utc=$end_iso"
  echo "profile=$profile"
  echo "difficulty=$difficulty"
  echo "seed_list=$seed_list"
  echo "holdout_seed_list=$holdout_seed_list"
  echo "population_size=$population_size"
  echo "generations=$generations"
  echo "games_per_candidate=$games_per_candidate"
  echo "rounds_per_game=$rounds_per_game"
  echo "run_mode=${run_mode:-}"
  echo "generation_count=${generation_count:-}"
  echo "baselineFitness=${baseline_fitness:-${baseline_final_fitness:-}}"
  echo "bestFitness=${best_fitness:-${best_final_fitness:-}}"
  echo "baselineLegacyFitness=${baseline_legacy_fitness:-}"
  echo "bestLegacyFitness=${best_legacy_fitness:-}"
  echo "baselinePrimaryFitness=${baseline_primary_fitness:-}"
  echo "bestPrimaryFitness=${best_primary_fitness:-}"
  echo "baselineGuardrailPenalty=${baseline_guardrail_penalty:-}"
  echo "bestGuardrailPenalty=${best_guardrail_penalty:-}"
  echo "baselineFinalFitness=${baseline_final_fitness:-${baseline_fitness:-}}"
  echo "bestFinalFitness=${best_final_fitness:-${best_fitness:-}}"
  echo "abPrimaryFinalFitnessEffectSize=${primary_final_fitness_badv:-}"
  echo "abPrimaryLegacyFitnessEffectSize=${primary_legacy_fitness_badv:-}"
  echo "abPrimaryPrimaryFitnessEffectSize=${primary_primary_fitness_badv:-}"
  echo "abPrimaryGuardrailPenaltyEffectSize=${primary_guardrail_penalty_badv:-}"
  echo "abHoldoutFinalFitnessEffectSize=${holdout_final_fitness_badv:-}"
  echo "abHoldoutLegacyFitnessEffectSize=${holdout_legacy_fitness_badv:-}"
  echo "abHoldoutPrimaryFitnessEffectSize=${holdout_primary_fitness_badv:-}"
  echo "abHoldoutGuardrailPenaltyEffectSize=${holdout_guardrail_penalty_badv:-}"
  echo "ab_validation_games_per_candidate=$ab_validation_games_per_candidate"
  echo "show_progress=$show_progress"
  echo "train_script=$train_script_abs"
  echo "artifacts_dir=$run_dir"
  echo "command_file=$command_path"
  echo "log_file=$log_path"
  echo "comparison_table_file=$comparison_table_path"
  echo "training_metrics_file=$training_metrics_path"
  echo "ab_primary_section_file=$primary_section_path"
  echo "ab_primary_metrics_file=$primary_metrics_path"
  echo "ab_holdout_section_file=$holdout_section_path"
  echo "ab_holdout_metrics_file=$holdout_metrics_path"
  echo "abValidationPrimarySeeds=${ab_primary_seeds_line:-}"
  echo "abValidationHoldoutSeeds=${ab_holdout_seeds_line:-}"
  echo "sandbox_home=$sandbox_home"
  echo "clang_module_cache_path=$module_cache_dir"
  append_runner_diagnostic_metrics "$log_path"
} > "$summary_path"

echo "=== A/B comparison snapshot finished ($status) ==="
echo "Summary: $summary_path"
echo "Comparison table: $comparison_table_path"
echo "Primary metrics: $primary_metrics_path"
echo "Holdout metrics: $holdout_metrics_path"
echo "Log: $log_path"

exit "$run_exit_code"
