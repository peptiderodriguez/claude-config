#!/usr/bin/env python3
"""Anonymize the public repo from a single mapping file (anonymize_map.tsv).

Three modes:
  anonymize.py                 stdin -> stdout (filter a stream)
  anonymize.py --apply DIR     in-place anonymize tracked text files under DIR
  anonymize.py --check DIR     fail-closed gate: exit 1 if any real identifier
                               (a rule's pattern) still appears under DIR

The map is the source of truth — add a row there when a new project/identifier
appears. Rules apply longest-pattern-first so specific patterns win over prefixes.
sync.sh runs --apply then --check; a GitHub Action runs --check on every push.
"""
import argparse
import os
import re
import sys
from pathlib import Path

MAP_PATH = Path(__file__).resolve().parent / "anonymize_map.tsv"
# Files that legitimately contain the real tokens (skip in --apply and --check).
SELF_SKIP = {"anonymize_map.tsv", "anonymize.py"}
TEXT_EXT = {".md", ".sh", ".json", ".py", ".yml", ".yaml", ".cff", ".txt", ".tsv"}
EXTRA_TEXT_NAMES = {"LICENSE"}
# Known generic codenames that are allowed to appear after code_bin/ (so the
# --check heuristic doesn't flag the genericized ones as "unknown projects").
KNOWN_GENERIC = {
    "binder-design", "imaging-seg", "proteomics-quant", "clinical-omics",
    "clinical-omics-2", "grant-repo", "quant-runner", "session-a", "session-b",
    "aging-study", "clinical-cohort", "model-trainer", "structure-tool",
    "design-cli", "library-gen", "claude-config", "<project>",
    "_shared", "proj",  # benign: shared-dir convention + a test fixture token
}


def load_rules():
    rules = []  # (pattern, replacement, is_regex)
    for raw in MAP_PATH.read_text().splitlines():
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            sys.stderr.write(f"anonymize: bad map line (need 3 tab-cols): {line!r}\n")
            sys.exit(2)
        mode, pattern, replacement = parts
        rules.append((pattern, replacement, mode == "re"))
    # longest pattern first so specific rules win over prefixes
    rules.sort(key=lambda r: len(r[0]), reverse=True)
    return rules


def anonymize_text(text, rules):
    for pattern, replacement, is_regex in rules:
        if is_regex:
            text = re.sub(pattern, replacement, text)
        else:
            text = text.replace(pattern, replacement)
    return text


def is_text_file(p: Path):
    if p.name in SELF_SKIP:
        return False
    if p.name in EXTRA_TEXT_NAMES:
        return True
    return p.suffix in TEXT_EXT


def iter_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in (".git", "site", "node_modules")]
        for name in filenames:
            p = Path(dirpath) / name
            if is_text_file(p):
                yield p


def cmd_apply(root: Path, rules):
    changed = 0
    for p in iter_files(root):
        try:
            orig = p.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        new = anonymize_text(orig, rules)
        if new != orig:
            p.write_text(new)
            changed += 1
    print(f"anonymize: applied map to {changed} file(s) under {root}")
    return 0


def cmd_check(root: Path, rules):
    # find any rule pattern still present (a real identifier leaked into the repo)
    leaks = []
    code_bin_unknown = {}
    cb_re = re.compile(r"code_bin/([A-Za-z0-9_\-]+)")
    for p in iter_files(root):
        try:
            lines = p.read_text().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        rel = p.relative_to(root)
        for i, line in enumerate(lines, 1):
            for pattern, _replacement, is_regex in rules:
                hit = re.search(pattern, line) if is_regex else (pattern in line)
                if hit:
                    leaks.append((rel, i, pattern, line.strip()[:120]))
            for m in cb_re.finditer(line):
                tok = m.group(1)
                if tok not in KNOWN_GENERIC and not tok.startswith("<"):
                    code_bin_unknown.setdefault(tok, (rel, i))
    if code_bin_unknown:
        print("anonymize: WARN — unknown code_bin/<name> tokens (add a map rule if these are real project names):", file=sys.stderr)
        for tok, (rel, i) in sorted(code_bin_unknown.items()):
            print(f"  code_bin/{tok}  ({rel}:{i})", file=sys.stderr)
    if leaks:
        print(f"anonymize: CHECK FAILED — {len(leaks)} real-identifier occurrence(s) present:", file=sys.stderr)
        for rel, i, pattern, snippet in leaks[:50]:
            print(f"  {rel}:{i}  [{pattern}]  {snippet}", file=sys.stderr)
        if len(leaks) > 50:
            print(f"  … and {len(leaks) - 50} more", file=sys.stderr)
        return 1
    print(f"anonymize: check passed — no mapped identifiers found under {root}")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Anonymize the public repo from anonymize_map.tsv")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--apply", metavar="DIR", help="in-place anonymize text files under DIR")
    g.add_argument("--check", metavar="DIR", help="exit 1 if any mapped identifier appears under DIR")
    args = ap.parse_args()
    rules = load_rules()
    if args.apply:
        sys.exit(cmd_apply(Path(args.apply).resolve(), rules))
    if args.check:
        sys.exit(cmd_check(Path(args.check).resolve(), rules))
    # default: stream filter
    sys.stdout.write(anonymize_text(sys.stdin.read(), rules))


if __name__ == "__main__":
    main()
