# Everything on screen is read back out of the maps, so the demo keeps no state of its own that
# could drift away from what the maps actually hold.
extends Label


#region Variables

const Part = preload("res://demos/attribute_map/part.gd")

## In tree order, with the indent each one is drawn at. The tank owns the turret, the turret owns
## the cannon, and the machine gun hangs off the tank beside the turret.
@export var tank: Part
@export var turret: Part
@export var cannon: Part
@export var machine_gun: Part

@export var target: Node

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"wall  %d" % roundi(target.get(&"health")),
		"",
		_line("part", "damage", "its own stats", "group", "rules it tracks", "flags"),
		_part(tank, ""),
		_part(turret, "  "),
		_part(cannon, "    "),
		_part(machine_gun, "  "),
		"",
		"Rules travel to every map below where they were added, and land only on the ones",
		"holding the key they target. The hull and turret hold no damage, so they track the",
		"boost without it doing a thing to them.",
	])

#endregion


#region Private

func _part(part: Part, indent: String) -> String:
	return _line(
		indent + part.label,
		_damage(part),
		_stats(part),
		String(part.group),
		_rules(part.attributes),
		_flags(part.attributes),
	)


## The group gets a column of its own. It is the thing deciding what "knocked out" reaches, so it
## is worth being able to see at a glance which stats are filed where.
func _line(name: String, damage: String, stats: String, group: String, rules: String, flags: String) -> String:
	return "%-15s%-9s%-29s%-16s%-34s%s" % [name, damage, stats, group, rules, flags]


## Blank rather than 0.0 for the parts that carry no damage at all, so a part that has none reads
## differently from a weapon that has been knocked down to none.
func _damage(part: Part) -> String:
	if not part.attributes.has_data(&"damage"):
		return "-"

	return _number(part.get_stat(&"damage"))


## Everything except damage, which has a column to itself.
func _stats(part: Part) -> String:
	var parts: PackedStringArray = []
	for key: StringName in part.get_stats():
		if key == &"damage":
			continue

		parts.append("%s %s" % [key, _number(part.get_stat(key))])

	return ", ".join(parts) if not parts.is_empty() else "-"


## A fire rate of 0.5 is not 1, and an armour of 60 does not need a decimal point.
func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)

	return "%.1f" % value


func _rules(map: FoxAttributeMap) -> String:
	var parts: PackedStringArray = []
	for id: StringName in map.get_rule_summary():
		parts.append(String(id))

	return ", ".join(parts) if not parts.is_empty() else "-"


## Anything handed down by a parent map is called out, since a stack count cannot say where it
## came from on its own.
func _flags(map: FoxAttributeMap) -> String:
	var handed_down: Dictionary[StringName, int] = {}
	var parent: FoxAttributeMap = map.get_parent_map()
	if parent != null:
		handed_down = parent.get_flags()

	var parts: PackedStringArray = []
	for flag: StringName in map.get_flags():
		if handed_down.has(flag):
			parts.append("%s (inherited)" % flag)
		else:
			parts.append(String(flag))

	return ", ".join(parts) if not parts.is_empty() else "-"

#endregion
