#!/bin/bash
# PostToolUse hook: structured PMID citation guard. After any Write/Edit on
# a markdown / tex / yaml file, scan for PMID tokens and verify each against
# a STRUCTURED citation manifest (DataFrame-shaped CSV) joined to a local
# PubMed cache. Modeled on binder-design's data/citations.csv ⋈ pubmed_cache
# pattern — see /Volumes/pool-mann-<operator>/code_bin/binder-design/src/design-cli/
# citation_table.py for the rationale ("stop parsing — citation identity is
# STRUCTURED DATA, not text proximity"). Surfaces additionalContext for
# violations; does NOT block (the file is already written). Set
# CLAUDE_PMID_GUARD_STRICT=1 to escalate to permissionDecision=ask.
#
# Cache lookup precedence: per-repo (<repo>/tests/fixtures/pubmed_cache/,
# <repo>/data/citations.csv) → global (~/.claude/cache/pubmed/,
# ~/.claude/state/citations.csv).
#
# To disable: comment out the matcher in ~/.claude/settings.json.

set -u
input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
[ -z "$fp" ] && exit 0
[ -f "$fp" ] || exit 0

# Only audit text artifacts where prose-PMID assertions are load-bearing.
# Lowercase the extension once so we don't have to enumerate case variants.
fp_lc=$(echo "$fp" | tr '[:upper:]' '[:lower:]')
case "$fp_lc" in
  *.md|*.markdown|*.mdx|*.tex|*.yaml|*.yml|*.rst|*.txt|*.adoc|*.ipynb) ;;
  *) exit 0 ;;
esac

# Walk up from the file to find an in-repo manifest+cache; else fall back
# to the global ~/.claude/ pair.
find_upward() {
  local start_dir="$1" rel="$2"
  local d="$start_dir"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -e "$d/$rel" ]; then printf '%s\n' "$d/$rel"; return 0; fi
    d=$(dirname "$d")
  done
  return 1
}

file_dir=$(dirname "$fp")
csv_path=$(find_upward "$file_dir" "data/citations.csv" || true)
[ -z "${csv_path:-}" ] && csv_path=$(find_upward "$file_dir" ".citations.csv" || true)
cache_dir=$(find_upward "$file_dir" "tests/fixtures/pubmed_cache" || true)

GLOBAL_CSV="${HOME}/.claude/state/citations.csv"
GLOBAL_CACHE="${HOME}/.claude/cache/pubmed"
[ -z "${csv_path:-}" ] && [ -f "$GLOBAL_CSV" ] && csv_path="$GLOBAL_CSV"
[ -z "${cache_dir:-}" ] && [ -d "$GLOBAL_CACHE" ] && cache_dir="$GLOBAL_CACHE"

# Extract PMIDs from the file: PMID:NNNNNNN  OR  pmid.ncbi.nlm.nih.gov/NNNNNNN
pmids=$(grep -oE '(PMID:?\s*[0-9]{6,9}|pmid\.ncbi\.nlm\.nih\.gov/[0-9]{6,9})' "$fp" 2>/dev/null \
         | grep -oE '[0-9]{6,9}' | sort -u)
[ -z "$pmids" ] && exit 0

# Bootstrap fail-loud — no manifest AND no cache anywhere. Fixing this
# silently would defeat the point. Surface the seed-cache handoff.
if [ -z "${csv_path:-}" ] && [ -z "${cache_dir:-}" ]; then
  n=$(printf '%s\n' "$pmids" | wc -l | tr -d ' ')
  msg=$'PMID guard: '"$n"$' PMID(s) found in '"$fp"$' but NO structured citation manifest is reachable.\n\nFile a citations.csv next to the file (DataFrame columns: pmid,first_author,year,journal,fixture,used_in,status) OR initialize the global manifest:\n  mkdir -p ~/.claude/state ~/.claude/cache/pubmed\n  echo "pmid,first_author,year,journal,fixture,used_in,status" > ~/.claude/state/citations.csv\n  python ~/.claude/scripts/seed_pubmed_cache.py '"$(printf '%s ' $pmids)"$'\n\nRationale: binder-design src/design-cli/citation_table.py — citation identity is STRUCTURED DATA, not prose proximity.'
  jq -nc --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
  exit 0
fi

# Compute the SOURCE id for the manifest lookup: the file's path relative to
# the manifest's root (deterministic; no parsing).
if [ -n "${csv_path:-}" ] && [ "$csv_path" != "$GLOBAL_CSV" ]; then
  csv_root=$(dirname "$(dirname "$csv_path")")  # strip data/citations.csv
  src_id=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$fp" "$csv_root" 2>/dev/null)
else
  src_id="$fp"  # global manifest — absolute path is the source id
fi

