#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_stage6b_ranking_guardrails.sh [параметры]

Назначение:
  Запускает Stage 6b opponent-aware ranking guardrails (unit tests) и сохраняет
  артефакты прогона в отдельную папку. Опционально может включать cross-service
  guardrails (flow plumbing + evaluator/strategy no-evidence neutrality checks).

Параметры:
  --include-flow-plumbing      Добавить cross-service Stage 6 guardrails
                              (flow plumbing + evaluator/strategy no-evidence)
  --list                      Показать выбранные тесты и выйти
  --dry-run                   Напечатать команду xcodebuild и выбранные тесты без запуска
  --project <path>            Путь до .xcodeproj (по умолчанию: Jocker/Jocker.xcodeproj)
  --scheme <name>             Схема для тестов (по умолчанию: Jocker)
  --configuration <name>      Конфигурация сборки (по умолчанию: Debug)
  --destination <value>       Destination для xcodebuild
                              (по умолчанию: platform=iOS Simulator,name=iPhone 15)
  --output-root <path>        Корневая папка для результатов
                              (по умолчанию: .derivedData/stage6b-ranking-runs)
  --derived-data-path <path>  Путь для DerivedData
                              (по умолчанию: .derivedData/xcode-stage6b-ranking-tests)
  -h, --help                  Показать справку

Примеры:
  scripts/run_stage6b_ranking_guardrails.sh --list
  scripts/run_stage6b_ranking_guardrails.sh --dry-run
  scripts/run_stage6b_ranking_guardrails.sh --include-flow-plumbing
  scripts/run_stage6b_ranking_guardrails.sh --destination "platform=iOS Simulator,name=iPhone 15,OS=17.2"
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

print_entries() {
  local entry
  for entry in "$@"; do
    IFS='|' read -r id area target <<<"$entry"
    printf '%-12s %-18s %s\n' "$id" "$area" "$target"
  done
}

project_path="Jocker/Jocker.xcodeproj"
scheme="Jocker"
configuration="Debug"
destination="platform=iOS Simulator,name=iPhone 15"
output_root=".derivedData/stage6b-ranking-runs"
derived_data_path=".derivedData/xcode-stage6b-ranking-tests"
list_only=false
dry_run=false
include_flow_plumbing=false

while (($# > 0)); do
  case "$1" in
    --include-flow-plumbing)
      include_flow_plumbing=true
      shift
      ;;
    --list)
      list_only=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --project)
      project_path="${2:-}"
      require_value "$project_path" "--project"
      shift 2
      ;;
    --scheme)
      scheme="${2:-}"
      require_value "$scheme" "--scheme"
      shift 2
      ;;
    --configuration)
      configuration="${2:-}"
      require_value "$configuration" "--configuration"
      shift 2
      ;;
    --destination)
      destination="${2:-}"
      require_value "$destination" "--destination"
      shift 2
      ;;
    --output-root)
      output_root="${2:-}"
      require_value "$output_root" "--output-root"
      shift 2
      ;;
    --derived-data-path)
      derived_data_path="${2:-}"
      require_value "$derived_data_path" "--derived-data-path"
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
project_abs="$(resolve_abs_path "$project_path" "$repo_root")"
output_root_abs="$(resolve_abs_path "$output_root" "$repo_root")"
derived_data_abs="$(resolve_abs_path "$derived_data_path" "$repo_root")"

ranking_catalog_entries=(
  "BLIND-004|blind chase|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenBlindChasing_andDisciplinedObservedLeftNeighbor_increasesBlindContestUtility"
  "BLIND-004|blind chase|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenBlindChasing_andOpponentModelHasNoEvidence_keepsBlindContestUtilityUnchanged"
  "PREMIUM-010|premium deny|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeftNeighborPremiumCandidate_andDisciplinedLeftNeighborObserved_strengthensDenyPressure"
  "PREMIUM-010|premium deny|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenOpponentModelHasNoEvidence_keepsDenyPressureUnchanged"
  "PREMIUM-011|penalty avoid|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenPenaltyTargetRisk_andDisciplinedObservedOpponent_strengthensPenaltyAvoidAdjustment"
  "PREMIUM-011|penalty avoid|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenPenaltyTargetRisk_andOpponentModelHasNoEvidence_keepsPenaltyAvoidAdjustmentUnchanged"
  "PHASE-003|match catch-up|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withLateBlockScoreDeficit_andDisciplinedObservedLeftNeighbor_increasesCatchUpUtility"
  "PHASE-003|match catch-up|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withLateBlockScoreDeficit_andOpponentModelHasNoEvidence_keepsCatchUpUtilityUnchanged"
  "JOKER-016|lead-joker chase|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerAllInChaseAndDisciplinedObservedLeftNeighbor_strengthensAntiPremiumShift"
  "JOKER-016|lead-joker chase|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerAntiPremiumContext_andOpponentModelHasNoEvidence_keepsShiftUnchanged"
  "JOKER-016|lead-joker dump|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumpingAntiPremiumContext_andDisciplinedObservedLeftNeighbor_increasesTakesUtility"
  "JOKER-016|lead-joker dump|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumpingAntiPremiumContext_andOpponentModelHasNoEvidence_keepsTakesUtilityUnchanged"
)

