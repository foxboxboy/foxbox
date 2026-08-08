extends "res://tests/fox_test.gd"
## Checks that every demo scene still opens.
##
## The demos are the first thing anyone looks at and nothing else in the suite touches them, so
## a renamed class, a removed export or a moved resource breaks them quietly.
## [br][br]
## Scenes are instantiated but never added to the tree, so no [method Node._ready] runs and no
## demo starts playing itself. That means this catches a scene that can no longer be built. It
## does not catch one that builds and then behaves differently: the profile default that stopped
## the crates rolling would still have slipped past here. Behaviour belongs in a test against
## the module, not against the demo.


const DEMOS_DIR: String = "res://demos/"


func run() -> void:
	suite = "demos"
	_every_scene_opens()


func _every_scene_opens() -> void:
	case("scenes open")
	var scenes: Array[String] = []
	_collect(DEMOS_DIR, scenes)
	scenes.sort()

	check(scenes.size() > 0, "found demo scenes to check")

	for path: String in scenes:
		var label: String = path.trim_prefix(DEMOS_DIR)
		var missing: Array[String] = _missing_dependencies(path)

		if not missing.is_empty():
			check(false, "%s is missing %s" % [label, ", ".join(missing)])
			continue

		var packed: PackedScene = load(path) as PackedScene

		if packed == null or not packed.can_instantiate():
			check(false, "%s opens" % label)
			continue

		var node: Node = packed.instantiate()
		check(node != null, "%s opens" % label)

		if node != null:
			node.free()


## The paths a scene depends on that are not actually there.
## [br][br]
## Instantiating is not enough on its own. A scene naming a resource that has been moved or
## deleted still instantiates: the engine logs the failure, substitutes nothing, and carries on,
## so the node comes back non-null and everything looks fine.
func _missing_dependencies(path: String) -> Array[String]:
	var missing: Array[String] = []

	for entry: String in ResourceLoader.get_dependencies(path):
		# Entries come as "path", "uid::path" or "uid::type::path".
		var target: String = entry.get_slice("::", entry.get_slice_count("::") - 1)
		if target != "" and not ResourceLoader.exists(target):
			missing.append(target)

	return missing


func _collect(dir: String, out: Array[String]) -> void:
	var d: DirAccess = DirAccess.open(dir)
	if d == null:
		return

	d.list_dir_begin()
	var entry: String = d.get_next()
	while entry != "":
		var full: String = dir.path_join(entry)
		if d.current_is_dir():
			_collect(full, out)
		elif entry.ends_with(".tscn"):
			out.append(full)
		entry = d.get_next()
	d.list_dir_end()
