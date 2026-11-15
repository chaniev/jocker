#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/train_bot_tuning.sh [runner options]
  scripts/train_bot_tuning.sh --compile-only
  scripts/train_bot_tuning.sh [runner options] --output <path>

Purpose:
  Compile the checked-in Swift training runner and execute it.
  All training semantics live in `Jocker/JockerSelfPlayTools/BotTrainingRunner.swift`.

Shell-only options:
  --compile-only   Compile the runner and exit without executing it.
  --output <path>  Save stdout log to a file via tee.
  -h, --help       Forward help to the Swift runner.

Examples:
  scripts/train_bot_tuning.sh
  scripts/train_bot_tuning.sh --run-mode baselineOnly --seed-list 20260220,20260221
  scripts/train_bot_tuning.sh --generations 4 --games-per-candidate 6 --output .derivedData/bot-train.log
EOF
}

output_path=""
compile_only=false
forwarded_args=()

while (($# > 0)); do
  case "$1" in
    --output)
      output_path="${2:-}"
      if [[ -z "$output_path" ]]; then
        echo "Missing value for --output" >&2
        exit 1
      fi
      shift 2
      ;;
    --compile-only)
      compile_only=true
      shift
      ;;
    --help|-h)
      forwarded_args+=("$1")
      shift
      ;;
    *)
      forwarded_args+=("$1")
      shift
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
runner_bin="$(python3 "$script_dir/training_runner_cache.py" --root "$repo_root")"

if [[ "$compile_only" == true ]]; then
  echo "Runner compiled: $runner_bin"
  exit 0
fi

echo "Running self-play training..."
if [[ -n "$output_path" ]]; then
  output_dir="$(dirname "$output_path")"
  mkdir -p "$output_dir"
  "$runner_bin" "${forwarded_args[@]}" | tee "$output_path"
  echo "Saved run log to: $output_path"
else
  "$runner_bin" "${forwarded_args[@]}"
fi
