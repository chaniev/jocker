#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run_stage3_runtime_scope_validation.sh [options] [-- <extra train args>]

Purpose:
  Reproducible Stage 03 step-9 validation harness for runtime-policy evolution scope.
  It runs up to three A/B compare passes on the same profile:
    1. old-scope              (legacy genome scope: turnStrategy + bidding + trumpSelection)
    2. critical-runtime       (runtimePolicy-only: ranking + rollout + opponentModeling)
    3. full-scope             (legacy scope + runtimePolicy, with endgame + jokerDeclaration)

  The harness aggregates training/holdout effect sizes into a single summary.txt and
  gates full-scope execution on the critical-runtime holdout result unless
  --force-full-scope is provided.

Options:
  --profile <compare-v1|smoke>   Compare profile to use (default: compare-v1)
  --show-progress <true|false>   Forwarded to compare harness (default: false)
  --force-full-scope             Run full-scope even if critical-runtime holdout gate fails
  --output-root <path>           Root artifacts directory
                                 (default: .derivedData/stage3-runtime-scope-runs)
  --compare-script <path>        Path to run_bot_ab_comparison_snapshot.sh
                                 (default: scripts/run_bot_ab_comparison_snapshot.sh)
  --list-config                  Print resolved config and exit
  --dry-run                      Print underlying commands and exit
  -h, --help                     Show this help

Examples:
  scripts/run_stage3_runtime_scope_validation.sh --list-config
  scripts/run_stage3_runtime_scope_validation.sh --profile smoke
  scripts/run_stage3_runtime_scope_validation.sh --profile compare-v1
  scripts/run_stage3_runtime_scope_validation.sh --profile compare-v1 --force-full-scope
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

latest_run_dir() {
  local root="$1"
  find "$root" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | LC_ALL=C sort | tail -n 1
}

is_number() {
  local value="$1"
  [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

compare_ge() {
  local lhs="$1"
  local rhs="$2"
  awk "BEGIN { exit !($lhs >= $rhs) }"
}

compare_gt() {
  local lhs="$1"
  local rhs="$2"
  awk "BEGIN { exit !($lhs > $rhs) }"
}

format_delta() {
  local lhs="$1"
  local rhs="$2"
  if ! is_number "$lhs" || ! is_number "$rhs"; then
    printf '\n'
    return 0
  fi
  awk "BEGIN { printf \"%.6f\n\", $lhs - $rhs }"
}

profile="compare-v1"
show_progress="false"
force_full_scope=false
output_root=".derivedData/stage3-runtime-scope-runs"
compare_script_path="scripts/run_bot_ab_comparison_snapshot.sh"
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
    --show-progress)
      show_progress="${2:-}"
      require_value "$show_progress" "--show-progress"
      shift 2
      ;;
    --force-full-scope)
      force_full_scope=true
      shift
      ;;
    --output-root)
      output_root="${2:-}"
      require_value "$output_root" "--output-root"
      shift 2
      ;;
    --compare-script)
      compare_script_path="${2:-}"
      require_value "$compare_script_path" "--compare-script"
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
  compare-v1|smoke) ;;
  *)
    echo "Unknown profile: $profile (use compare-v1|smoke)" >&2
    exit 1
    ;;
esac

require_bool "$show_progress" "--show-progress"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
compare_script_abs="$(resolve_abs_path "$compare_script_path" "$repo_root")"
output_root_abs="$(resolve_abs_path "$output_root" "$repo_root")"

if [[ ! -f "$compare_script_abs" ]]; then
  echo "Compare script not found: $compare_script_abs" >&2
  exit 1
fi

if [[ ! -x "$compare_script_abs" ]]; then
  echo "Compare script is not executable: $compare_script_abs" >&2
  exit 1
fi

timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
old_root="$run_dir/old-scope"
critical_root="$run_dir/critical-runtime"
full_root="$run_dir/full-scope"
summary_path="$run_dir/summary.txt"
command_path="$run_dir/commands.txt"

