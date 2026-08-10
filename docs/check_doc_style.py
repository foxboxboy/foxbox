"""Checks the class doc comments against the conventions in CONTRIBUTING.md.

    python docs/check_doc_style.py

Exits non-zero and prints file:line for every failure. CI runs it before the slow steps.

These rules come from Godot's own writing guidelines, not from taste:
https://contributing.godotengine.org/en/latest/documentation/guidelines/docs_writing_guidelines.html

The checks are deliberately narrow. A style check that fires on correct code gets switched off, so
each one is built to have no false positives on the current tree and to miss cases rather than
invent them.
"""

import re
import sys
from pathlib import Path

ADDON = Path(__file__).resolve().parent.parent / "addons" / "foxfabric"

# Excluded from the published reference by docs/build_docs.py, so its prose never ships.
SKIP_DIRS = ("character/components/trash",)

# Godot bans these eight outright.
BANNED = ("obvious", "simple", "basic", "easy", "actual", "just", "clear", "however")

# A class summary says what the class is. A summary opening with one of these is describing what it
# does, which is the form Godot reserves for methods. Only third person verbs seen in this project
# or common enough to expect; the list misses new ones rather than guessing at them.
VERBS = (
    "Acts", "Adds", "Applies", "Builds", "Calculates", "Calls", "Carries", "Checks", "Connects",
    "Contains", "Controls", "Converts", "Creates", "Delivers", "Draws", "Emits", "Handles",
    "Holds", "Keeps", "Loads", "Locks", "Maintains", "Makes", "Manages", "Manipulates", "Moves",
    "Places", "Positions", "Provides", "Reads", "Receives", "Registers", "Removes", "Renders",
    "Reports", "Returns", "Rotates", "Routes", "Sends", "Sets", "Stores", "Tracks", "Updates",
    "Wraps", "Writes",
)

# A description is a paragraph, not a continuation of the line above it. Opening on a pronoun
# leaves the subject in the summary, where a reader skimming to the description never sees it.
PRONOUNS = ("It ", "They ", "These ", "Its ", "Their ")


def doc_block(lines):
    """The ## block introducing the class, as (summary_lines, description_lines, first_line_no)."""
    start = None
    for i, line in enumerate(lines):
        if re.match(r"^(class_name|extends|@icon|@tool)\b", line):
            start = i
        elif start is not None and line.startswith("##"):
            break
        elif start is not None and line.strip():
            return [], [], 0

    if start is None:
        return [], [], 0

    block = []
    for i in range(start + 1, len(lines)):
        if not lines[i].startswith("##"):
            break
        block.append((i + 1, lines[i]))

    summary, description, seen_gap = [], [], False
    for no, text in block:
        if text.strip() == "##":
            seen_gap = True
            continue
        (description if seen_gap else summary).append((no, text[3:].rstrip()))

    return summary, description, block[0][0] if block else 0


def banned_hits(text):
    """Banned words in prose. A word inside backticks or quotes is a name, not prose."""
    stripped = re.sub(r"`[^`]*`|\"[^\"]*\"", " ", text)
    return [w for w in BANNED if re.search(r"\b%s(ly)?\b" % w, stripped, re.I)]


def main():
    failures = []

    for path in sorted(ADDON.rglob("*.gd")):
        rel = path.relative_to(ADDON).as_posix()
        if any(rel.startswith(d) for d in SKIP_DIRS):
            continue

        # Every .gd with a doc comment, not only the ones that publish. The editor scripts carry no
        # class_name and so reach no generated page, but they are read by whoever maintains them and
        # the conventions apply the same.
        lines = path.read_text(encoding="utf-8").splitlines()

        # Banned words anywhere in a ## comment, skipping example code inside [codeblock].
        in_code = False
        for no, line in enumerate(lines, 1):
            if not line.startswith("##"):
                continue
            if "[codeblock" in line:
                in_code = True
            if "[/codeblock" in line:
                in_code = False
                continue
            if in_code:
                continue
            for word in banned_hits(line[2:]):
                failures.append((rel, no, 'banned word "%s"' % word))

        summary, description, _ = doc_block(lines)

        if summary:
            no, text = summary[0]
            first = text.split(" ")[0] if text else ""
            if first in VERBS:
                failures.append((rel, no, 'summary opens on the verb "%s"; say what the class is' % first))

        if description:
            no, text = description[0]
            first = text.split(" ")[0] if text else ""
            if first in VERBS:
                failures.append((rel, no, 'description opens on the verb "%s"; name the subject' % first))
            elif any(text.startswith(p) for p in PRONOUNS):
                failures.append((rel, no, "description opens on a pronoun; name the subject"))

    if not failures:
        print("Doc comments match CONTRIBUTING.md.")
        return 0

    print("::error::%d doc comment problem(s). See CONTRIBUTING.md." % len(failures))
    print()
    for rel, no, why in failures:
        print("    addons/foxfabric/%s:%s" % (rel, no))
        print("        %s" % why)
    return 1


if __name__ == "__main__":
    sys.exit(main())
