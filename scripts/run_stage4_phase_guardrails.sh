#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_stage4_phase_guardrails.sh [параметры]

Назначение:
  Запускает Stage 04 phase-conditioned policy guardrails (deterministic unit tests)
  и сохраняет артефакты прогона в отдельную папку.

Параметры:
  --list                      Показать выбранные тесты и выйти
  --dry-run                   Напечатать команду xcodebuild и выбранные тесты без запуска
  --project <path>            Путь до .xcodeproj (по умолчанию: Jocker/Jocker.xcodeproj)
  --scheme <name>             Схема для тестов (по умолчанию: Jocker)
  --configuration <name>      Конфигурация сборки (по умолчанию: Debug)
  --destination <value>       Destination для xcodebuild
                              (по умолчанию: platform=iOS Simulator,name=iPhone 15)
  --output-root <path>        Корневая папка для результатов
                              (по умолчанию: .derivedData/stage4-phase-runs)
  --derived-data-path <path>  Путь для DerivedData
                              (по умолчанию: .derivedData)
  -h, --help                  Показать справку

Примеры:
  scripts/run_stage4_phase_guardrails.sh --list
  scripts/run_stage4_phase_guardrails.sh --dry-run
  scripts/run_stage4_phase_guardrails.sh --destination "platform=iOS Simulator,name=iPhone 15,OS=17.2"
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