mkdir -p "$run_dir"

old_scope_args=(
  --tuning-scope all
  --tune-ranking-policy false
  --tune-rollout-policy false
  --tune-endgame-policy false
  --tune-opponent-modeling-policy false
  --tune-joker-declaration-policy false
  --tune-phase-policy false
)

critical_scope_args=(
  --tuning-scope runtimePolicy-only
  --tune-ranking-policy true
  --tune-rollout-policy true
  --tune-endgame-policy false
  --tune-opponent-modeling-policy true
  --tune-joker-declaration-policy false
  --tune-phase-policy false
)

full_scope_args=(
  --tuning-scope all
  --tune-ranking-policy true
  --tune-rollout-policy true
  --tune-endgame-policy true
  --tune-opponent-modeling-policy true
  --tune-joker-declaration-policy true
  --tune-phase-policy false
)

print_config() {
  echo "profile=$profile"
  echo "show_progress=$show_progress"
  echo "force_full_scope=$force_full_scope"
  echo "output_root=$output_root_abs"
  echo "run_dir=$run_dir"
  echo "compare_script=$compare_script_abs"
  echo "extra_train_args_count=${#extra_train_args[@]}"
}

print_cmd() {
  local output_root_for_scope="$1"
  shift
  local cmd=(
    "$compare_script_abs"
    --profile "$profile"
    --show-progress "$show_progress"
    --output-root "$output_root_for_scope"
  )
  if ((${#extra_train_args[@]} > 0 || $# > 0)); then
    cmd+=(--)
    cmd+=("$@")
    if ((${#extra_train_args[@]} > 0)); then
      cmd+=("${extra_train_args[@]}")
    fi
  fi
  printf '%q ' "${cmd[@]}"
  printf '\n'
}

if [[ "$list_config" == true ]]; then
  print_config
  echo "old_scope_args=$(printf '%s ' "${old_scope_args[@]}")"
  echo "critical_scope_args=$(printf '%s ' "${critical_scope_args[@]}")"
  echo "full_scope_args=$(printf '%s ' "${full_scope_args[@]}")"
  exit 0
fi

{
  echo "old_scope_command=$(print_cmd "$old_root" "${old_scope_args[@]}")"
  echo "critical_scope_command=$(print_cmd "$critical_root" "${critical_scope_args[@]}")"
  echo "full_scope_command=$(print_cmd "$full_root" "${full_scope_args[@]}")"
} > "$command_path"

if [[ "$dry_run" == true ]]; then
  echo "=== Stage 03 runtime scope validation (dry-run) ==="
  print_config
  cat "$command_path"
  exit 0
fi

echo "=== Stage 03 runtime scope validation ==="
echo "Profile: $profile"
echo "Artifacts dir: $run_dir"
echo "Commands file: $command_path"

run_scope() {
  local scope_id="$1"
  local scope_root="$2"
  shift 2
  local scope_args=("$@")
  local cmd=(
    "$compare_script_abs"
    --profile "$profile"
    --show-progress "$show_progress"
    --output-root "$scope_root"
  )
  if ((${#scope_args[@]} > 0 || ${#extra_train_args[@]} > 0)); then
    cmd+=(--)
    if ((${#scope_args[@]} > 0)); then
      cmd+=("${scope_args[@]}")
    fi
    if ((${#extra_train_args[@]} > 0)); then
      cmd+=("${extra_train_args[@]}")
    fi
  fi

  mkdir -p "$scope_root"
  echo "" >&2
  echo "--- Scope: $scope_id ---" >&2
  printf 'Command:' >&2
  printf ' %q' "${cmd[@]}" >&2
  printf '\n' >&2

  set +e
  "${cmd[@]}" >&2
  local scope_exit_code=$?
  set -e

  local scope_run_dir
  scope_run_dir="$(latest_run_dir "$scope_root")"
  if [[ -z "$scope_run_dir" ]]; then
    echo "Failed to locate artifacts for scope $scope_id under $scope_root" >&2
    exit 1
  fi

  printf '%s\n' "$scope_exit_code"
  printf '%s\n' "$scope_run_dir"
}

old_scope_output="$(run_scope "old-scope" "$old_root" "${old_scope_args[@]}")"
old_exit_code="$(printf '%s\n' "$old_scope_output" | sed -n '1p')"
old_run_dir="$(printf '%s\n' "$old_scope_output" | sed -n '2p')"
old_summary_path="$old_run_dir/summary.txt"

critical_scope_output="$(run_scope "critical-runtime" "$critical_root" "${critical_scope_args[@]}")"
critical_exit_code="$(printf '%s\n' "$critical_scope_output" | sed -n '1p')"
critical_run_dir="$(printf '%s\n' "$critical_scope_output" | sed -n '2p')"
critical_summary_path="$critical_run_dir/summary.txt"

old_status="$(extract_metric "status" "$old_summary_path" 2>/dev/null || printf 'failed\n')"
critical_status="$(extract_metric "status" "$critical_summary_path" 2>/dev/null || printf 'failed\n')"

old_primary_final="$(extract_metric "abPrimaryFinalFitnessEffectSize" "$old_summary_path" 2>/dev/null || true)"
old_holdout_final="$(extract_metric "abHoldoutFinalFitnessEffectSize" "$old_summary_path" 2>/dev/null || true)"
critical_primary_final="$(extract_metric "abPrimaryFinalFitnessEffectSize" "$critical_summary_path" 2>/dev/null || true)"
critical_holdout_final="$(extract_metric "abHoldoutFinalFitnessEffectSize" "$critical_summary_path" 2>/dev/null || true)"

critical_holdout_gate="fail"
critical_holdout_gate_reason="missing_metrics"
if [[ "$old_status" == "passed" && "$critical_status" == "passed" ]] &&
   is_number "${old_holdout_final:-}" &&
   is_number "${critical_holdout_final:-}"; then
  if compare_gt "$critical_holdout_final" "0.0" && compare_ge "$critical_holdout_final" "$old_holdout_final"; then
    critical_holdout_gate="pass"
    critical_holdout_gate_reason="critical_holdout_finalFitness_effect_size_is_positive_and_not_worse_than_old_scope"
  else
    critical_holdout_gate_reason="critical_holdout_finalFitness_effect_size_did_not_clear_positive_not-worse-than-old gate"
  fi
fi

full_scope_executed=false
full_exit_code="skipped"
full_run_dir=""
full_summary_path=""
full_status="skipped"
full_primary_final=""
full_holdout_final=""
full_gate_reason="skipped_by_critical_holdout_gate"

if [[ "$critical_holdout_gate" == "pass" || "$force_full_scope" == true ]]; then
  if [[ "$force_full_scope" == true && "$critical_holdout_gate" != "pass" ]]; then
    full_gate_reason="forced_by_flag"
  else
    full_gate_reason="critical_holdout_gate_passed"
  fi

  full_scope_output="$(run_scope "full-scope" "$full_root" "${full_scope_args[@]}")"
  full_exit_code="$(printf '%s\n' "$full_scope_output" | sed -n '1p')"
  full_run_dir="$(printf '%s\n' "$full_scope_output" | sed -n '2p')"
  full_summary_path="$full_run_dir/summary.txt"
  full_status="$(extract_metric "status" "$full_summary_path" 2>/dev/null || printf 'failed\n')"
  full_primary_final="$(extract_metric "abPrimaryFinalFitnessEffectSize" "$full_summary_path" 2>/dev/null || true)"
  full_holdout_final="$(extract_metric "abHoldoutFinalFitnessEffectSize" "$full_summary_path" 2>/dev/null || true)"
  full_scope_executed=true
fi

recommended_scope="none"
recommended_holdout_final=""
if [[ "$old_status" == "passed" ]] && is_number "${old_holdout_final:-}"; then
  recommended_scope="old-scope"
  recommended_holdout_final="$old_holdout_final"
fi
if [[ "$critical_status" == "passed" ]] && is_number "${critical_holdout_final:-}"; then
  if [[ -z "$recommended_holdout_final" ]] || compare_gt "$critical_holdout_final" "$recommended_holdout_final"; then
    recommended_scope="critical-runtime"
    recommended_holdout_final="$critical_holdout_final"
  fi
fi
if [[ "$full_status" == "passed" ]] && is_number "${full_holdout_final:-}"; then
  if [[ -z "$recommended_holdout_final" ]] || compare_gt "$full_holdout_final" "$recommended_holdout_final"; then
    recommended_scope="full-scope"
    recommended_holdout_final="$full_holdout_final"
  fi
fi

overall_status="passed"
if [[ "$old_status" != "passed" || "$critical_status" != "passed" ]]; then
  overall_status="failed"
fi
if [[ "$critical_holdout_gate" != "pass" ]]; then
  overall_status="failed"
fi
if [[ "$full_scope_executed" == true && "$full_status" != "passed" ]]; then
  overall_status="failed"
fi

{
  echo "status=$overall_status"
  echo "profile=$profile"
  echo "artifacts_dir=$run_dir"
  echo "commands_file=$command_path"
  echo "force_full_scope=$force_full_scope"
  echo "full_scope_executed=$full_scope_executed"
  echo "critical_holdout_gate=$critical_holdout_gate"
  echo "critical_holdout_gate_reason=$critical_holdout_gate_reason"
  echo "full_scope_gate_reason=$full_gate_reason"
  echo "recommended_scope=$recommended_scope"
  echo "recommended_holdout_finalFitness_effect_size=${recommended_holdout_final:-}"
  echo "scope.old.exit_code=$old_exit_code"
  echo "scope.old.status=$old_status"
  echo "scope.old.run_dir=$old_run_dir"
  echo "scope.old.summary=$old_summary_path"
  echo "scope.old.training.finalFitnessEffectSize=${old_primary_final:-}"
  echo "scope.old.holdout.finalFitnessEffectSize=${old_holdout_final:-}"
  echo "scope.critical.exit_code=$critical_exit_code"
  echo "scope.critical.status=$critical_status"
  echo "scope.critical.run_dir=$critical_run_dir"
  echo "scope.critical.summary=$critical_summary_path"
  echo "scope.critical.training.finalFitnessEffectSize=${critical_primary_final:-}"
  echo "scope.critical.holdout.finalFitnessEffectSize=${critical_holdout_final:-}"
  echo "scope.critical.deltaVsOld.training.finalFitnessEffectSize=$(format_delta "${critical_primary_final:-}" "${old_primary_final:-}")"
  echo "scope.critical.deltaVsOld.holdout.finalFitnessEffectSize=$(format_delta "${critical_holdout_final:-}" "${old_holdout_final:-}")"
  echo "scope.full.exit_code=$full_exit_code"
  echo "scope.full.status=$full_status"
  echo "scope.full.run_dir=${full_run_dir:-}"
  echo "scope.full.summary=${full_summary_path:-}"
  echo "scope.full.training.finalFitnessEffectSize=${full_primary_final:-}"
  echo "scope.full.holdout.finalFitnessEffectSize=${full_holdout_final:-}"
  echo "scope.full.deltaVsCritical.training.finalFitnessEffectSize=$(format_delta "${full_primary_final:-}" "${critical_primary_final:-}")"
  echo "scope.full.deltaVsCritical.holdout.finalFitnessEffectSize=$(format_delta "${full_holdout_final:-}" "${critical_holdout_final:-}")"
  echo "checks=old-scope,critical-runtime,critical-holdout-gate,full-scope-if-gated"
} > "$summary_path"

echo ""
echo "=== Stage 03 Summary ==="
cat "$summary_path"
echo ""
echo "Summary: $summary_path"

if [[ "$overall_status" != "passed" ]]; then
  exit 1
fi
