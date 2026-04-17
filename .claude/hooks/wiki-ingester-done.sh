#!/bin/bash
# Fires on wiki-ingester SubagentStop. Reads stdin JSON, logs the full
# last_assistant_message, and emits a truncated systemMessage so the user
# gets a visible notification in the Claude Code UI.
set -euo pipefail

INPUT=$(cat)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // "(no summary)"')

LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
  echo "[$TS] [$AGENT_ID]"
  echo "$LAST_MSG"
  echo "---"
} >> "$LOG_DIR/wiki-ingester.log"

# qmd refresh — not load-bearing for ingest; failures logged, not raised.
# A non-zero exit from `qmd update` or `qmd embed` inside an `if` condition
# does not terminate the script under `set -e` (bash treats the condition's
# exit as handled). So a qmd failure lands in the log without failing the
# outer hook.
{
  echo "[$TS] qmd refresh:"
  if command -v qmd >/dev/null 2>&1; then
    if qmd update >/dev/null 2>&1; then
      echo "  qmd update ok"
    else
      echo "  qmd update FAILED"
    fi
    if qmd embed >/dev/null 2>&1; then
      echo "  qmd embed ok"
    else
      echo "  qmd embed FAILED — index may be stale"
    fi
  else
    echo "  qmd not installed; skipping refresh"
  fi
  echo "---"
} >> "$LOG_DIR/wiki-ingester.log" 2>&1

# Truncate to 200 chars for the user-visible notification.
NOTIFY=$(printf '%s' "$LAST_MSG" | head -c 200)

jq -n --arg msg "wiki-ingester: $NOTIFY" '{systemMessage: $msg}'