# Inline Python join — stdlib only (no pandas in the hook venv). Mirrors
# audit_citations() from binder-design citation_table.py: join claim ⋈ cache
# on pmid; flag uncached-live and (author|year|journal) mismatches.
violations=$(CSV="${csv_path:-}" CACHE="${cache_dir:-}" SRC="$src_id" PMIDS="$pmids" python3 - <<'PY' 2>/dev/null
import csv, json, os, re, sys, unicodedata
from pathlib import Path

csv_path = os.environ.get("CSV") or ""
cache_dir = os.environ.get("CACHE") or ""
src_id    = os.environ.get("SRC", "?")
pmids     = [p for p in os.environ.get("PMIDS","").split() if p]

def deacc(s): return "".join(c for c in unicodedata.normalize("NFKD", s or "") if not unicodedata.combining(c))
def norm_au(s):
    s = deacc((s or "").strip().lower())
    s = re.sub(r"\s+et\s+al\.?$", "", s)
    s = re.sub(r"\s*[&/].*$", "", s)
    return s.split()[0] if s.split() else ""
def journal_ok(c, t):
    cj, tj = deacc((c or "").lower()), deacc((t or "").lower())
    if not cj: return True
    if not tj: return False
    if cj in tj or tj in cj: return True
    stop = {"the","of","and","for","in","a","an"}
    ct = [x for x in re.split(r"[^a-z0-9]+", cj) if x and x not in stop]
    rt = [x for x in re.split(r"[^a-z0-9]+", tj) if x and x not in stop]
    if not ct or not rt: return False
    if len(ct) >= 2 and len(ct) <= len(rt) and all(rt[i].startswith(ct[i]) for i in range(len(ct))):
        return True
    if len(ct) == 1 and 2 <= len(ct[0]) <= 6 and ct[0].isalpha():
        if "".join(t[0] for t in rt).startswith(ct[0]): return True
    return False

rows = []
if csv_path and Path(csv_path).exists():
    with open(csv_path, newline="", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))

by_pmid = {}
for r in rows:
    by_pmid.setdefault(str(r.get("pmid","")).strip(), []).append(r)

cache = {}
if cache_dir and Path(cache_dir).is_dir():
    for f in Path(cache_dir).glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
            cache[str(d.get("pmid") or f.stem).strip()] = d
        except Exception:
            pass

out = []
for p in pmids:
    rows_for = by_pmid.get(p, [])
    rrow = None
    for r in rows_for:
        fx = r.get("fixture","")
        if fx == src_id or fx in src_id or src_id in fx:
            rrow = r; break
    if rrow is None and rows_for:
        rrow = rows_for[0]
    if rrow is None:
        out.append(f"PMID:{p}  no row in manifest for source={src_id}  [NEEDS ROW — add (pmid={p},fixture={src_id}) to {csv_path or '~/.claude/state/citations.csv'}]")
        continue
    status = (rrow.get("status","") or "live").strip().lower()
    if status == "demoted":
        continue
    rec = cache.get(p)
    if rec is None:
        if status == "pending_cache":
            continue
        out.append(f"PMID:{p}  status=live but NO cache entry  [NEEDS CACHE — run ~/.claude/scripts/seed_pubmed_cache.py {p}]")
        continue
    ca, ta = norm_au(rrow.get("first_author","")), norm_au(rec.get("first_author",""))
    if ca and ta and ca != ta and ca not in ta and ta not in ca:
        out.append(f"PMID:{p}  first_author MISMATCH  claim={rrow.get('first_author','')!r} vs cache={rec.get('first_author','')!r}")
    cy, ty = str(rrow.get("year","")).strip(), str(rec.get("year","")).strip()
    if cy and ty and cy != ty:
        out.append(f"PMID:{p}  year MISMATCH  claim={cy} vs cache={ty}")
    if not journal_ok(rrow.get("journal",""), rec.get("journal","")):
        out.append(f"PMID:{p}  journal MISMATCH  claim={rrow.get('journal','')!r} vs cache={rec.get('journal','')!r}")

if out:
    print("\n".join(out))
PY
)

[ -z "$violations" ] && exit 0

msg=$'PMID citation guard — violations in '"$fp"$' (structured manifest: '"${csv_path:-<none>}"$', cache: '"${cache_dir:-<none>}"$'):\n\n'"$violations"$'\n\nRationale: the manifest is a DataFrame (pmid,first_author,year,journal,fixture,used_in,status). Fix by either adding/correcting the row, demoting via status=demoted, or marking status=pending_cache (operator handoff). Do NOT silently delete the PMID from prose — that hides the gap.'

if [ "${CLAUDE_PMID_GUARD_STRICT:-0}" = "1" ]; then
  jq -nc --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",permissionDecision:"ask",permissionDecisionReason:$msg}}'
else
  jq -nc --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
fi
exit 0
