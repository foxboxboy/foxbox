Extensions: Sphinx extensions used by the docs build.

gdscript.py is Godot's own GDScript lexer, copied from godot-docs at _extensions/gdscript.py.
MIT licensed, credited in its header to the Godot Engine community.

It is here because stock Pygments puts every GDScript keyword in one token, so func, if, for and
return all render the same colour, and it treats the @ in @export as an error. Godot's lexer
emits Keyword.ControlFlow separately, which is the class custom.css is written against, and
understands annotations.

conf.py puts this folder on sys.path and loads "gdscript" as an extension.
