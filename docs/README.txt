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

Only the tooling and the hand written pages:

    build_docs.py            the four step build
    tools/make_rst.py        Godot's XML to reStructuredText converter
    tools/doc_status.py      coverage report for documented classes
    tools/misc/utility/      colour helpers, imported by both scripts
    tools/version.py         version stamp the converter imports
    web/index.rst            landing page
    web/conf.py              Sphinx settings
    web/Makefile, make.bat   Sphinx entry points
    web/_static/             css and logos

Everything generated is ignored, so the output can never drift from the source:

    xml_output/              class XML from Godot
    rst_output/              converted reStructuredText
    web/class_*.rst          the pages Sphinx renders
    web/_build/              final HTML

index.rst uses a glob toctree over class_*, so adding or removing a class needs no edit here.
The old index listed every class by hand and had drifted to fifteen that no longer existed.


NOTES

version.py sits at the repo root looking out of place because make_rst.py line 14 puts the
repo root on sys.path and then does "import version". There is a copy at tools/version.py, so
deleting the root one may just fall through to that, but it is untested. If you tidy it away
and the build starts failing on "import version", that is why.

.gdignore stops the Godot editor trying to import the css, fonts and svg under web/_build.
