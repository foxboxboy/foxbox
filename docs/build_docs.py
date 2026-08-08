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
# make_rst.py resolves every type against the classes it is given, so it needs the built-in
# engine documentation too, or float, Node3D and friends all come back unresolved. Kept in a
# separate folder so --filter can restrict output to our classes only.
XML_ENGINE = DOCS / "xml_engine"
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


def engine_count():
    if not XML_ENGINE.exists():
        return 0
    return len(list(XML_ENGINE.rglob("*.xml")))


def engine_paths():
    """The three roots doctool writes to. make_rst.py treats 'modules' and 'platform'
    specially, walking them for doc_classes folders, so they are passed by name."""
    return [
        XML_ENGINE / "doc" / "classes",
        XML_ENGINE / "modules",
        XML_ENGINE / "platform",
    ]


def step_engine_xml(godot, force=False):
    print("\n[1/4] Engine class reference")
    if engine_count() > 0 and not force:
        print("      cached, %d classes (--refresh-engine to redo)" % engine_count())
        return
    reset(XML_ENGINE)
    # doctool lays these out like the Godot source tree: doc/classes, modules/*/doc_classes
    # and platform/*/doc_classes, not one flat folder.
    run([godot, "--headless", "--path", PROJECT, "--doctool", XML_ENGINE])
    if engine_count() == 0:
        fail("Godot wrote no engine XML to %s" % XML_ENGINE)
    print("      %d classes" % engine_count())


def step_xml(godot):
    print("\n[2/4] Generating FoxFabric XML from source comments")
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

    # Scripts with no class_name get named after their file path, so they produce pages titled
    # "addons/foxfabric/..." that sort above every real class. Godot's own editor help does not
    # list them either, so drop them and stay consistent with it.
    dropped = 0
    for stray in XML_DIR.glob("addons--*.xml"):
        stray.unlink()
        dropped += 1

    print("      %d classes" % (count - dropped))
    if dropped:
        print("      skipped %d script(s) with no class_name" % dropped)


def step_rst():
    print("\n[3/4] Converting XML to reStructuredText")
    reset(RST_DIR)
    # Both folders go in so types resolve, but --filter keeps the output to ours.
    # make_rst.py puts the repo root on sys.path so it can "import version".
    run([
        sys.executable, DOCS / "tools" / "make_rst.py",
        *engine_paths(), XML_DIR,
        "--output", RST_DIR,
        "--filter", XML_DIR.name,
    ], cwd=DOCS)
    print("      %d pages" % len(list(RST_DIR.glob("class_*.rst"))))


def step_collect():
    print("\n[4/4] Collecting pages into web/")
    for stale in WEB_DIR.glob("class_*.rst"):
        stale.unlink()
    count = 0
    for page in sorted(RST_DIR.glob("class_*.rst")):
        shutil.copy2(page, WEB_DIR / page.name)
        count += 1
    # index.rst is hand written and uses a glob toctree, so it never needs regenerating
    print("      %d pages copied" % count)


def step_html():
    print("\n[5/5] Building HTML")
    # Invoked as a module rather than the sphinx-build binary, which only works when the
    # interpreter's Scripts directory happens to be on PATH.
    probe = subprocess.run(
        [sys.executable, "-c", "import sphinx, sphinx_rtd_theme"],
        capture_output=True,
    )
    if probe.returncode != 0:
        fail(
            "Sphinx is not installed for this interpreter (%s).\n"
            "  Install it with:  pip install sphinx sphinx-rtd-theme\n"
            "  Or rerun with --skip-html to stop after the reStructuredText step."
            % sys.executable
        )
    run([sys.executable, "-m", "sphinx", "-b", "html", WEB_DIR, HTML_DIR])


def main():
    parser = argparse.ArgumentParser(description="Build the FoxFabric API docs.")
    parser.add_argument("--skip-html", action="store_true", help="stop before Sphinx")
    parser.add_argument("--open", action="store_true", help="open the result in a browser")
    parser.add_argument("--refresh-engine", action="store_true",
                        help="re-dump the engine class reference (only needed after a Godot upgrade)")
    args = parser.parse_args()

    godot = find_godot()
    step_engine_xml(godot, force=args.refresh_engine)
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
