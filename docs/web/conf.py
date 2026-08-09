# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'FoxFabric'
copyright = '2026, tateorrtot'
author = 'tateorrtot'
release = '0.1'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

# Only FoxFabric classes get pages here, but the generated text cross-references engine types
# like Node3D and float. intersphinx resolves those against the official Godot docs so they stay
# clickable instead of producing a thousand "undefined label" warnings.
# Needs network on the first build, then Sphinx caches the inventory.
import os
import sys

sys.path.insert(0, os.path.abspath('_extensions'))

# gdscript is Godot's own lexer, copied from godot-docs. Stock Pygments lumps every keyword into
# one token, so func, if, for and return all come out the same colour. Godot's lexer emits
# Keyword.ControlFlow separately, which is the class custom.css is written against.
extensions = ['sphinx.ext.intersphinx', 'gdscript']

highlight_language = 'gdscript'

intersphinx_mapping = {
    'godot': ('https://docs.godotengine.org/en/stable/', None),
}
intersphinx_disabled_reftypes = []

templates_path = ['_templates']

# intros/ holds hand written prose that build_docs.py splices into the generated module pages.
# Those files are fragments, not pages, so Sphinx must not try to build them on their own.
exclude_patterns = ['_build', 'intros', 'Thumbs.db', '.DS_Store']

# Pygments' gdscript lexer does not understand @export and friends, so it falls back to relaxed
# mode and still highlights fine. The warning is about the lexer, not about our code.
suppress_warnings = ['misc.highlighting_failure']

# Godot 4.7 emits an "abstract" method qualifier, and make_rst.py turns every qualifier into an
# RST substitution. The vendored copy of make_rst.py predates @abstract, so its make_footer()
# defines virtual, required, const, vararg, constructor, static, operator, bitfield and void but
# not this one. Declaring it here avoids patching the vendored tool. Do not redeclare the others,
# or every page reports a duplicate substitution.
rst_prolog = """
.. |abstract| replace:: :abbr:`abstract (This method must be overridden when extending its base class. It cannot be called directly.)`
"""



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

html_theme_options = {
    'logo_only': True,
    # False makes Sphinx emit the whole tree and let CSS collapse it, which is what puts a + box
    # on every branch. True emits only the current branch, so siblings have no children in the
    # markup and get no box at all.
    'collapse_navigation': False,
    # Deep enough to reach a class's own sections, the way Godot shows Description, Properties
    # and Methods under the class you are reading.
    'navigation_depth': 5,
    'sticky_navigation': True,
    # The theme's own external-link icon stacks on top of the one custom.css already draws.
    'style_external_links': False,
    # Godot puts these at the foot of the page only. 'both' also stacks them above the title,
    # which pushes the actual content down and reads as clutter.
    'prev_next_buttons_location': 'bottom',
    # Theme 3.0 turned these on by default, which puts a version dropdown under the logo on top of
    # the floating flyout Read the Docs already provides. One project, one language, two controls
    # that do nothing.
    'version_selector': False,
    'language_selector': False,
}

html_logo = "_static/fox_docs_logo.svg"
html_favicon = "_static/favicon.svg"

# Every class page is generated, so "View page source" would show a reStructuredText file that
# nobody should edit. The real source is the ## comment in the .gd file.
html_show_sourcelink = False

html_title = "FoxFabric documentation"

# What the theme builds the "Edit on GitHub" link from. Read the Docs used to supply these and no
# longer does, so without them the link is absent on every page, including the hand written ones
# where editing is the right thing to offer. Godot sets them the same way.
#
# conf_py_path is the folder holding the reStructuredText, relative to the repo root, and the
# theme joins it to the page name. _templates/breadcrumbs.html drops the link again on generated
# pages.
html_context = {
    'display_github': True,
    'github_user': 'tateorrtot',
    'github_repo': 'foxfabric-godot',
    'github_version': 'main',
    'conf_py_path': '/docs/web/',
}


html_css_files = [
    'custom.css',
    'foxfabric.css',
]

# custom.css styles sidebar captions as clickable and hides their contents until a class is
# added. custom.js is what adds it. Without the pair, sections never open.
html_js_files = [
    'custom.js',
]