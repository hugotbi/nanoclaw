# Kit conseil + dev pour Claude Code

Équipement pour trois usages : produire des livrables de conseil, traiter de la donnée, mener des recherches web approfondies. Il couvre aussi le développement.

## Installation

Le kit repose sur trois couches, qui s'installent différemment.

| Couche | Contenu | Où ça vit | Installation |
|---|---|---|---|
| 1. Plugins claude.ai | Superpowers, strategy-consultant, Data, Exa, Operations, Product Management, investment-banking, Engineering | Compte claude.ai | Déjà activés. Ils se synchronisent sur le web, Desktop, Cowork et les sessions cloud |
| 2. Plugins GitHub | financial-analysis, market-researcher, private-equity, pm-market-research, pm-product-strategy, duckdb-skills, management-consulting, startup-business-analyst, business-analytics, context7, playwright | `~/.claude/plugins` de chaque machine | `install.sh` / `install.ps1` |
| 3. Skills GitHub autonomes | 19 skills : recherche profonde, storyline/Minto, stats/data | `~/.claude/skills` de chaque machine | `install.sh` / `install.ps1` |

Tes skills Orios (charte slide, Excel, cartographie, style humain, commande publique) sont déjà sur le compte claude.ai et suivent partout.

**Sur ton poste**
```bash
# macOS / Linux
bash kit-conseil/install.sh

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File kit-conseil\install.ps1
```
Ajoute `--no-python` (ou `-NoPython`) pour ne pas toucher à Python. Relance ensuite Claude Code, ou tape `/reload-plugins`.

**Sessions cloud (claude.ai/code)** : le conteneur repart de zéro à chaque session. Dans les réglages de l'environnement cloud, menu *Edit*, ajoute cette ligne au *Setup script* :
```bash
cd ~ && git clone -q --depth 1 -b claude/quirky-turing-odh7ek https://github.com/hugotbi/nanoclaw /tmp/kit && bash /tmp/kit/kit-conseil/install.sh
```

Les skills autonomes sont figés sur un commit précis. Le contenu a été relu avant intégration : aucun appel réseau caché, aucun `eval` ni `curl | sh`. Pour les mettre à jour, change le hash dans le script.

## Quoi utiliser pour quoi

### Cadrer une mission
| Besoin | Skill |
|---|---|
| Mission complète, du cadrage au rapport Word | `/strategy-consultant:engagement` (agents analystes en parallèle, validation des sources, critique du storyline) |
| Reformuler la question client | `strategy-consultant:problem-definition` |
| Arbre d'hypothèses ou issue tree MECE | `strategy-consultant:hypothesis-tree`, `issue-tree-builder` |
| Proposition commerciale, pricing de mission | `management-consulting:proposal-development`, `engagement-pricing` |
| Cartographie des parties prenantes | `stakeholder-map` |
| Atelier de décision | `workshop-designer`, `management-consulting:workshop-facilitation` |

### Recherche web approfondie
| Besoin | Skill |
|---|---|
| Benchmark structuré (N objets × M champs, un agent par objet) | `research` → `research-deep` → `research-report` |
| Recherche multi-étapes avec enrichissement | `exa:search`, `exa:exa-agent` (connecteur Exa à autoriser) |
| Panorama sectoriel | `market-researcher:sector-overview` |
| Analyse concurrentielle | `financial-analysis:competitive-analysis`, `pm-market-research:competitor-analysis`, `product-management:competitive-brief` |
| Taille de marché (TAM/SAM/SOM) | `pm-market-research:market-sizing`, `market-research-reports` |
| Pages dynamiques ou derrière un login | plugin `playwright` |
| Contre-vérifier une conclusion | `strategy-consultant:sense-check` |

