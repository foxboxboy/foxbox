These fonts are not mine.

Inter                by Rasmus Andersson      https://rsms.me/inter/
JetBrains Mono       by JetBrains             https://www.jetbrains.com/lp/mono/

Both are licensed under the SIL Open Font License 1.1, which permits bundling them with a
project like this. The copies here came from the godot-docs repository, at
_static/css/fonts/, so the typography matches the official Godot documentation.

custom.css references them by relative path, and custom.css lives one folder up from here, so
they must stay in _static/fonts/. In godot-docs the stylesheet sits in _static/css/, which is
why the path differs from the one in that repository.

Without these files every rule in custom.css that asks for Inter or JetBrains Mono silently
falls back to a system font, and the site looks close to the Godot docs without matching them.
