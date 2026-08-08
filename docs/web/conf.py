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
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

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
}

html_logo = "_static/fox_docs_logo.svg"


html_css_files = [
    'custom.css',
]