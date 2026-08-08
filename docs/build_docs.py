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
]

# Folders whose classes are not documented at all. Retired code is honest to keep in the repo
# and unhelpful in a table of contents, where it competes with what people should actually use.
# Paths are relative to the addon root.
UNDOCUMENTED = [
    "deprecated",
    "character/components/trash",
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


def check_line_endings():
    """Stop the build if any source file has CRLF endings.

    Godot's doc comment parser leaves the carriage return on the end of a CRLF line and then
    cannot join the next line onto it. A paragraph wrapped across several ## lines arrives split,
    and reStructuredText renders each continuation as an indented blockquote. It was wrong on 21
    pages before anyone noticed, because the output is merely ugly rather than broken.

    .gitattributes pins the repo to LF, so this should never fire. It refuses to build rather
    than repairing the generated XML, because the damage starts in the source file and that is
    where it has to be fixed.
    """
    offenders = [
        str(path.relative_to(PROJECT))
        for path in sorted(ADDON.rglob("*.gd"))
        if b"\r\n" in path.read_bytes()
    ]

    if offenders:
        fail(
            "CRLF line endings in %d file(s), which mangles wrapped doc paragraphs:\n"
            "  %s\n"
            "Fix with:  git add --renormalize .  then re-checkout the tree."
            % (len(offenders), "\n  ".join(offenders))
        )


def step_xml(godot):
    print("\n[2/6] Generating FoxFabric XML from source comments")
    check_line_endings()
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

    retired = 0
    for name in undocumented_classes():
        target = XML_DIR / ("%s.xml" % name)
        if target.exists():
            target.unlink()
            retired += 1

    print("      %d classes" % (count - dropped - retired))
    if dropped:
        print("      skipped %d script(s) with no class_name" % dropped)
    if retired:
        print("      skipped %d retired class(es) in %s" % (retired, ", ".join(UNDOCUMENTED)))


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


def is_undocumented(script):
    rel = script.relative_to(ADDON).as_posix()
    return any(rel == u or rel.startswith(u + "/") for u in UNDOCUMENTED)


def undocumented_classes():
    """Class names declared inside UNDOCUMENTED folders. Their XML is discarded before the
    reStructuredText step so they never become pages, rather than becoming pages that no
    toctree references."""
    names = set()
    for script in ADDON.rglob("*.gd"):
        if not is_undocumented(script):
            continue
        text = script.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^class_name\s+(\w+)", text, re.MULTILINE)
        if match:
            names.add(match.group(1))
    return names


def scan_modules():
    """Maps every folder under the addon to the classes it declares directly.

    Returns {module: {relative_dir: [class names]}}, where relative_dir is "" for classes sitting
    at the module root. The XML does not record which file a class came from, so reading
    class_name out of the source is the only link between a class and its folder."""
    found = {}
    for script in sorted(ADDON.rglob("*.gd")):
        if is_undocumented(script):
            continue
        text = script.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^class_name\s+(\w+)", text, re.MULTILINE)
        if not match:
            continue
        rel = script.relative_to(ADDON)
        module = rel.parts[0] if len(rel.parts) > 1 else "core"
        subdir = "/".join(rel.parts[1:-1]) if len(rel.parts) > 2 else ""
        found.setdefault(module, {}).setdefault(subdir, []).append(match.group(1))
    return found


# Folder names that should not be naively title-cased.
ACRONYMS = {"gui": "GUI", "ui": "UI", "2d": "2D", "3d": "3D", "vfx": "VFX", "sfx": "SFX"}


def module_title(name):
    words = name.replace("/", " ").replace("_", " ").split()
    return " ".join(ACRONYMS.get(w.lower(), w.title()) for w in words)


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


def page_name(module, subdir):
    """Doc name for a folder page. Hyphen separates path segments, since folder names already
    contain underscores."""
    if not subdir:
        return "module_%s" % module
    return "module_%s-%s" % (module, subdir.replace("/", "-"))


def child_dirs(dirs, parent):
    """Immediate children of parent among dirs, including intermediate folders that hold no
    classes themselves but have classes further down."""
    depth = len(parent.split("/")) if parent else 0
    seen = []
    for d in dirs:
        if not d or d == parent:
            continue
        if parent and not d.startswith(parent + "/"):
            continue
        segment = "/".join(d.split("/")[: depth + 1])
        if segment != parent and segment not in seen:
            seen.append(segment)
    return seen


def write_folder_page(module, subdir, dirs, classes_at, have_page, counter):
    """Writes one page per folder, mirroring the layout on disk."""
    own = sorted("class_" + c.lower() for c in classes_at.get(subdir, []))
    own = [p for p in own if p in have_page]
    kids = child_dirs(dirs, subdir)

    if not own and not kids:
        return

    title = module_title(subdir.split("/")[-1] if subdir else module)
    body = [title, "=" * len(title), ""]

    if not subdir:
        blurb = module_blurb(module)
        if blurb:
            body += [blurb, ""]
        intro = intro_for(module)
        if intro:
            body += [intro, ""]

    # One toctree, subfolders first then classes. Two separate toctrees render as two bullet
    # lists with a gap between them, which reads as a broken list.
    entries = [page_name(module, k) for k in kids] + own
    if entries:
        body += [".. toctree::", "   :maxdepth: 1", ""]
        body += ["   " + e for e in entries]
        body.append("")

    (WEB_DIR / (page_name(module, subdir) + ".rst")).write_text("\n".join(body), encoding="utf-8")
    counter.append(page_name(module, subdir))

    for kid in kids:
        write_folder_page(module, kid, dirs, classes_at, have_page, counter)


def step_modules():
    print("\n[5/6] Grouping pages by module")
    for stale in WEB_DIR.glob("module_*.rst"):
        stale.unlink()

    have_page = {p.stem for p in WEB_DIR.glob("class_*.rst")}
    modules = scan_modules()
    written = []
    pages = []

    for name in sorted(modules, key=lambda m: (MODULE_ORDER.index(m) if m in MODULE_ORDER else 999, m)):
        classes_at = modules[name]
        dirs = sorted(classes_at)
        if not any(classes_at.values()):
            continue
        before = len(pages)
        write_folder_page(name, "", dirs, classes_at, have_page, pages)
        if len(pages) > before:
            written.append(name)

    missing_intro = [m for m in written if not intro_for(m)]
    if missing_intro:
        print("      no intro yet: %s" % ", ".join(missing_intro))

    unlisted = [m for m in written if m not in MODULE_ORDER]
    if unlisted:
        print("      WARNING: not in MODULE_ORDER, will sort last: %s" % ", ".join(unlisted))

    all_classes = {("class_" + c.lower()) for m in modules.values() for cs in m.values() for c in cs}
    orphans = sorted(have_page - all_classes)
    if orphans:
        print("      WARNING: %d page(s) in no module: %s" % (len(orphans), ", ".join(orphans)))

    endings = normalise_endings()
    if endings:
        print("      normalised line endings in %d page(s)" % endings)

    print("      %d modules, %d folder pages" % (len(written), len(pages)))


def normalise_endings():
    """Force every generated page to LF.

    Python writes text with the platform's line ending, so a Windows build produces CRLF and a
    Linux one LF. These pages are committed for Read the Docs, so without this the two disagree
    and every build looks like it changed all 87 files.
    """
    fixed = 0
    for page in list(WEB_DIR.glob("class_*.rst")) + list(WEB_DIR.glob("module_*.rst")):
        raw = page.read_bytes()
        lf = raw.replace(b"\r\n", b"\n")
        if lf != raw:
            page.write_bytes(lf)
            fixed += 1
    return fixed


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
