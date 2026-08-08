#!/usr/bin/env python3
"""Builds the FoxFabric API docs, from source comments through to browsable HTML.

    python docs/build_docs.py              full build
    python docs/build_docs.py --skip-html  stop before Sphinx
    python docs/build_docs.py --open       open the result in a browser

Needs Godot, plus sphinx and sphinx-rtd-theme for the final step:

    pip install sphinx sphinx-rtd-theme

Point FOXFABRIC_GODOT at the Godot binary if it is not on PATH.
"""

import argparse
import os
import shutil
import subprocess
import sys
import webbrowser
from pathlib import Path

DOCS = Path(__file__).resolve().parent
PROJECT = DOCS.parent
XML_DIR = DOCS / "xml_output"
RST_DIR = DOCS / "rst_output"
WEB_DIR = DOCS / "web"
HTML_DIR = WEB_DIR / "_build" / "html"

# Only this folder is documented. Pointing doctool at the whole project sweeps in every other
# addon, which is how GodotDoctor and Todo_Manager classes ended up in an earlier build.
SOURCE = "res://addons/foxfabric"


def fail(message):
    print("\n  " + message + "\n", file=sys.stderr)
    sys.exit(1)


def find_godot():
    candidate = os.environ.get("FOXFABRIC_GODOT")
    if candidate and Path(candidate).exists():
        return candidate
    found = shutil.which("godot") or shutil.which("godot.exe")
    if found:
        return found
    fail(
        "Could not find Godot.\n"
        '  Set it with:  FOXFABRIC_GODOT="/path/to/godot"'
    )


def run(cmd, cwd=None):
    print("  >", " ".join(str(c) for c in cmd))
    result = subprocess.run([str(c) for c in cmd], cwd=cwd)
    if result.returncode != 0:
        fail("Command failed with exit code %d." % result.returncode)


def reset(path):
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def step_xml(godot):
    print("\n[1/4] Generating class XML from source comments")
    reset(XML_DIR)
    run([
        godot, "--headless", "--path", PROJECT,
        "--doctool", XML_DIR,
        "--no-docbase",
        "--gdscript-docs", SOURCE,
    ])
    count = len(list(XML_DIR.glob("*.xml")))
    if count == 0:
        fail("Godot produced no XML. Has the project been imported at least once?")
    print("      %d classes" % count)


def step_rst():
    print("\n[2/4] Converting XML to reStructuredText")
    reset(RST_DIR)
    # make_rst.py puts the repo root on sys.path so it can "import version"
    run([sys.executable, DOCS / "tools" / "make_rst.py", XML_DIR, "--output", RST_DIR], cwd=DOCS)
    print("      %d pages" % len(list(RST_DIR.glob("class_*.rst"))))


def step_collect():
    print("\n[3/4] Collecting pages into web/")
    for stale in WEB_DIR.glob("class_*.rst"):
        stale.unlink()
    count = 0
    for page in sorted(RST_DIR.glob("class_*.rst")):
        shutil.copy2(page, WEB_DIR / page.name)
        count += 1
    # index.rst is hand written and uses a glob toctree, so it never needs regenerating
    print("      %d pages copied" % count)


def step_html():
    print("\n[4/4] Building HTML")
    if shutil.which("sphinx-build") is None:
        fail(
            "sphinx-build is not on PATH.\n"
            "  Install it with:  pip install sphinx sphinx-rtd-theme\n"
            "  Or rerun with --skip-html to stop after the reStructuredText step."
        )
    run(["sphinx-build", "-b", "html", WEB_DIR, HTML_DIR])


def main():
    parser = argparse.ArgumentParser(description="Build the FoxFabric API docs.")
    parser.add_argument("--skip-html", action="store_true", help="stop before Sphinx")
    parser.add_argument("--open", action="store_true", help="open the result in a browser")
    args = parser.parse_args()

    godot = find_godot()
    step_xml(godot)
    step_rst()
    step_collect()

    if args.skip_html:
        print("\nStopped before Sphinx. reStructuredText is in %s\n" % RST_DIR)
        return

    step_html()
    landing = HTML_DIR / "index.html"
    print("\nDone. Open %s\n" % landing)
    if args.open:
        webbrowser.open(landing.as_uri())


if __name__ == "__main__":
    main()
