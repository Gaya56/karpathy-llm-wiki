#!/usr/bin/env bash
# qmd-bootstrap.sh — fresh-install of qmd for this Codespace.
# Fresh-install ONLY. If a qmd collection named "wiki" or "raw" is already
# registered, the script exits without touching qmd state. Re-register by
# hand if you need to reset:
#     qmd collection remove wiki
#     qmd collection remove raw
set -euo pipefail

REPO=/workspaces/karpathy-llm-wiki

# 1. Runtime preflight — Node.js >= 22 OR Bun >= 1.0
have_node22=false
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed -E 's/^v([0-9]+).*/\1/')
  if [ "$NODE_MAJOR" -ge 22 ]; then
    have_node22=true
  fi
fi
have_bun=false
if command -v bun >/dev/null 2>&1; then
  have_bun=true
fi
if [ "$have_node22" = false ] && [ "$have_bun" = false ]; then
  echo "ERROR: qmd requires Node.js >=22 or Bun >=1.0" >&2
  echo "       node: $(command -v node || echo 'not found')" >&2
  echo "       bun:  $(command -v bun  || echo 'not found')" >&2
  exit 1
fi

# 2. Install qmd if not present
if ! command -v qmd >/dev/null 2>&1; then
  echo "Installing @tobilu/qmd globally..."
  if [ "$have_bun" = true ]; then
    bun install -g @tobilu/qmd
  else
    npm install -g @tobilu/qmd
  fi
fi
echo "qmd version: $(qmd --version)"

# 3. Fresh-install guard — refuse to run if our collection names already exist.
# NOTE: `qmd collection list` output format is not documented as machine-
# readable (no --json flag on this subcommand), so this grep is best-effort.
# If it false-positives on a collection name that merely contains "wiki" or
# "raw" as a substring, remove our collections manually and re-run.
if qmd collection list 2>/dev/null | grep -qwE '(wiki|raw)'; then
  echo "ERROR: a qmd collection named 'wiki' or 'raw' is already registered." >&2
  echo "       This script is fresh-install only. Remove them first:" >&2
  echo "         qmd collection remove wiki" >&2
  echo "         qmd collection remove raw" >&2
  exit 1
fi

# 4. Register collections — restrict to markdown so we don't index images,
# DS_Store, JSON raw sidecars, etc. Upstream default mask is undocumented,
# so we pin it explicitly.
qmd collection add "$REPO/wiki" --name wiki --mask "**/*.md"
qmd collection add "$REPO/raw"  --name raw  --mask "**/*.md"

# 5. Attach context metadata (qmd:// URI form per qmd docs)
qmd context add qmd://wiki "Compiled LLM wiki articles maintained by the karpathy-llm-wiki skill. Queries should prefer these over raw sources."
qmd context add qmd://raw  "Immutable raw source captures. Used to discover whether a topic has source material, not for synthesis."

# 6. Initial embed — downloads ~2 GB of GGUF models on first run
echo "Running initial embed (slow on first run — downloads models to ~/.cache/qmd/models/)..."
qmd embed

echo ""
echo "Install complete. Collection state:"
qmd collection list
