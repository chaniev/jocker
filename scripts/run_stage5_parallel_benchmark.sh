#!/usr/bin/env bash
set -euo pipefail

# Canonical Stage-05 profile: same as Makefile bt-hard-fullgame-balanced (FULLGAME_BALANCED_ARGS).
STAGE5_CANONICAL_ARGS=(
  --difficulty hard
  --seed 20260220
  --population-size 10
  --generations 10
  --games-per-candidate 8
  --rounds-per-game 24
  --player-count 4
  --cards-min 1
  --cards-max 9
  --elite-count 2
  --mutation-chance 0.32
  --mutation-magnitude 0.18
  --selection-pool-ratio 0.55
  --use-full-match-rules true
  --rotate-candidate-across-seats true
  --fitness-win-rate-weight 1.0
  --fitness-score-diff-weight 1.0
  --fitness-underbid-loss-weight 0.85
  --fitness-trump-density-underbid-weight 0.60
  --fitness-notrump-control-underbid-weight 0.70
  --score-diff-normalization 450
  --underbid-loss-normalization 6000
  --trump-density-underbid-normalization 2800
  --notrump-control-underbid-normalization 2200
  --show-progress false
  --ab-validate false
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_stage5_parallel_benchmark.sh
  scripts/run_stage5_parallel_benchmark.sh --output-root <path>

Purpose:
  Benchmark Stage 05 parallel candidate evaluation:
  1. Warm up runner via --compile-only (wall-clock excludes swiftc).
  2. Run canonical profile (bt-hard-fullgame-balanced) with --max-parallel-evaluations 1, 2, 4.
  3. Save raw logs and build summary.txt with parity status and speedup.

Artifacts:
  .derivedData/stage5-parallel-benchmark/<timestamp>/
    parallel-1.log, parallel-2.log, parallel-4.log  (raw logs)
    summary.txt                                  (parity + speedup)
EOF
}

output_root=".derivedData/stage5-parallel-benchmark"
while (($# > 0)); do
  case "$1" in
    --output-root)
      output_root="${2:-}"
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
if [[ "$output_root" == /* ]]; then
  output_root_abs="$output_root"
else
  output_root_abs="$repo_root/$output_root"
fi
mkdir -p "$output_root_abs"
timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
mkdir -p "$run_dir"

echo "=== Stage 05 parallel benchmark ==="
echo "Artifacts dir: $run_dir"

# Warm up: compile only so wall-clock does not include swiftc
bash "$train_script" --compile-only

run_one() {
  local parallel="$1"
  local log_path="$run_dir/parallel-$parallel.log"
  local wall_path="$run_dir/parallel-$parallel.wall_sec"
  local start end
  start=$(date +%s)
  bash "$train_script" "${STAGE5_CANONICAL_ARGS[@]}" --max-parallel-evaluations "$parallel" --output "$log_path"
  end=$(date +%s)
  echo $((end - start)) > "$wall_path"
  echo "parallel=$parallel wall_sec=$(cat "$wall_path")"
}

run_one 1
run_one 2
run_one 4

# Extract metrics block (key aggregated and best-candidate-identifying lines) for parity comparison.
# We compare: bestFinalFitness, generationBestFitness=[...], and runtimeGene.* section (best candidate).
extract_metrics_block() {
  local log="$1"
  grep -E '^(bestFinalFitness=|generationBestFitness=)' "$log" | sort
}

extract_runtime_gene_block() {
  local log="$1"
  grep -E '^runtimeGene\.' "$log" | sort
}

seq_metrics="$(extract_metrics_block "$run_dir/parallel-1.log")"
seq_runtime_gene="$(extract_runtime_gene_block "$run_dir/parallel-1.log")"
wall_1=$(cat "$run_dir/parallel-1.wall_sec")
wall_2=$(cat "$run_dir/parallel-2.wall_sec")
wall_4=$(cat "$run_dir/parallel-4.wall_sec")

parity_metrics_1_2="fail"
parity_metrics_1_4="fail"
parity_best_candidate_1_2="fail"
parity_best_candidate_1_4="fail"

metrics_2="$(extract_metrics_block "$run_dir/parallel-2.log")"
metrics_4="$(extract_metrics_block "$run_dir/parallel-4.log")"
gene_2="$(extract_runtime_gene_block "$run_dir/parallel-2.log")"
gene_4="$(extract_runtime_gene_block "$run_dir/parallel-4.log")"

[[ "$seq_metrics" == "$metrics_2" ]] && parity_metrics_1_2="ok"
[[ "$seq_metrics" == "$metrics_4" ]] && parity_metrics_1_4="ok"
[[ "$seq_runtime_gene" == "$gene_2" ]] && parity_best_candidate_1_2="ok"
[[ "$seq_runtime_gene" == "$gene_4" ]] && parity_best_candidate_1_4="ok"

speedup_2=""
speedup_4=""
if [[ -n "$wall_1" && "$wall_1" -gt 0 ]]; then
  speedup_2=$(awk "BEGIN { printf \"%.2f\", $wall_1 / $wall_2 }")
  speedup_4=$(awk "BEGIN { printf \"%.2f\", $wall_1 / $wall_4 }")
fi

status="passed"
if [[ "$parity_metrics_1_2" != "ok" || "$parity_metrics_1_4" != "ok" || "$parity_best_candidate_1_2" != "ok" || "$parity_best_candidate_1_4" != "ok" ]]; then
  status="failed"
fi

{
  echo "status=$status"
  echo "artifacts_dir=$run_dir"
  echo "profile=bt-hard-fullgame-balanced"
  echo "parity_metrics_sequential_vs_parallel_2=$parity_metrics_1_2"
  echo "parity_metrics_sequential_vs_parallel_4=$parity_metrics_1_4"
  echo "parity_best_candidate_sequential_vs_parallel_2=$parity_best_candidate_1_2"
  echo "parity_best_candidate_sequential_vs_parallel_4=$parity_best_candidate_1_4"
  echo "wall_sec_parallel_1=$wall_1"
  echo "wall_sec_parallel_2=$wall_2"
  echo "wall_sec_parallel_4=$wall_4"
  echo "speedup_parallel_2=$speedup_2"
  echo "speedup_parallel_4=$speedup_4"
  echo "checks=compile-only,sequential-vs-2-parity,sequential-vs-4-parity,speedup"
} > "$run_dir/summary.txt"

echo ""
echo "=== Summary ==="
cat "$run_dir/summary.txt"
echo ""
echo "Summary written to: $run_dir/summary.txt"

if [[ "$status" == "failed" ]]; then
  echo "Stage 05 benchmark failed: parity or speedup check failed." >&2
  exit 1
fi
echo "=== Stage 05 parallel benchmark passed ==="
