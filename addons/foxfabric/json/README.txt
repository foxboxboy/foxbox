Json: Reads and writes JSON that keeps its Godot types. For files people open: world files, level formats, moddable content. A file carries a version, so an older one still loads after the format moves.

For a save the player never opens, FileAccess.store_var is two lines and keeps every Godot type exactly. Use that instead.