### Data crunching
| Besoin | Skill / outil |
|---|---|
| SQL direct sur CSV, Excel, Parquet | `duckdb-skills:query`, `read-file`, `convert-file` |
| Exploration, nettoyage, validation | `data:explore-data`, `data:validate-data`, `financial-analysis:clean-data-xls` |
| Gros volumes | `polars` |
| Tests statistiques, régressions, séries temporelles | `statistical-analysis`, `statsmodels`, `data:statistical-analysis` |
| Écarts budget / réel, cascades | `finance:variance-analysis` |
| Modèles financiers | `financial-analysis:dcf-model`, `comps-analysis`, `3-statement-model`, `lbo-model` |
| Unit economics, due diligence | `private-equity:unit-economics`, `dd-checklist` |
| Convertir n'importe quel document en texte exploitable | `markitdown` |
| Graphiques, dashboards | `dataviz`, `data:create-viz`, `data:build-dashboard` |

### Livrables
**Règle : la charte Orios prime.** Les skills génériques servent au fond (structure, argumentation) ; la forme passe par les skills Orios.

| Besoin | Skill |
|---|---|
| Deck Orios | `oc-slide-orios-2026` ; `oc-cartographie-processus-orios` pour les swimlanes |
| Excel Orios | `oc-excel-orios-2026` |
| Politique ou note interne Word | `orios-format-politique` |
| Storyline, titres-messages | `storyline-builder`, `strategy-consultant:synthesis` |
| Note « réponse d'abord » (Minto) | `top-down-memo`, `scpr-framework` |
| Mémo de décision d'une page | `decision-memo-builder` |
| Graphiques natifs PowerPoint (waterfall, barres annotées) | `mckinsey-charts` |
| Revue critique avant envoi | `mckinsey-critic`, `financial-analysis:ib-check-deck` |
| Ton naturel, sans tics d'IA | `style-humain-orios`, `eviter-style-ia` |
| Process, conduite du changement, organisation | `operations:process-optimization`, `management-consulting:process-excellence`, `change-management`, `org-design` |
| Frameworks (Porter, PESTEL, SWOT, Ansoff, BMC) | `pm-product-strategy:*` |
| Commande publique (ANDRA, Lean Achats) | `expert-commande-publique` |

### Développement
| Besoin | Skill |
|---|---|
| Point d'entrée : cadrer avant de coder | `superpowers:brainstorming` → `writing-plans` → `subagent-driven-development` |
| Coder en TDD | `superpowers:test-driven-development` |
| Bug | `superpowers:systematic-debugging` |
| Ne pas déclarer « fini » sans preuve | `superpowers:verification-before-completion` |
| Revue de code | `/code-review`, `engineering:code-review`, `superpowers:requesting-code-review` |
| Documentation à jour d'une librairie | plugin `context7` |
| Tester une UI, scraper | plugin `playwright` |
| Architecture, ADR | `engineering:architecture`, `engineering:system-design` |

## Reste à faire de ton côté

- **Connecteurs à autoriser** sur claude.ai, *Settings → Connectors* : Exa (indispensable pour `exa:*`) et Microsoft 365 pour strategy-consultant. Les autres (Notion, Slack, Figma, Amplitude…) seulement si tu t'en sers.
- **Desktop Commander** : dans une session cloud, il tourne dans le conteneur, pas sur ton PC, et il n'a pas réussi à se connecter dans cette session. Pour agir sur tes fichiers locaux, lance le script depuis Claude Code ou Claude Desktop sur ta machine.
- **Optionnel, avec clé API** : Firecrawl (`firecrawl@claude-plugins-official`), Tavily (`tavily@claude-plugins-official`) et Perplexity pour du crawl ou de la recherche citée à grande échelle.

## Écartés volontairement
- `affaan-m/ECC` et `andrej-karpathy-skills` : nombre d'étoiles douteux, recouvrement avec Superpowers.
- `caveman` : dégrade l'écriture, à proscrire sur du livrable client.
- `199-biotechnologies/claude-deep-research-skill` : pas de licence, dépend d'un binaire tiers.
- Installation en bloc des 177 skills K-Dense ou des 94 plugins wshobson : chaque description occupe du contexte. Seuls les pertinents ont été retenus.
