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
import re
import shutil
import subprocess
import sys
import webbrowser
from pathlib import Path

DOCS = Path(__file__).resolve().parent
PROJECT = DOCS.parent
ADDON = PROJECT / "addons" / "foxfabric"

# Sidebar order, foundational first. A module missing from here still gets a page, and the build
# prints a warning so it does not silently vanish from the sidebar.
MODULE_ORDER = [
    "core",
    "attribute_map",
    "effect",
    "state_machine",
    "shop",
    "socket",
    "damage",
    "interaction",
    "aim_gimbal",
    "zoom_spring_arm",
    "physics_dragging",
    "view_model",
    "world_environments",
    "character",
    "deprecated",
]
XML_DIR = DOCS / "xml_output"
# make_rst.py resolves every type against the classes it is given, so it needs the built-in
# engine documentation too, or float, Node3D and friends all come back unresolved. Kept in a
# separate folder so --filter can restrict output to our classes only.
XML_ENGINE = DOCS / "xml_engine"
RST_DIR = DOCS / "rst_output"
WEB_DIR = DOCS / "web"
# Hand written prose, one file per module, spliced into the generated module pages so that
# regenerating never destroys anything a human wrote.
INTROS = WEB_DIR / "intros"
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
    print("\n[1/6] Engine class reference")
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
    print("\n[2/6] Generating FoxFabric XML from source comments")
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
    print("\n[3/6] Converting XML to reStructuredText")
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
    print("\n[4/6] Collecting pages into web/")
    for stale in WEB_DIR.glob("class_*.rst"):
        stale.unlink()
    count = 0
    for page in sorted(RST_DIR.glob("class_*.rst")):
        shutil.copy2(page, WEB_DIR / page.name)
        count += 1
    # index.rst is hand written and uses a glob toctree, so it never needs regenerating
    print("      %d pages copied" % count)


def scan_modules():
    """Maps each module folder to the classes it declares, by reading class_name out of the
    source. The XML does not record which folder a class came from, so this is the only link
    between a class and the module it belongs to."""
    found = {}
    for script in sorted(ADDON.rglob("*.gd")):
        rel = script.relative_to(ADDON)
        module = rel.parts[0] if len(rel.parts) > 1 else "core"
        text = script.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^class_name\s+(\w+)", text, re.MULTILINE)
        if match:
            found.setdefault(module, []).append(match.group(1))
    return found


def module_title(name):
    return name.replace("_", " ").title()


def module_blurb(name):
    """Reuses the module's own README.txt so the site and the repo cannot disagree."""
    readme = ADDON / name / "README.txt"
    if not readme.exists():
        return ""
    first = readme.read_text(encoding="utf-8", errors="replace").strip().split("\n\n")[0]
    first = " ".join(first.split())
    # strip the "Name: " prefix the module READMEs all start with
    return re.sub(r"^[A-Za-z ]+:\s*", "", first)


def intro_for(name):
    """Hand written prose for a module, kept in web/intros/ so regenerating a module page never
    overwrites it. Returns an empty string when there is none."""
    path = INTROS / ("%s.rst" % name)
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8").strip()


def step_modules():
    print("\n[5/6] Grouping pages by module")
    for stale in WEB_DIR.glob("module_*.rst"):
        stale.unlink()

    have_page = {p.stem for p in WEB_DIR.glob("class_*.rst")}
    modules = scan_modules()
    written = []

    for name in sorted(modules, key=lambda m: (MODULE_ORDER.index(m) if m in MODULE_ORDER else 999, m)):
        pages = sorted("class_" + c.lower() for c in modules[name])
        pages = [p for p in pages if p in have_page]
        if not pages:
            continue

        title = module_title(name)
        body = [title, "=" * len(title), ""]

        blurb = module_blurb(name)
        if blurb:
            body += [blurb, ""]

        intro = intro_for(name)
        if intro:
            body += [intro, ""]

        body += [".. toctree::", "   :maxdepth: 1", "   :caption: Classes", ""]
        body += ["   " + p for p in pages]
        body.append("")

        (WEB_DIR / ("module_%s.rst" % name)).write_text("\n".join(body), encoding="utf-8")
        written.append(name)

    missing_intro = [m for m in written if not intro_for(m)]
    if missing_intro:
        print("      no intro yet: %s" % ", ".join(missing_intro))

    unlisted = [m for m in written if m not in MODULE_ORDER]
    if unlisted:
        print("      WARNING: not in MODULE_ORDER, will sort last: %s" % ", ".join(unlisted))

    orphans = sorted(have_page - {("class_" + c.lower()) for cs in modules.values() for c in cs})
    if orphans:
        print("      WARNING: %d page(s) in no module: %s" % (len(orphans), ", ".join(orphans)))

    print("      %d modules" % len(written))


def step_html():
    print("\n[6/6] Building HTML")
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
    step_modules()

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
