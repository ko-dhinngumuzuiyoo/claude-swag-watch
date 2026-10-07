#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture_dir="$repo_dir/tests/fixtures"
if command -v cygpath >/dev/null 2>&1; then
  fixture_dir=$(cygpath -m "$fixture_dir" | tr -d '\r')
  fixture_url="file:///$fixture_dir"
else
  fixture_url="file://$fixture_dir"
fi

# Keep dry-run tests safe even if a regression accidentally reaches gh.
gh() {
  printf 'ERROR: gh must not be called during dry-run tests\n' >&2
  return 99
}
export -f gh

failures=0
run_case() {
  local name=$1 status=$2 terminal=$3 expected_code=$4 expected_result=$5
  shift 5
  local output code=0 results
  output=$(STATUS_URL="$fixture_url/$status" TERMINAL_URL="$fixture_url/$terminal" \
    bash "$repo_dir/watch.sh" --dry-run "$@" 2>&1) || code=$?
  output=${output//$'\r'/}
  results=$(grep '^RESULT:' <<< "$output" || true)

  if [[ "$code" == "$expected_code" && "$results" == "$expected_result" ]] &&
    { [[ -z "$expected_result" ]] || [[ "${output##*$'\n'}" == "$expected_result" ]]; }; then
    printf 'PASS: %s\n' "$name"
  else
    printf 'FAIL: %s (expected exit %s and "%s", got exit %s)\n%s\n' \
      "$name" "$expected_code" "$expected_result" "$code" "$output"
    failures=$((failures + 1))
  fi
}

run_case 'both-off + known -> RESULT: no-change' status-off-both.json terminal-known.html 0 'RESULT: no-change'
run_case 'plushie-on + known -> RESULT: alert' status-plushie-on.json terminal-known.html 0 'RESULT: alert'
run_case 'both-off + new -> RESULT: alert' status-off-both.json terminal-new.html 0 'RESULT: alert'
run_case 'bad JSON -> exit 1' status-bad.json terminal-known.html 1 ''
run_case '--dry-run --test -> RESULT: test' status-off-both.json terminal-known.html 0 'RESULT: test' --test

if (( failures > 0 )); then
  exit 1
fi
