# Everything on screen is read back out of the maps, so the demo keeps no state of its own that
# could drift away from what the maps actually hold.
extends Label


#region Variables

const Runner = preload("res://demos/attribute_map/runner.gd")

const MUD: StringName = &"mud"

@export var pack: FoxAttributeMap

@export var fox: Runner
@export var hare: Runner
@export var badger: Runner

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"1      mud on the pack             %s" % _on_off(pack.get_rule_summary().has(MUD)),
		"2 / 3  slow and unslow the pack",
		"4 / 5  the fox slows itself",
		"Space  the fox is                  %s" % ("in the pack" if fox.is_in_a_pack() else "running alone"),
		"",
		_line("", "move_speed", "going at", "flags", "rules"),
		_line("pack", "-", "-", _stacks(pack), _rules(pack)),
		_runner(fox),
		_runner(hare),
		_runner(badger),
		"",
		"mud is a rule. It changes move_speed itself, and the pack passes it down.",
		"slowed is a flag. It changes no data at all, and the runners ease off anyway.",
	])

#endregion


#region Private

## Runners in the pack are indented under it, so leaving the pack is visible in the table as well
## as on the track.
func _runner(runner: Runner) -> String:
	var indent: String = "  " if runner.is_in_a_pack() else ""
	return _line(
		indent + runner.label,
		"%.1f" % runner.get_speed(),
		"%.1f" % runner.get_pace(),
		_stacks(runner.attributes),
		_rules(runner.attributes),
	)


## move_speed and the pace it produces get their own columns, because the whole difference between
## a rule and a flag is which of the two they move.
func _line(name: String, speed: String, pace: String, flags: String, rules: String) -> String:
	return "%-13s%-12s%-11s%-30s%s" % [name, speed, pace, flags, rules]


## A stack count on its own cannot say where it came from, so anything handed down by a parent map
## is called out. Take the fox out of the pack and the inherited part is what disappears.
func _stacks(map: FoxAttributeMap) -> String:
	# Declared empty and filled in, because a bare {} in a ternary is an untyped Dictionary and
	# assigning one to a typed variable fails at runtime.
	var handed_down: Dictionary[StringName, int] = {}
	var parent: FoxAttributeMap = map.get_parent_map()
	if parent != null:
		handed_down = parent.get_flags()

	var parts: PackedStringArray = []
	for flag: StringName in map.get_flags():
		var total: int = map.get_flag_stacks(flag)
		var inherited: int = handed_down.get(flag, 0)
		if inherited > 0:
			parts.append("%s x%-4d(%d inherited)" % [flag, total, inherited])
		else:
			parts.append("%s x%d" % [flag, total])

	return ", ".join(parts) if not parts.is_empty() else "-"


func _rules(map: FoxAttributeMap) -> String:
	var parts: PackedStringArray = []
	for id: StringName in map.get_rule_summary():
		parts.append(String(id))

	return ", ".join(parts) if not parts.is_empty() else "-"


func _on_off(value: bool) -> String:
	return "on" if value else "off"

#endregion
