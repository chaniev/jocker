#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_joker_regression_pack.sh [параметры]

Назначение:
  Запускает целевой набор JOKER regression-тестов (Stage 5) и сохраняет артефакты
  прогона в отдельную папку. По умолчанию запускает только strict-guardrails.

Параметры:
  --include-probes            Добавить probe-тесты (`XCTSkip`-ориентированные цели retuning)
  --strict-only               Запустить только strict-тесты (режим по умолчанию)
  --list                      Показать выбранные тесты и выйти
  --dry-run                   Напечатать команду xcodebuild и выбранные тесты без запуска
  --project <path>            Путь до .xcodeproj (по умолчанию: Jocker/Jocker.xcodeproj)
  --scheme <name>             Схема для тестов (по умолчанию: Jocker)
  --configuration <name>      Конфигурация сборки (по умолчанию: Debug)
  --destination <value>       Destination для xcodebuild
                              (по умолчанию: platform=iOS Simulator)
  --output-root <path>        Корневая папка для результатов
                              (по умолчанию: .derivedData/joker-regression-runs)
  --derived-data-path <path>  Путь для DerivedData
                              (по умолчанию: .derivedData/xcode-joker-tests)
  -h, --help                  Показать справку

Примеры:
  scripts/run_joker_regression_pack.sh --list
  scripts/run_joker_regression_pack.sh
  scripts/run_joker_regression_pack.sh --include-probes --destination "platform=iOS Simulator,name=iPhone 16"
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
    IFS='|' read -r id status target <<<"$entry"
    printf '%-10s %-6s %s\n' "$id" "$status" "$target"
  done
}

project_path="Jocker/Jocker.xcodeproj"
scheme="Jocker"
configuration="Debug"
destination="platform=iOS Simulator"
output_root=".derivedData/joker-regression-runs"
derived_data_path=".derivedData/xcode-joker-tests"
include_probes=false
list_only=false
dry_run=false

while (($# > 0)); do
  case "$1" in
    --include-probes)
      include_probes=true
      shift
      ;;
    --strict-only)
      include_probes=false
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

catalog_entries=(
  # JOKER-003 / JOKER-005 / JOKER-007 / JOKER-010 / JOKER-012 (ranking utility strict)
  "JOKER-003|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingEarly_prefersAboveDeclaringTrumpOverNonTrump"
  "JOKER-003|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumpingEarly_penalizesAboveDeclaringTrumpMoreThanNonTrump"
  "JOKER-004|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingFinalAllIn_preservesWishOverAbove"
  "JOKER-005|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumpingEarly_prefersTakesNonTrumpOverTakesTrump"
  "JOKER-005|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingEarly_prefersAboveTrumpOverTakesTrump"
  "JOKER-007|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingEarly_lowControlReservePenalizesWishMore"
  "JOKER-007|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingEarly_lowControlReserveIncreasesAboveTrumpAdvantageOverWish"
  "JOKER-010|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumpingAndOwnPremiumCandidate_increasesTakesNonTrumpAdvantageOverWish"
  "JOKER-010|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasingWithAntiPremiumPressure_increasesAboveTrumpAdvantageOverWish"
  "JOKER-012|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerChasing_preferredControlSuitBoostsMatchingAboveDeclaration"
  "JOKER-012|strict|JockerTests/BotTurnCandidateRankingServiceTests/testMoveUtility_whenLeadJokerDumping_preferredControlSuitPenalizesMatchingTakesDeclaration"

  # JOKER-004 / JOKER-005 / JOKER-015 (evaluator strict)
  "JOKER-004|strict|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenForcedLeadJokerEarlyChase_prefersAboveTrumpOverWish"
  "JOKER-004|strict|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenForcedLeadJokerFinalAllInChase_preservesWishOverAbove"
  "JOKER-005|strict|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenForcedLeadJokerDumping_prefersTakesNonTrumpDeclaration"
  "JOKER-015|strict|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenForcedLeadJokerEarlyChaseAndSpadeControlDominates_prefersAboveSpades"
  "JOKER-015|strict|JockerTests/BotTurnCandidateEvaluatorServiceTests/testBestMove_whenForcedLeadJokerEarlyChaseAndHeartControlDominates_prefersAboveHearts"

  # JOKER-009 / JOKER-014 (runtime strategy strict)
  "JOKER-009|strict|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_whenEarlyVsAllInChaseWithWeakHand_flipsLeadJokerDeclarationAboveToWish"
  "JOKER-014|strict|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_whenEarlyOverbidDumpAndOwnPremiumProtection_prefersLeadJokerTakesNonTrump"

  # Probe targets for Stage 5 retuning
  "JOKER-004|probe|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_jokerDeclarationProbe_mayFlipBetweenAboveAndWishByChaseUrgency"
  "JOKER-006|probe|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_jokerTakesProbe_mayPreferLeadJokerTakesInEarlyDumpWhenNonJokerLeadsAreRisky"
  "JOKER-008|probe|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_jokerControlReserveProbe_mayShiftLeadJokerDeclarationInEarlyChase"
  "JOKER-011|probe|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_jokerPremiumAwareChaseProbe_mayFlipAllInWishTowardAboveUnderAntiPremiumPressure"
  "JOKER-013|probe|JockerTests/BotTurnStrategyServiceTests/testMakeTurnDecision_jokerPreferredSuitProbe_mayShiftAboveDeclarationByPostJokerControlSuit"
)

