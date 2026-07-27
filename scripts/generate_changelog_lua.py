#!/usr/bin/env python3
"""Generate RemindersChangelog.lua from CHANGELOG.md.

The WoW client can't read files from disk at runtime, so the in-game
"What's New" window can't just display CHANGELOG.md. Instead it reads an
embedded Lua table (RemindersChangelog.lua). This script regenerates that
table from CHANGELOG.md, which stays the single source of truth.

Run it whenever you cut a release (after moving the Unreleased entries under
the new version heading in CHANGELOG.md):

    python3 scripts/generate_changelog_lua.py

Only versioned sections are included; an "## Unreleased" heading is skipped.
"""

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")
OUTPUT = os.path.join(ROOT, "RemindersChangelog.lua")

# Matches: ## [v12.4.0](https://.../tree/v12.4.0) (2026-07-27)
#   group 1 -> version ("12.4.0"), group 2 -> date ("2026-07-27")
VERSION_RE = re.compile(r"^##\s+\[v([^\]]+)\]\([^)]*\)\s*\(([^)]*)\)")


def strip_md(text):
    """Turn a Markdown bullet into plain text the WoW font can render."""
    # [label](url) -> label
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    # drop inline-code backticks
    text = text.replace("`", "")
    return text.strip()


def lua_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def parse(path):
    releases = []
    current = None
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")

            match = VERSION_RE.match(line)
            if match:
                current = {"version": match.group(1), "date": match.group(2), "entries": []}
                releases.append(current)
                continue

            # Any other H2 (e.g. "## Unreleased") ends the current release so we
            # don't attribute its bullets to a shipped version.
            if line.startswith("## "):
                current = None
                continue

            if current is not None and line.startswith("- "):
                entry = strip_md(line[2:])
                if entry:
                    current["entries"].append(entry)

    return releases


def emit(releases):
    out = [
        "-- Auto-generated from CHANGELOG.md by scripts/generate_changelog_lua.py",
        "-- Do not edit by hand; regenerate when cutting a release.",
        "",
        "Reminders.changelog = {",
    ]
    for rel in releases:
        out.append("    {")
        out.append('        version = "%s",' % lua_escape(rel["version"]))
        out.append('        date = "%s",' % lua_escape(rel["date"]))
        out.append("        entries = {")
        for entry in rel["entries"]:
            out.append('            "%s",' % lua_escape(entry))
        out.append("        },")
        out.append("    },")
    out.append("}")
    out.append("")
    return "\n".join(out)


def main():
    releases = parse(CHANGELOG)
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(emit(releases))
    print("Wrote %d releases to %s" % (len(releases), os.path.relpath(OUTPUT, ROOT)))


if __name__ == "__main__":
    main()
