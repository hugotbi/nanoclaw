# Kit conseil + dev pour Claude Code (Windows / PowerShell).
# Idempotent : relancer le script ne casse rien, il remet à niveau.
#
#   powershell -ExecutionPolicy Bypass -File kit-conseil\install.ps1
#   powershell -ExecutionPolicy Bypass -File kit-conseil\install.ps1 -NoPython
param([switch]$NoPython)
$ErrorActionPreference = "Stop"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { throw "Claude Code introuvable (npm i -g @anthropic-ai/claude-code)" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git introuvable" }

$SkillsDir = Join-Path $HOME ".claude\skills"
$AgentsDir = Join-Path $HOME ".claude\agents"
New-Item -ItemType Directory -Force -Path $SkillsDir, $AgentsDir | Out-Null

# --- 1. Marketplaces de plugins (GitHub) -------------------------------------
$Marketplaces = @(
  "anthropics/claude-plugins-official",
  "anthropics/financial-services",
  "phuryn/pm-skills",
  "duckdb/duckdb-skills",
  "anotb/management-consulting-plugin",
  "wshobson/agents"
)
foreach ($m in $Marketplaces) {
  Write-Host "-> marketplace $m"
  claude plugin marketplace add $m 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { claude plugin marketplace update $m 2>&1 | Out-Null }
}

# --- 2. Plugins ---------------------------------------------------------------
# Les plugins du catalogue claude.ai sont activés sur le compte et se
# synchronisent tout seuls : pas besoin de les installer ici.
$Plugins = @(
  "financial-analysis@claude-for-financial-services",
  "market-researcher@claude-for-financial-services",
  "private-equity@claude-for-financial-services",
  "pm-market-research@pm-skills",
  "pm-product-strategy@pm-skills",
  "duckdb-skills@duckdb-skills",
  "management-consulting@anotb-management-consulting-plugin",
  "startup-business-analyst@claude-code-workflows",
  "business-analytics@claude-code-workflows",
  "context7@claude-plugins-official",
  "playwright@claude-plugins-official"
)
foreach ($p in $Plugins) {
  Write-Host "-> plugin $p"
  claude plugin install $p 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Warning "échec : $p" }
}

# --- 3. Skills autonomes (commits figés, relus avant intégration) -------------
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("kit-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null

function Fetch($Repo, $Commit, $Dest) {
  git init -q $Dest
  git -C $Dest fetch -q --depth 1 "https://github.com/$Repo" $Commit
  git -C $Dest checkout -q FETCH_HEAD
}
function CopySkill($Src, $Name) {
  $target = Join-Path $SkillsDir $Name
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  Copy-Item -Recurse $Src $target
}

try {
  Write-Host "-> skills recherche profonde (Weizhena/Deep-Research-skills)"
  Fetch "Weizhena/Deep-Research-skills" "6ce38f60e3f8b22502c29873f96503a4e0c5addb" "$Tmp\dr"
  Get-ChildItem "$Tmp\dr\skills\research-en" -Directory | ForEach-Object { CopySkill $_.FullName $_.Name }
  Copy-Item "$Tmp\dr\agents\web-search-agent.md" $AgentsDir -Force
  Copy-Item -Recurse -Force "$Tmp\dr\agents\web-search-modules" $AgentsDir

  Write-Host "-> skills storyline / Minto / critique (sruthir28/enterprise-ai-skills)"
  Fetch "sruthir28/enterprise-ai-skills" "ae8fe60a765cc766e0c598bfe8a7a33fd5faac1b" "$Tmp\ea"
  foreach ($s in "storyline-builder","top-down-memo","scpr-framework","issue-tree-builder","mckinsey-critic",
                 "mckinsey-charts","decision-memo-builder","workshop-designer","stakeholder-map") {
    CopySkill "$Tmp\ea\$s" $s
  }

  Write-Host "-> skills data / stats (K-Dense-AI/scientific-agent-skills, sélection)"
  Fetch "K-Dense-AI/scientific-agent-skills" "92ace75ac21efe19a620434e0ca4e356081fe807" "$Tmp\kd"
  foreach ($s in "polars","statsmodels","statistical-analysis","markitdown","market-research-reports") {
    CopySkill "$Tmp\kd\skills\$s" $s
  }
} finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

# --- 4. Stack Python pour le data crunching ----------------------------------
if (-not $NoPython -and (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Host "-> stack Python (pandas, polars, duckdb, stats, charts, Office)"
  python -m pip install -q --user --upgrade pandas polars duckdb pyarrow openpyxl xlsxwriter scipy statsmodels `
    matplotlib seaborn plotly kaleido python-pptx python-docx pyyaml "markitdown[all]"
}

Write-Host ""
Write-Host "Terminé. Relance Claude Code (ou /reload-plugins) pour charger les plugins."
