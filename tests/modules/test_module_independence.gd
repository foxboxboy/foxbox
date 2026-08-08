extends "res://tests/fox_test.gd"
## Checks that modules do not reach into each other.
##
## A module may reference [code]core[/code] and itself, and nothing else. That rule is what lets
## someone copy a single module folder into their project and have it work, so it is worth
## enforcing rather than trusting.
## [br][br]
## Doc comments are ignored. A [code][FoxEffectManager][/code] crosslink in documentation is not
## a dependency, and stripping them keeps the check honest.


const ADDON: String = "res://addons/foxfabric/"

## Exempt from every rule. See CONTRIBUTING.md.
const SKIPPED: Array[String] = ["deprecated", "trash"]

## Cross-module dependencies that are deliberate. Anything not listed here is a failure.
const ALLOWED: Dictionary = {
	"character": ["state_machine"],
}


func run() -> void:
	suite = "module_independence"
	_modules_only_reach_core()


func _modules_only_reach_core() -> void:
	case("cross module references")

	var files: Array[String] = []
	_collect(ADDON, files)
	check(files.size() > 30, "found the addon source to scan")

	var owner: Dictionary = _class_owners(files)
	check(owner.size() > 30, "mapped class names to their modules")

	var strays: Array[String] = []
	for path: String in files:
		var module: String = _module_of(path)
		if module == "":
			continue

		var allowed: Array = ALLOWED.get(module, [])
		for name: String in _referenced_classes(path):
			var home: String = owner.get(name, "")
			if home == "" or home == module or home == "core":
				continue
			if allowed.has(home):
				continue
			strays.append("%s references %s from %s" % [path.trim_prefix(ADDON), name, home])

	eq(strays.size(), 0, "no module reaches outside core: %s" % ", ".join(strays))


## Every .gd file under [param dir], skipping the exempt folders.
func _collect(dir: String, out: Array[String]) -> void:
	var d: DirAccess = DirAccess.open(dir)
	if d == null:
		return

	d.list_dir_begin()
	var entry: String = d.get_next()
	while entry != "":
		var full: String = dir.path_join(entry)
		if d.current_is_dir():
			if not SKIPPED.has(entry):
				_collect(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = d.get_next()
	d.list_dir_end()


## The module folder a file belongs to, or "" for files sitting at the addon root.
func _module_of(path: String) -> String:
	var rel: String = path.trim_prefix(ADDON)
	var cut: int = rel.find("/")
	return rel.substr(0, cut) if cut != -1 else ""


## Maps every class_name in the addon to the module that declares it.
func _class_owners(files: Array[String]) -> Dictionary:
	var re: RegEx = RegEx.create_from_string("^\\s*class_name\\s+(\\w+)")
	var owner: Dictionary = {}

	for path: String in files:
		var module: String = _module_of(path)
		if module == "":
			continue
		for line: String in _lines(path):
			var m: RegExMatch = re.search(line)
			if m:
				owner[m.get_string(1)] = module

	return owner


## Every Fox class named in the executable code of a file. Comments do not count.
func _referenced_classes(path: String) -> Array[String]:
	var re: RegEx = RegEx.create_from_string("\\bFox\\w+")
	var found: Array[String] = []

	for line: String in _lines(path):
		for m: RegExMatch in re.search_all(_code_of(line)):
			var name: String = m.get_string()
			if not found.has(name):
				found.append(name)

	return found


func _lines(path: String) -> PackedStringArray:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedStringArray()
	return f.get_as_text().split("\n")


## Drops comments. Truncating at the first hash can lose a reference but never invents one,
## so the check stays conservative.
func _code_of(line: String) -> String:
	if line.strip_edges().begins_with("#"):
		return ""

	var hash_at: int = line.find("#")
	return line.substr(0, hash_at) if hash_at != -1 else line
