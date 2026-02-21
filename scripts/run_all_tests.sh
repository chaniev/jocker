#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Использование:
  scripts/run_all_tests.sh [параметры]

Назначение:
  Запускает все тесты Xcode-схемы и сохраняет артефакты прогона
  (полный лог + .xcresult + summary) в отдельную папку.

Параметры:
  --project <path>            Путь до .xcodeproj (по умолчанию: Jocker/Jocker.xcodeproj)
  --scheme <name>             Схема для тестов (по умолчанию: Jocker)
  --configuration <name>      Конфигурация сборки (по умолчанию: Debug)
  --destination <value>       Destination для xcodebuild
                              (по умолчанию: platform=iOS Simulator)
  --output-root <path>        Корневая папка для результатов
                              (по умолчанию: .derivedData/test-runs)
  --derived-data-path <path>  Путь для DerivedData
                              (по умолчанию: .derivedData/xcode-tests)
  -h, --help                  Показать справку

Примеры:
  scripts/run_all_tests.sh
  scripts/run_all_tests.sh --destination "platform=iOS Simulator,name=iPhone 16"
  scripts/run_all_tests.sh --scheme Jocker --output-root .derivedData/custom-test-runs
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

project_path="Jocker/Jocker.xcodeproj"
scheme="Jocker"
configuration="Debug"
destination="platform=iOS Simulator"
output_root=".derivedData/test-runs"
derived_data_path=".derivedData/xcode-tests"

while (($# > 0)); do
  case "$1" in
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

if [[ ! -d "$project_abs" ]]; then
  echo "Xcode project not found: $project_abs" >&2
  exit 1
fi

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

timestamp="$(date '+%Y%m%d-%H%M%S')"
run_dir="$output_root_abs/$timestamp"
log_path="$run_dir/xcodebuild.log"
result_bundle_path="$run_dir/TestResults.xcresult"
summary_path="$run_dir/summary.txt"
start_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

mkdir -p "$run_dir"
mkdir -p "$derived_data_abs"

echo "=== Test run started ==="
echo "Project: $project_abs"
echo "Scheme: $scheme"
echo "Configuration: $configuration"
echo "Destination: $destination"
echo "Artifacts dir: $run_dir"
echo "DerivedData: $derived_data_abs"

set +e
xcodebuild \
  -project "$project_abs" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -destination "$destination" \
  -derivedDataPath "$derived_data_abs" \
  -resultBundlePath "$result_bundle_path" \
  test | tee "$log_path"
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
project=$project_abs
scheme=$scheme
configuration=$configuration
destination=$destination
derived_data_path=$derived_data_abs
log_file=$log_path
result_bundle=$result_bundle_path
EOF

echo "=== Test run finished ($status) ==="
echo "Summary: $summary_path"
echo "Log: $log_path"
echo "Result bundle: $result_bundle_path"

exit "$test_exit_code"
