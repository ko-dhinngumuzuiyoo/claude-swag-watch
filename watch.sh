#!/usr/bin/env bash
set -euo pipefail

dry_run=false
test_mode=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --test) test_mode=true ;;
    *) printf 'Usage: %s [--dry-run] [--test]\n' "$0" >&2; exit 1 ;;
  esac
done

STATUS_URL=${STATUS_URL:-https://claude.dev/terminal/swag-status.json}
TERMINAL_URL=${TERMINAL_URL:-https://claude.dev/terminal/}
NOTIFY_USER=${NOTIFY_USER:-ko-dhinngumuzuiyoo}
export LC_ALL=C

body_file=''
trap 'if [[ -n "$body_file" ]]; then rm -f -- "$body_file"; fi' EXIT

fetch() {
  if ! curl -fsSL --max-time 20 --retry 2 \
    --user-agent 'claude-swag-watch (+https://github.com/ko-dhinngumuzuiyoo/claude-swag-watch)' "$1"; then
    printf 'ERROR: failed to fetch %s\n' "$1" >&2
    return 1
  fi
}

if "$test_mode"; then
  label=swag-test
  title='[TEST] claude-swag-watch 通知テスト'
  result=test
  body_file=$(mktemp)
  printf '@%s\n\nclaude-swag-watch の通知テストです。スマートフォンに通知が届くか確認してください。\n確認後はこの Issue を閉じてください。\n' "$NOTIFY_USER" > "$body_file"
else
  status_json=$(fetch "$STATUS_URL")
  # Slurp to reject empty input or multiple JSON documents. Native Windows jq
  # can emit CRLF, so strip CR before comparing its output.
  if ! off=$(jq -ecs '
    if length == 1 and (.[0] | type == "object")
      and (.[0].off | type == "array")
      and (.[0].off | all(.[]; type == "string"))
    then .[0].off | sort
    else error("expected one object with an .off array of strings")
    end
  ' <<< "$status_json" | tr -d '\r'); then
    printf 'ERROR: invalid status JSON; expected an .off array of strings\n' >&2
    exit 1
  fi

  html=$(fetch "$TERMINAL_URL")
  known_urls='https://app.brilliantmade.com/r/claude-code-plushies
https://app.brilliantmade.com/r/claude-code-stickers'
  # No matches is a valid change: every known URL has been removed.
  current_urls=$({ grep -Eo 'https://app\.brilliantmade\.com/r/[A-Za-z0-9_-]+' <<< "$html" || true; } | tr -d '\r' | sort -u)

  reasons=()
  if [[ "$off" != '["plushie","stickers"]' ]]; then
    reasons+=("swag-status.json changed: $off")
  fi
  if [[ "$current_urls" != "$known_urls" ]]; then
    reasons+=('申込フォーム URL が変わりました:')
    while IFS= read -r url; do
      if [[ -n "$url" && $'\n'"$known_urls"$'\n' != *$'\n'"$url"$'\n'* ]]; then
        reasons+=("追加: $url")
      fi
    done <<< "$current_urls"
    while IFS= read -r url; do
      if [[ $'\n'"$current_urls"$'\n' != *$'\n'"$url"$'\n'* ]]; then
        reasons+=("削除: $url")
      fi
    done <<< "$known_urls"
  fi

  if (( ${#reasons[@]} == 0 )); then
    printf 'RESULT: no-change\n'
    exit 0
  fi

  label=swag-alert
  title='Clawd グッズの配布状況が変わりました'
  result=alert
  body_file=$(mktemp)
  {
    printf '@%s\n\nClawd グッズの配布状況に変化がありました。\n\n検出理由:\n' "$NOTIFY_USER"
    printf -- '- %s\n' "${reasons[@]}"
    printf '\n取得したステータス JSON:\n```json\n%s\n```\n' "$status_json"
    printf '\n現在の申込フォーム URL:\n%s\n' "${current_urls:-（なし）}"
    printf '\nhttps://claude.dev/terminal/\n\nTerminal を開いて /plushies または /stickers と入力\n'
    printf '\n確認後はこの Issue を閉じてください。閉じると次回以降、変更が検出された際に再び通知されます。\n'
  } > "$body_file"
fi

if "$dry_run"; then
  printf 'DRY RUN: would ensure label %s\n' "$label"
  if ! "$test_mode"; then
    printf 'DRY RUN: would skip creation if an open swag-alert issue exists\n'
  fi
  printf 'DRY RUN: would create issue with label %s and title "%s"\n' "$label" "$title"
  cat "$body_file"
else
  gh label create "$label" --color D93F0B --description "restock alert" >/dev/null 2>&1 || true
  create_issue=true
  if ! "$test_mode"; then
    open_count=$(gh issue list --label swag-alert --state open --json number --jq length | tr -d '\r')
    if (( open_count > 0 )); then
      printf 'open alert issue exists, skipping\n'
      create_issue=false
    fi
  fi
  if "$create_issue"; then
    gh issue create --label "$label" --title "$title" --body-file "$body_file"
  fi
fi

printf 'RESULT: %s\n' "$result"
