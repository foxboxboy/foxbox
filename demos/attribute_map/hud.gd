# Everything on screen is read back out of the maps, so the demo keeps no state of its own that
# could drift away from what the maps actually hold.
extends Label


#region Variables

const Entity = preload("res://demos/attribute_map/entity.gd")

const MUD: StringName = &"mud"

@export var cart: Entity
@export var fox: Entity
@export var hare: Entity

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"1      a mud rule on the cart      %s" % _on_off(cart.attributes.get_rule_summary().has(MUD)),
		"2 / 3  slow and unslow the cart",
		"4 / 5  the fox slows itself",
		"Space  the fox is                  %s" % ("riding" if fox.get_parent() == cart else "on the kerb"),
		"",
		_row_text("", "move_speed", "flags", "rules"),
		_row(cart, ""),
		_row(fox, "  "),
		_row(hare, "  "),
	])

#endregion


#region Private

func _row(entity: Entity, indent: String) -> String:
	return _row_text(
		indent + entity.label,
		"%.1f" % entity.get_speed(),
		_stacks(entity.attributes),
		_rules(entity.attributes),
	)


func _row_text(name: String, speed: String, flags: String, rules: String) -> String:
	return "%-16s%-12s%-30s%s" % [name, speed, flags, rules]


## A stack count on its own cannot say where it came from, so anything handed down by a parent map
## is called out. Take the fox off the cart and the inherited part is what disappears.
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