extract_destination_id() {
  local destination="$1"
  if [[ "$destination" =~ (^|,)id=([^,]+)($|,) ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
  fi
}

ensure_simulator_ready() {
  local destination_id="$1"
  if [[ -z "$destination_id" ]]; then
    return 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    return 0
  fi

  xcrun simctl boot "$destination_id" >/dev/null 2>&1 || true

  local attempts=30
  local boot_line="($destination_id) (Booted)"
  while (( attempts > 0 )); do
    if xcrun simctl list devices "$destination_id" 2>/dev/null | grep -F "$boot_line" >/dev/null; then
      return 0
    fi
    sleep 1
    attempts=$((attempts - 1))
  done

  echo "Timed out waiting for simulator $destination_id to reach Booted state." >&2
  return 1
}

print_entries() {
  local entry
  for entry in "$@"; do
    IFS='|' read -r id area target <<<"$entry"
    printf '%-12s %-24s %s\n' "$id" "$area" "$target"
  done
}

project_path="Jocker/Jocker.xcodeproj"
scheme="Jocker"
configuration="Debug"
destination="platform=iOS Simulator,name=iPhone 15"
output_root=".derivedData/stage4-phase-runs"
derived_data_path=".derivedData"
list_only=false
dry_run=false

while (($# > 0)); do
  case "$1" in
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
destination_id="$(extract_destination_id "$destination")"

catalog_entries=(
  "PHASE-001|early block / low pressure|JockerTests/BotTurnCardHeuristicsServiceTests/testCardThreat_withPhaseContext_highTrumpCardIsMoreThreateningEarlyThanLate"
  "PHASE-003|late block / catch-up|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withLateBlockScoreDeficit_increasesChaseRiskUtility"
  "PHASE-003|late block / catch-up tuned|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseRankingTuning_amplifiesLateCatchUpAndSoftensEarlyCatchUp"
  "BLIND-004|block 4 / blind pressure|JockerTests/BotBlindBidPolicyTests/testMakePreDealBlindBid_withPhaseBlindTuning_isMoreAggressiveLateInBlock4"
  "PREMIUM-012|premium pressure|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_premiumPreserveEffect_isStrongerNearBlockEndThanEarly"
  "PREMIUM-012|premium pressure tuned|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseRankingTuning_amplifiesLatePremiumPressureAndSoftensEarlyPressure"
  "JOKER-017|joker-sensitive openings|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseJokerTuning_penalizesEarlyWishAndStrengthensLateAllInWish"
)

selected_tests=()
for entry in "${catalog_entries[@]}"; do
  IFS='|' read -r _id _area target <<<"$entry"
  selected_tests+=("$target")
done

if [[ "$list_only" == true ]]; then
  echo "Stage 04 phase-conditioned guardrails pack"
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

test_cmd=(
  xcodebuild
  -quiet
  -project "$project_abs"
  -scheme "$scheme"
  -configuration "$configuration"
  -destination "$destination"
  -destination-timeout 90
  -derivedDataPath "$derived_data_abs"
  -parallel-testing-enabled NO
  CODE_SIGNING_ALLOWED=NO
)

echo "=== Stage 04 phase-conditioned guardrails pack ==="
echo "Selected tests: ${#selected_tests[@]}"

if [[ "$dry_run" == true ]]; then
  printf 'Test command:'
  printf ' %q' "${test_cmd[@]}"
  printf '\n'
  print_entries "${catalog_entries[@]}"
  exit 0
fi

mkdir -p "$run_dir"
mkdir -p "$derived_data_abs"

print_entries "${catalog_entries[@]}" > "$selected_tests_path"
: > "$log_path"

echo "Project: $project_abs"
echo "Scheme: $scheme"
echo "Configuration: $configuration"
echo "Destination: $destination"
echo "Artifacts dir: $run_dir"
echo "DerivedData: $derived_data_abs"
echo "Selected tests file: $selected_tests_path"

if [[ -n "$destination_id" ]]; then
  echo "Prebooting simulator: $destination_id"
  ensure_simulator_ready "$destination_id"
fi

test_results=()
test_status=0

for entry in "${catalog_entries[@]}"; do
  IFS='|' read -r entry_id entry_area entry_target <<<"$entry"
  entry_cmd=("${test_cmd[@]}" "-only-testing:$entry_target" test-without-building)

  if [[ -n "$destination_id" ]]; then
    ensure_simulator_ready "$destination_id"
  fi

  set +e
  {
    echo "=== [$entry_id] $entry_area ==="
    printf '%q ' "${entry_cmd[@]}"
    printf '\n'
    "${entry_cmd[@]}"
  } 2>&1 | tee -a "$log_path"
  entry_status=${PIPESTATUS[0]}
  set -e

  test_results+=("$entry_id|$entry_area|$entry_target|$entry_status")
  if [[ $entry_status -ne 0 && $test_status -eq 0 ]]; then
    test_status=$entry_status
  fi
done

status=$test_status

finish_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

{
  echo "status=$([[ $status -eq 0 ]] && echo passed || echo failed)"
  echo "exit_code=$status"
  echo "build_exit_code=prebuilt-artifacts"
  echo "test_exit_code=$test_status"
  echo "started_at_utc=$start_iso"
  echo "finished_at_utc=$finish_iso"
  echo "selected_test_count=${#selected_tests[@]}"
  echo "scenario_family_count=5"
  echo "validation_mode=embedded_phase_guardrails"
  for index in "${!test_results[@]}"; do
    IFS='|' read -r entry_id entry_area entry_target entry_status <<<"${test_results[$index]}"
    human_index=$((index + 1))
    echo "test.$human_index.id=$entry_id"
    echo "test.$human_index.area=$entry_area"
    echo "test.$human_index.target=$entry_target"
    echo "test.$human_index.status=$([[ $entry_status -eq 0 ]] && echo passed || echo failed)"
    echo "test.$human_index.exit_code=$entry_status"
  done
  echo "family.early_block_low_pressure=PHASE-001"
  echo "family.early_block_low_pressure.coverage=baseline_phase_probe"
  echo "family.early_block_low_pressure.test=JockerTests/BotTurnCardHeuristicsServiceTests/testCardThreat_withPhaseContext_highTrumpCardIsMoreThreateningEarlyThanLate"
  echo "family.early_block_low_pressure.expected=threat(early)>threat(late)"
  echo "family.late_block_catch_up=PHASE-003"
  echo "family.late_block_catch_up.coverage=baseline_and_candidate"
  echo "family.late_block_catch_up.baseline_test=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withLateBlockScoreDeficit_increasesChaseRiskUtility"
  echo "family.late_block_catch_up.candidate_test=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseRankingTuning_amplifiesLateCatchUpAndSoftensEarlyCatchUp"
  echo "family.late_block_catch_up.expected.baseline=lateDeficit>noContext"
  echo "family.late_block_catch_up.expected.candidate=tunedEarly<baselineEarly;tunedLate>baselineLate"
  echo "family.block4_blind_pressure=BLIND-004"
  echo "family.block4_blind_pressure.coverage=baseline_and_candidate"
  echo "family.block4_blind_pressure.baseline_probe=JockerTests/BotBlindBidPolicyTests/testMakePreDealBlindBid_withPhaseBlindTuning_isMoreAggressiveLateInBlock4"
  echo "family.block4_blind_pressure.candidate_test=JockerTests/BotBlindBidPolicyTests/testMakePreDealBlindBid_withPhaseBlindTuning_isMoreAggressiveLateInBlock4"
  echo "family.block4_blind_pressure.expected.baseline=baselineEarly==baselineLate"
  echo "family.block4_blind_pressure.expected.candidate=tunedLate>=tunedEarly"
  echo "family.premium_pressure=PREMIUM-012"
  echo "family.premium_pressure.coverage=baseline_and_candidate"
  echo "family.premium_pressure.baseline_test=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_premiumPreserveEffect_isStrongerNearBlockEndThanEarly"
  echo "family.premium_pressure.candidate_test=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseRankingTuning_amplifiesLatePremiumPressureAndSoftensEarlyPressure"
  echo "family.premium_pressure.expected.baseline=lateDelta>earlyDelta"
  echo "family.premium_pressure.expected.candidate=tunedEarly<baselineEarly;tunedLate>baselineLate"
  echo "family.joker_sensitive_openings=JOKER-017"
  echo "family.joker_sensitive_openings.coverage=baseline_and_candidate"
  echo "family.joker_sensitive_openings.baseline_probe=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseJokerTuning_penalizesEarlyWishAndStrengthensLateAllInWish"
  echo "family.joker_sensitive_openings.candidate_test=JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_withPhaseJokerTuning_penalizesEarlyWishAndStrengthensLateAllInWish"
  echo "family.joker_sensitive_openings.expected.baseline=baselineEarly<baselineLate"
  echo "family.joker_sensitive_openings.expected.candidate=tunedEarly<baselineEarly;tunedLate>baselineLate"
  echo "artifacts_dir=$run_dir"
  echo "selected_tests_file=$selected_tests_path"
  echo "log_file=$log_path"
  echo "result_bundle=not-generated"
  echo "result_bundle_reason=disabled_for_stability"
} > "$summary_path"

echo "Summary: $summary_path"
echo "Selected tests: $selected_tests_path"
echo "Log: $log_path"

exit "$status"
