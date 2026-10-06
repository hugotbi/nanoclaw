#!/usr/bin/env bash
# Kit conseil + dev pour Claude Code (macOS / Linux / session cloud).
# Idempotent : relancer le script ne casse rien, il remet à niveau.
#
#   bash kit-conseil/install.sh            # plugins + skills + stack Python
#   bash kit-conseil/install.sh --no-python  # sans la stack Python
set -euo pipefail

WITH_PYTHON=1
[[ "${1:-}" == "--no-python" ]] && WITH_PYTHON=0

command -v claude >/dev/null || { echo "Claude Code introuvable (npm i -g @anthropic-ai/claude-code)"; exit 1; }
command -v git >/dev/null || { echo "git introuvable"; exit 1; }

SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
mkdir -p "$SKILLS_DIR" "$AGENTS_DIR"

# --- 1. Marketplaces de plugins (GitHub) -------------------------------------
MARKETPLACES=(
  anthropics/claude-plugins-official      # superpowers, context7, playwright...
  anthropics/financial-services           # financial-analysis, market-researcher, private-equity
  phuryn/pm-skills                        # frameworks marché / stratégie
  duckdb/duckdb-skills                    # SQL sur CSV / Parquet / Excel
  anotb/management-consulting-plugin      # process, change, org design, due diligence
  wshobson/agents                         # business analyst, analytics
)
for m in "${MARKETPLACES[@]}"; do
  echo "→ marketplace $m"
  claude plugin marketplace add "$m" >/dev/null 2>&1 || claude plugin marketplace update "$m" >/dev/null 2>&1 || true
done

# --- 2. Plugins ---------------------------------------------------------------
# Les plugins du catalogue claude.ai (Superpowers, strategy-consultant, Data,
# Exa, Operations, Product Management, investment-banking, Engineering) sont
# activés sur le compte et se synchronisent tout seuls : pas besoin ici.
PLUGINS=(
  financial-analysis@claude-for-financial-services
  market-researcher@claude-for-financial-services
  private-equity@claude-for-financial-services
  pm-market-research@pm-skills
  pm-product-strategy@pm-skills
  duckdb-skills@duckdb-skills
  management-consulting@anotb-management-consulting-plugin
  startup-business-analyst@claude-code-workflows
  business-analytics@claude-code-workflows
  context7@claude-plugins-official
  playwright@claude-plugins-official
)
for p in "${PLUGINS[@]}"; do
  echo "→ plugin $p"
  claude plugin install "$p" >/dev/null 2>&1 || echo "  ! échec : $p"
done

# --- 3. Skills autonomes (commits figés, relus avant intégration) -------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch() { # repo commit dest
  git init -q "$3"
  git -C "$3" fetch -q --depth 1 "https://github.com/$1" "$2"
  git -C "$3" checkout -q FETCH_HEAD
}

echo "→ skills recherche profonde (Weizhena/Deep-Research-skills)"
fetch Weizhena/Deep-Research-skills 6ce38f60e3f8b22502c29873f96503a4e0c5addb "$TMP/dr"
cp -R "$TMP/dr/skills/research-en/." "$SKILLS_DIR/"
cp "$TMP/dr/agents/web-search-agent.md" "$AGENTS_DIR/"
cp -R "$TMP/dr/agents/web-search-modules" "$AGENTS_DIR/"

echo "→ skills storyline / Minto / critique (sruthir28/enterprise-ai-skills)"
fetch sruthir28/enterprise-ai-skills ae8fe60a765cc766e0c598bfe8a7a33fd5faac1b "$TMP/ea"
for s in storyline-builder top-down-memo scpr-framework issue-tree-builder mckinsey-critic \
         mckinsey-charts decision-memo-builder workshop-designer stakeholder-map; do
  rm -rf "$SKILLS_DIR/$s"; cp -R "$TMP/ea/$s" "$SKILLS_DIR/$s"
done

echo "→ skills data / stats (K-Dense-AI/scientific-agent-skills, sélection)"
fetch K-Dense-AI/scientific-agent-skills 92ace75ac21efe19a620434e0ca4e356081fe807 "$TMP/kd"
for s in polars statsmodels statistical-analysis markitdown market-research-reports; do
  rm -rf "$SKILLS_DIR/$s"; cp -R "$TMP/kd/skills/$s" "$SKILLS_DIR/$s"
done

# --- 4. Stack Python pour le data crunching ----------------------------------
if [[ $WITH_PYTHON == 1 ]] && command -v python3 >/dev/null; then
  echo "→ stack Python (pandas, polars, duckdb, stats, charts, Office)"
  python3 -m pip install -q --user --upgrade \
    pandas polars duckdb pyarrow openpyxl xlsxwriter scipy statsmodels \
    matplotlib seaborn plotly kaleido python-pptx python-docx pyyaml 'markitdown[all]' \
    2>/dev/null || python3 -m pip install -q --upgrade --break-system-packages \
    pandas polars duckdb pyarrow openpyxl xlsxwriter scipy statsmodels \
    matplotlib seaborn plotly kaleido python-pptx python-docx pyyaml 'markitdown[all]'
fi

echo
echo "Terminé. Relance Claude Code (ou /reload-plugins) pour charger les plugins."
