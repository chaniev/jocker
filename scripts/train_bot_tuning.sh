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
build_dir="$repo_root/.derivedData/dev-tools/bot-training"
runner_bin="$build_dir/bot_training_runner"
module_cache_dir="$build_dir/module-cache"

mkdir -p "$build_dir"
mkdir -p "$module_cache_dir"

model_sources=()
while IFS= read -r source_file; do
  model_sources+=("$source_file")
done < <(find "$repo_root/Jocker/Jocker/Models" -type f -name '*.swift' | sort)

scoring_sources=()
while IFS= read -r source_file; do
  scoring_sources+=("$source_file")
done < <(find "$repo_root/Jocker/Jocker/Scoring" -type f -name '*.swift' | sort)

ai_sources=()
while IFS= read -r source_file; do
  ai_sources+=("$source_file")
done < <(find "$repo_root/Jocker/Jocker/Game/Services/AI" -type f -name '*.swift' | sort)

swift_sources=(
  "$repo_root/Jocker/JockerSelfPlayTools/main.swift"
  "$repo_root/Jocker/JockerSelfPlayTools/BotTrainingRunner.swift"
  "$repo_root/Jocker/Jocker/Core/GameColors.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/CardNode.swift"
  "$repo_root/Jocker/Jocker/Game/Nodes/TrickNode.swift"
  "${model_sources[@]}"
  "${scoring_sources[@]}"
  "${ai_sources[@]}"
)

needs_rebuild=true
if [[ -x "$runner_bin" ]]; then
  needs_rebuild=false
  for source_file in "${swift_sources[@]}"; do
    if [[ "$source_file" -nt "$runner_bin" ]]; then
      needs_rebuild=true
      break
    fi
  done
fi

if [[ "$needs_rebuild" == true ]]; then
  echo "Compiling bot training runner..."
  CLANG_MODULE_CACHE_PATH="$module_cache_dir" \
  SWIFT_MODULECACHE_PATH="$module_cache_dir" \
  swiftc -O "${swift_sources[@]}" -o "$runner_bin"
else
  echo "Using cached bot training runner: $runner_bin"
fi

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
