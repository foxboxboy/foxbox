Docs: Builds a browsable web version of the FoxFabric API from the ## comments in the source,
using Godot's own documentation tooling. Same text as the in-editor help, so the two cannot
disagree.


BUILDING

    pip install sphinx sphinx-rtd-theme
    python docs/build_docs.py --open

That runs four steps. Godot reads the ## comments and writes class XML, make_rst.py converts
that to reStructuredText, the pages are copied into web/, and Sphinx renders HTML into
web/_build/html.

Without sphinx installed you can still do the first three:

    python docs/build_docs.py --skip-html

Set FOXFABRIC_GODOT if godot is not on PATH. The project must have been imported at least
once, otherwise Godot has no class list to document.


HOSTING

Read the Docs, the same host the Godot documentation uses, which is where the version and
language flyout in the bottom corner comes from.

Read the Docs has no Godot to run, so it can only render reStructuredText that is already in
the repo. That is why class_*.rst and module_*.rst are tracked rather than ignored, and it is
how the engine's own docs work too.

Keeping them current is on you. Change a ## comment and regenerate in the same commit:

    python docs/build_docs.py --skip-html

.github/workflows/docs.yml checks this on every push that touches addons/ or docs/, and fails
if the committed pages no longer match the source. It used to regenerate and push them back
itself, which moved main under whoever had just pushed to it, and left the published pages
wrong until the job finished.

Connect the repo once at https://readthedocs.org and it publishes on every push to main.


THE STEPS BY HAND

If the script gets in the way, this is all it does:

    godot --headless --path . --doctool docs/xml_output --no-docbase \
          --gdscript-docs res://addons/foxfabric

    python docs/tools/make_rst.py docs/xml_output --output docs/rst_output

    cp docs/rst_output/class_*.rst docs/web/
    cd docs/web && make html

--no-docbase skips the roughly one thousand built-in engine classes. --gdscript-docs limits
the run to one folder, which matters: pointing doctool at the whole project documents every
other addon in addons/ as though it belonged to FoxFabric. An earlier build shipped fifty
GodotDoctor classes that way.


WHAT IS TRACKED

The tooling, the hand written pages, and the generated pages Read the Docs renders:

    build_docs.py            the six step build
    tools/make_rst.py        Godot's XML to reStructuredText converter
    tools/doc_status.py      coverage report for documented classes
    tools/misc/utility/      colour helpers, imported by both scripts
    tools/version.py         version stamp the converter imports
    web/index.rst            landing page
    web/conf.py              Sphinx settings
    web/Makefile, make.bat   Sphinx entry points
    web/_static/             css and logos
    web/class_*.rst          generated, tracked only because Read the Docs cannot make them
    web/module_*.rst         generated, same reason

The intermediate output stays ignored:

    xml_output/              class XML from Godot
    rst_output/              converted reStructuredText
    web/_build/              final HTML

A local build will therefore show class_*.rst as modified. That is expected. Leave them, CI
regenerates and commits them on push.

index.rst uses a glob toctree over class_*, so adding or removing a class needs no edit here.
The old index listed every class by hand and had drifted to fifteen that no longer existed.


NOTES

The engine class reference is dumped to xml_engine/ and cached, because make_rst.py resolves
every type against the classes it is handed. Without it, float, Node3D and every other built-in
comes back "unresolved" and the run dies with over a thousand errors. --filter keeps the output
to our classes only. Pass --refresh-engine after upgrading Godot.

Source files have to use LF endings, which .gitattributes enforces. Godot's doc parser leaves
the carriage return on the end of a CRLF line and then cannot join the next line onto it, so a
paragraph wrapped across several ## lines arrives split and renders as an indented blockquote.
It went unnoticed across 21 pages. build_docs.py repairs it and warns if it ever has to.

conf.py defines the |abstract| substitution. Godot 4.7 emits an "abstract" method qualifier and
make_rst.py turns every qualifier into an RST substitution, but the vendored copy predates
@abstract and does not define that one.

conf.py also enables intersphinx against docs.godotengine.org, so engine types link out to the
official docs instead of producing an undefined-label warning per reference. The first build
needs network to fetch the inventory, after which Sphinx caches it.


VERSION NOTES

version.py sits at the repo root looking out of place because make_rst.py line 14 puts the
repo root on sys.path and then does "import version". There is a copy at tools/version.py, so
deleting the root one may just fall through to that, but it is untested. If you tidy it away
and the build starts failing on "import version", that is why.

.gdignore stops the Godot editor trying to import the css, fonts and svg under web/_build.
