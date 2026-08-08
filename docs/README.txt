Docs: An experiment that builds a browsable web version of the FoxFabric API using
Godot's own documentation tooling, in the style of the official online docs.

Only the tooling and the hand written pages are tracked. Everything generated is
ignored, so the output can never drift from the source.

Tracked:
    tools/make_rst.py       Godot's XML to reStructuredText converter
    tools/doc_status.py     coverage report for documented classes
    tools/misc/utility/     colour helpers, required by both scripts
    tools/version.py        version stamp the converter imports
    web/index.rst           hand written landing page
    web/core.rst            hand written page
    web/Makefile            sphinx entry point
    web/_static/            css and logos

Generated and ignored:
    xml_output/             class XML dumped from the editor
    rst_output/             converted reStructuredText
    web/class_*.rst         the pages sphinx actually renders
    web/_build/             final HTML

To rebuild:
    1. In Godot, run the editor with --doctool to dump class XML into xml_output.
    2. python tools/make_rst.py --output rst_output xml_output
    3. Copy the class_*.rst files into web/ and run `make html` there.

Requires python 3 on PATH. Note that make_rst.py imports version.py from the repo
root, so run it from inside docs/.

That is why version.py sits at the top level looking out of place. make_rst.py line 14 puts
the repo root on sys.path and then does "import version". There is a copy at
tools/version.py too, so deleting the root one may just fall through to that, but it is
untested. If you tidy it away and doc generation starts failing on "import version", that
is why.

Known gap: the last generated pass swept in the third party addons sitting in
addons/, so GodotDoctor, SignalVisualizer and Todo_Manager classes appeared as if
they belonged to FoxFabric. Scope the doctool run to addons/foxfabric before
regenerating.
