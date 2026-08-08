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
extensions = ['sphinx.ext.intersphinx']

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
    # The RTD theme collapses everything under a caption until you are already on that page,
    # which is why the sidebar looked empty. Godot's docs keep the whole tree open.
    'collapse_navigation': False,
    # 2 keeps every module and class in view. Going deeper adds each class's own sections
    # (Description, Properties, Methods) to the sidebar, which is hundreds of extra entries.
    'navigation_depth': 2,
    'sticky_navigation': True,
    'style_external_links': True,
    'prev_next_buttons_location': 'both',
}

html_logo = "_static/fox_docs_logo.svg"
html_favicon = "_static/favicon.svg"

# Every class page is generated, so "View page source" would show a reStructuredText file that
# nobody should edit. The real source is the ## comment in the .gd file.
html_show_sourcelink = False

html_title = "FoxFabric documentation"


html_css_files = [
    'custom.css',
]

# custom.css styles sidebar captions as clickable and hides their contents until a class is
# added. custom.js is what adds it. Without the pair, sections never open.
html_js_files = [
    'custom.js',
]