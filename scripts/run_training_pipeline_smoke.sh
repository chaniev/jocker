#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run_training_pipeline_smoke.sh
  scripts/run_training_pipeline_smoke.sh --output-root <path>

Purpose:
  Smoke-check the training pipeline end to end:
  1. compile the checked-in Swift runner
  2. run a short baselineOnly evaluation
  3. run a short 1-generation evolution
  4. verify baselineOnly does not enter the generation loop
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

resolve_abs_path() {
  local path="$1"
  local root="$2"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$root" "$path"
  fi
}

output_root=".derivedData/training-pipeline-smoke"

while (($# > 0)); do
  case "$1" in
    --output-root)
      output_root="${2:-}"
      require_value "$output_root" "--output-root"
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
train_script="$repo_root/scripts/train_bot_tuning.sh"
output_root_abs="$(resolve_abs_path "$output_root" "$repo_root")"
timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
summary_path="$run_dir/summary.txt"
baseline_log="$run_dir/baseline-only.log"
evolution_log="$run_dir/evolution-1gen.log"

mkdir -p "$run_dir"

echo "=== Training Pipeline Smoke ==="
echo "Artifacts dir: $run_dir"

bash "$train_script" --compile-only

bash "$train_script" \
  --run-mode baselineOnly \
  --difficulty hard \
  --seed 20260307 \
  --games-per-candidate 1 \
  --rounds-per-game 2 \
  --player-count 3 \
  --cards-min 1 \
  --cards-max 2 \
  --show-progress false \
  --ab-validate false \
  --output "$baseline_log"

grep -q '^mode=baselineOnly$' "$baseline_log"
grep -q '^generationCount=0$' "$baseline_log"
grep -q '^generationBestFitness=\[\]$' "$baseline_log"
grep -q '^baselineLegacyFitness=' "$baseline_log"
grep -q '^bestLegacyFitness=' "$baseline_log"
grep -q '^baselinePrimaryFitness=' "$baseline_log"
grep -q '^bestPrimaryFitness=' "$baseline_log"
grep -q '^baselineGuardrailPenalty=' "$baseline_log"
grep -q '^bestGuardrailPenalty=' "$baseline_log"
grep -q '^baselineFinalFitness=' "$baseline_log"
grep -q '^bestFinalFitness=' "$baseline_log"

bash "$train_script" \
  --difficulty hard \
  --seed 20260307 \
  --population-size 2 \
  --generations 1 \
  --games-per-candidate 1 \
  --rounds-per-game 2 \
  --player-count 3 \
  --cards-min 1 \
  --cards-max 2 \
  --elite-count 1 \
  --mutation-chance 0.25 \
  --mutation-magnitude 0.10 \
  --selection-pool-ratio 0.50 \
  --show-progress false \
  --ab-validate false \
  --output "$evolution_log"

grep -q '^mode=evolution$' "$evolution_log"
grep -q '^generationCount=1$' "$evolution_log"
grep -Eq '^generationBestFitness=\[[^]]+\]$' "$evolution_log"
grep -q '^baselineLegacyFitness=' "$evolution_log"
grep -q '^bestLegacyFitness=' "$evolution_log"
grep -q '^baselinePrimaryFitness=' "$evolution_log"
grep -q '^bestPrimaryFitness=' "$evolution_log"
grep -q '^baselineGuardrailPenalty=' "$evolution_log"
grep -q '^bestGuardrailPenalty=' "$evolution_log"
grep -q '^baselineFinalFitness=' "$evolution_log"
grep -q '^bestFinalFitness=' "$evolution_log"

cat > "$summary_path" <<EOF
status=passed
artifacts_dir=$run_dir
baseline_log=$baseline_log
evolution_log=$evolution_log
checks=compile-only,baselineOnly,baseline-no-generation-loop,baseline-fitness-quartet,evolution-1-generation,evolution-fitness-quartet
EOF

echo "=== Training pipeline smoke passed ==="
echo "Summary: $summary_path"
