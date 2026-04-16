#!/bin/bash
# Fires on wiki-linter SubagentStop. Reads stdin JSON, logs the full
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
} >> "$LOG_DIR/wiki-linter.log"

# Truncate to 200 chars for the user-visible notification.
NOTIFY=$(printf '%s' "$LAST_MSG" | head -c 200)

jq -n --arg msg "wiki-linter: $NOTIFY" '{systemMessage: $msg}'
