#!/usr/bin/env python3
"""Fail if any Markdown file links to a file or folder in this repo that does not exist."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LINK = re.compile(r"\]\(([^)\s]+)\)")
bad = 0
for md in sorted(ROOT.rglob("*.md")):
    if ".git" in md.parts:
        continue
    for target in LINK.findall(md.read_text(encoding="utf-8")):
        if re.match(r"^(https?:|mailto:|#)", target):
            continue
        path = (md.parent / target.split("#")[0]).resolve()
        if not path.exists():
            print(f"{md.relative_to(ROOT)}: broken link -> {target}")
            bad += 1
print("All internal links resolve." if not bad else f"{bad} broken link(s).")
sys.exit(1 if bad else 0)
