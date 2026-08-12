"""Checks the module table in README.md against each module's own README.txt.

    python docs/check_module_blurbs.py

Exits non-zero and prints what disagrees. CI runs it before the slow steps.

README.md says the two are the same text, and docs/build_docs.py copies the README.txt line onto
the generated module page. Nothing kept them in step, so editing one left the website and the
README quietly disagreeing. This is what the claim rests on.
"""

import io
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / "addons" / "foxfabric"
README = ROOT / "README.md"

# | `socket` | 2D and 3D | Named seats a node attaches to, one occupant each. ... |
ROW = re.compile(r"^\| `([a-z_0-9]+)` \| [^|]+ \| (.*?) \|$", re.M)


def blurb(module):
    """The module's own description, with the label its README.txt opens with removed."""
    path = ADDON / module / "README.txt"
    if not path.exists():
        return None
    first = io.open(path, encoding="utf-8", newline="").read().split("\n")[0]
    return first.split(": ", 1)[1] if ": " in first else first


def main():
    rows = dict(ROW.findall(io.open(README, encoding="utf-8", newline="").read()))
    modules = sorted(p.name for p in ADDON.iterdir() if p.is_dir())

    failures = []

    for module in modules:
        described = blurb(module)
        if described is None:
            failures.append("%s has no README.txt" % module)
        elif module not in rows:
            failures.append("%s is not in the README.md table" % module)
        elif rows[module] != described:
            failures.append(
                "%s reads differently in the two places\n"
                "        README.md:  %s\n"
                "        README.txt: %s" % (module, rows[module], described)
            )

    for module in sorted(rows):
        if module not in modules:
            failures.append("the README.md table has a row for %s, which is not a module" % module)

    if not failures:
        print("Module blurbs match README.md.")
        return 0

    print("::error::%d module blurb problem(s)." % len(failures))
    print()
    for failure in failures:
        print("    %s" % failure)
    return 1


if __name__ == "__main__":
    sys.exit(main())