flow_plumbing_catalog_entries=(
  "FLOW-OPP-001|flow plumbing|JockerTests/GameScenePlayingFlowTests/testBotMatchContext_buildsOpponentModelSnapshotFromObservedRounds"
  "FLOW-OPP-002|flow plumbing|JockerTests/GameScenePlayingFlowTests/testBotMatchContext_buildsOpponentModelWithZeroEvidenceAtBlockStart"
  "EVAL-OPP-001|evaluator no-evidence|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenLeadJokerAntiPremiumContext_andOpponentModelHasNoEvidence_keepsDecisionUnchanged"
  "EVAL-OPP-002|evaluator style-shift|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenModeratePremiumDenyContext_andDisciplinedObservedLeftNeighborFlipsDumpChoiceComparedToErratic"
  "STRAT-OPP-001|strategy no-evidence|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_whenAllInChaseAntiPremiumContext_andOpponentModelHasNoEvidence_keepsDecisionUnchanged"
  "STRAT-OPP-002|strategy style-shift|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_whenModeratePremiumDenyContext_andDisciplinedObservedLeftNeighborFlipsDumpChoiceComparedToErratic"
)

catalog_entries=()
catalog_entries+=("${ranking_catalog_entries[@]}")
if [[ "$include_flow_plumbing" == true ]]; then
  catalog_entries+=("${flow_plumbing_catalog_entries[@]}")
fi

selected_tests=()
for entry in "${catalog_entries[@]}"; do
  IFS='|' read -r _id _area target <<<"$entry"
  selected_tests+=("$target")
done

if [[ "$list_only" == true ]]; then
  echo "Stage 6b ranking guardrails pack"
  if [[ "$include_flow_plumbing" == true ]]; then
    echo "Mode: ranking+flow-plumbing"
  else
    echo "Mode: ranking-only"
  fi
  echo "Selected tests: ${#selected_tests[@]}"
  print_entries "${catalog_entries[@]}"
  exit 0
fi

if [[ ! -d "$project_abs" ]]; then
  echo "Xcode project not found: $project_abs" >&2
  exit 1
fi

if [[ "$dry_run" != true ]]; then
  if ! xcodebuild -version >/dev/null 2>&1; then
    developer_dir="$(xcode-select -p 2>/dev/null || true)"
    if [[ "$developer_dir" == *"CommandLineTools"* ]]; then
      echo "xcodebuild недоступен: выбран только Command Line Tools." >&2
      echo "Укажите установленный Xcode, например:" >&2
      echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    else
      echo "xcodebuild недоступен. Проверьте, что Xcode установлен и настроен." >&2
    fi
    exit 1
  fi
fi

timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
log_path="$run_dir/xcodebuild.log"
result_bundle_path="$run_dir/TestResults.xcresult"
summary_path="$run_dir/summary.txt"
selected_tests_path="$run_dir/selected-tests.txt"
start_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
mode_label="ranking-only"
if [[ "$include_flow_plumbing" == true ]]; then
  mode_label="ranking+flow-plumbing"
fi
ranking_tests_count="${#ranking_catalog_entries[@]}"
flow_tests_count=0
if [[ "$include_flow_plumbing" == true ]]; then
  flow_tests_count="${#flow_plumbing_catalog_entries[@]}"
fi

cmd=(
  xcodebuild
  -project "$project_abs"
  -scheme "$scheme"
  -configuration "$configuration"
  -destination "$destination"
  -derivedDataPath "$derived_data_abs"
  -resultBundlePath "$result_bundle_path"
  CODE_SIGNING_ALLOWED=NO
)

for test_id in "${selected_tests[@]}"; do
  cmd+=("-only-testing:$test_id")
done
cmd+=(test)

echo "=== Stage 6b ranking guardrails pack ==="
echo "Mode: $mode_label"
echo "Selected tests: ${#selected_tests[@]} (ranking=$ranking_tests_count, optional=$flow_tests_count)"

if [[ "$dry_run" == true ]]; then
  printf 'Command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  print_entries "${catalog_entries[@]}"
  exit 0
fi

mkdir -p "$run_dir"
mkdir -p "$derived_data_abs"

print_entries "${catalog_entries[@]}" > "$selected_tests_path"

echo "Project: $project_abs"
echo "Scheme: $scheme"
echo "Configuration: $configuration"
echo "Destination: $destination"
echo "Artifacts dir: $run_dir"
echo "DerivedData: $derived_data_abs"
echo "Selected tests file: $selected_tests_path"

set +e
"${cmd[@]}" | tee "$log_path"
test_exit_code=${PIPESTATUS[0]}
set -e

end_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if [[ "$test_exit_code" -eq 0 ]]; then
  status="passed"
else
  status="failed"
fi

cat > "$summary_path" <<EOF
status=$status
exit_code=$test_exit_code
started_at_utc=$start_iso
finished_at_utc=$end_iso
selected_tests_count=${#selected_tests[@]}
mode=$mode_label
ranking_tests_count=$ranking_tests_count
flow_tests_count=$flow_tests_count
optional_tests_count=$flow_tests_count
project=$project_abs
scheme=$scheme
configuration=$configuration
destination=$destination
derived_data_path=$derived_data_abs
selected_tests_file=$selected_tests_path
log_file=$log_path
result_bundle=$result_bundle_path
EOF

echo "=== Stage 6b ranking guardrails pack finished ($status) ==="
echo "Summary: $summary_path"
echo "Log: $log_path"
echo "Result bundle: $result_bundle_path"

exit "$test_exit_code"
