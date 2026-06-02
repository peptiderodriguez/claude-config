#!/usr/bin/env python3
"""Seed ~/.claude/cache/pubmed/<PMID>.json from NCBI eutils.

Composition loop closer: the pmid_citation_guard.sh hook surfaces
"[NEEDS CACHE — run ~/.claude/scripts/seed_pubmed_cache.py <PMID>]"
violations. This script makes that fix actually doable.

Cache record shape matches the schema the hook reads (see
~/.claude/hooks/pmid_citation_guard.sh, the `cache[...] = d` line) and
the canonical fixture at
/Volumes/pool-mann-<operator>/code_bin/binder-design/tests/fixtures/pubmed_cache/10201409.json:

    {"pmid": "...", "first_author": "<Surname>", "year": "YYYY",
     "journal": "<name>", "title": "<title>"}

Stdlib-only by design (no `requests`, no `Bio.Entrez`) — runs anywhere
a system Python lives, including bare cluster login shells.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

EUTILS = ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
          "esummary.fcgi?db=pubmed&retmode=json&id={pmid}")
USER_AGENT = "claude-config-pmid-seeder/1.0"
RATE_LIMIT_S = 0.334  # ~3 req/s, NCBI no-API-key ceiling


def _surname(author_name: str) -> str:
    """'Scheffzek K' / 'Kobe B' / 'van der Berg A B' -> surname token.

    eutils gives 'Surname I[I]' (initials trailing). Strip the final
    1-3 char ALL-CAPS-or-initial token. Falls back to whole string.
    """
    s = (author_name or "").strip()
    if not s:
        return ""
    parts = s.split()
    if len(parts) >= 2 and re.fullmatch(r"[A-Z][A-Za-z]{0,2}", parts[-1]):
        return " ".join(parts[:-1])
    return s


def _year(rec: dict) -> str:
    for key in ("pubdate", "epubdate", "sortpubdate"):
        v = (rec.get(key) or "").strip()
        m = re.match(r"(\d{4})", v)
        if m:
            return m.group(1)
    return ""


def _fetch(pmid: str, timeout: float = 30.0) -> dict:
    req = urllib.request.Request(
        EUTILS.format(pmid=pmid),
        headers={"User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        payload = json.loads(r.read().decode("utf-8"))
    result = (payload or {}).get("result") or {}
    rec = result.get(pmid)
    if not rec or "error" in rec:
        raise RuntimeError(f"eutils returned no record for PMID:{pmid}")
    return rec


def _parse(pmid: str, rec: dict) -> dict:
    authors = rec.get("authors") or []
    first = ""
    for a in authors:
        nm = (a.get("name") or "").strip()
        if nm:
            first = _surname(nm)
            break
    journal = (rec.get("fulljournalname") or rec.get("source") or "").strip()
    title = (rec.get("title") or "").strip()
    return {
        "pmid": str(pmid),
        "first_author": first,
        "year": _year(rec),
        "journal": journal,
        "title": title,
    }


def _append_manifest(manifest: Path, row: dict, source: str) -> None:
    manifest.parent.mkdir(parents=True, exist_ok=True)
    header = ["pmid", "first_author", "year", "journal", "fixture",
              "used_in", "status"]
    fresh = not manifest.exists()
    with manifest.open("a", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        if fresh:
            w.writerow(header)
        w.writerow([row["pmid"], row["first_author"], row["year"],
                    row["journal"], source, "seeded-by-script", "live"])


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pmids", nargs="+", help="One or more PMIDs.")
    ap.add_argument("--cache-dir", default="~/.claude/cache/pubmed/")
    ap.add_argument("--manifest", default="~/.claude/state/citations.csv")
    ap.add_argument("--source", default=None,
                    help="Fixture/source id for the manifest row. If "
                         "omitted, the cache is seeded but no row is "
                         "appended — add the row manually.")
    ap.add_argument("--overwrite", action="store_true")
    args = ap.parse_args(argv)

    cache_dir = Path(args.cache_dir).expanduser()
    manifest = Path(args.manifest).expanduser()
    cache_dir.mkdir(parents=True, exist_ok=True)

    multi = len(args.pmids) > 1
    rc = 0
    for i, pmid in enumerate(args.pmids):
        pmid = pmid.strip()
        if not re.fullmatch(r"\d{4,9}", pmid):
            print(f"FAIL PMID:{pmid} not a numeric PMID")
            rc = 1
            continue
        out = cache_dir / f"{pmid}.json"
        if out.exists() and not args.overwrite:
            print(f"SKIP PMID:{pmid} cache exists ({out})")
            continue
        if multi and i > 0:
            time.sleep(RATE_LIMIT_S)
        try:
            rec = _fetch(pmid)
            row = _parse(pmid, rec)
        except (urllib.error.URLError, urllib.error.HTTPError,
                json.JSONDecodeError, RuntimeError, TimeoutError) as e:
            print(f"FAIL PMID:{pmid} {type(e).__name__}: {e}")
            rc = 1
            continue
        out.write_text(json.dumps(row, indent=2, ensure_ascii=False) + "\n",
                       encoding="utf-8")
        if args.source:
            _append_manifest(manifest, row, args.source)
            tail = f" (+manifest row, source={args.source})"
        else:
            tail = "  [NEEDS ROW — add manifest row manually]"
        print(f"OK PMID:{pmid} cached as "
              f"{row['first_author']} {row['year']} {row['journal']}{tail}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
