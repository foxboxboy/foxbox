# Everything on screen is read back out of the maps, so the demo keeps no state of its own that
# could drift away from what the maps actually hold.
extends Label


#region Variables

const Entity = preload("res://demos/attribute_map/entity.gd")

const SLOWED: StringName = &"slowed"
const MUD: StringName = &"mud"

@export var cart: Entity
@export var fox: Entity
@export var hare: Entity

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"1      mud rule on the cart          %s" % _on_off(cart.attributes.get_rule_summary().has(MUD)),
		"2 / 3  slow and unslow the cart      x%d" % cart.attributes.get_flag_stacks(SLOWED),
		"4 / 5  the fox slows itself          x%d" % fox.attributes.get_flag_stacks(SLOWED),
		"Space  the fox is                    %s" % ("riding" if fox.get_parent() == cart else "on the kerb"),
		"",
		"%-22s %-11s %-14s %s" % ["", "move_speed", "flags", "rules"],
		_row(cart, ""),
		_row(fox, "  "),
		_row(hare, "  "),
	])

#endregion


#region Private

func _row(entity: Entity, indent: String) -> String:
	var map: FoxAttributeMap = entity.attributes
	return "%-22s %-11s %-14s %s" % [
		indent + entity.label,
		"%.1f" % entity.get_speed(),
		_stacks(map.get_flags()),
		_names(map.get_rule_summary().keys()),
	]


## Flags read as name and count, since a stack of one and a stack of three look the same otherwise.
func _stacks(flags: Dictionary[StringName, int]) -> String:
	var parts: PackedStringArray = []
	for flag: StringName in flags:
		parts.append("%s x%d" % [flag, flags[flag]])

	return ", ".join(parts) if not parts.is_empty() else "-"


func _names(ids: Array) -> String:
	var parts: PackedStringArray = []
	for id: Variant in ids:
		parts.append(str(id))

	return ", ".join(parts) if not parts.is_empty() else "-"


func _on_off(value: bool) -> String:
	return "on" if value else "off"

#endregion