selected_entries=()
selected_tests=()
strict_count=0
probe_count=0

for entry in "${catalog_entries[@]}"; do
  IFS='|' read -r _id status target <<<"$entry"
  if [[ "$status" == "probe" && "$include_probes" != true ]]; then
    continue
  fi
  selected_entries+=("$entry")
  selected_tests+=("$target")
  if [[ "$status" == "probe" ]]; then
    probe_count=$((probe_count + 1))
  else
    strict_count=$((strict_count + 1))
  fi
done

if [[ "${#selected_tests[@]}" -eq 0 ]]; then
  echo "No tests selected." >&2
  exit 1
fi

if [[ "$list_only" == true ]]; then
  echo "JOKER regression pack ($( [[ "$include_probes" == true ]] && echo 'strict+probe' || echo 'strict-only'))"
  echo "Selected tests: ${#selected_tests[@]} (strict=$strict_count, probe=$probe_count)"
  print_entries "${selected_entries[@]}"
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
mode_label="strict-only"
if [[ "$include_probes" == true ]]; then
  mode_label="strict+probe"
fi

cmd=(
  xcodebuild
  -project "$project_abs"
  -scheme "$scheme"
  -configuration "$configuration"
  -destination "$destination"
  -derivedDataPath "$derived_data_abs"
  -resultBundlePath "$result_bundle_path"
)

for test_id in "${selected_tests[@]}"; do
  cmd+=("-only-testing:$test_id")
done
cmd+=(test)

echo "=== JOKER regression pack ==="
echo "Mode: $mode_label"
echo "Selected tests: ${#selected_tests[@]} (strict=$strict_count, probe=$probe_count)"

if [[ "$dry_run" == true ]]; then
  printf 'Command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  print_entries "${selected_entries[@]}"
  exit 0
fi

mkdir -p "$run_dir"
mkdir -p "$derived_data_abs"

print_entries "${selected_entries[@]}" > "$selected_tests_path"

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
mode=$mode_label
selected_tests_count=${#selected_tests[@]}
strict_tests_count=$strict_count
probe_tests_count=$probe_count
project=$project_abs
scheme=$scheme
configuration=$configuration
destination=$destination
derived_data_path=$derived_data_abs
selected_tests_file=$selected_tests_path
log_file=$log_path
result_bundle=$result_bundle_path
EOF

echo "=== JOKER regression pack finished ($status) ==="
echo "Summary: $summary_path"
echo "Log: $log_path"
echo "Result bundle: $result_bundle_path"

exit "$test_exit_code"
