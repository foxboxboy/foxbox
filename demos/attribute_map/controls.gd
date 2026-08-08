# Number keys act on the pack, Space takes the fox out of it and puts it back.
#
# Keys are read as raw events rather than named actions, so this works in a project that has not
# set up an input map.
extends Node


#region Variables

const FlatRule = preload("res://demos/attribute_map/flat_rule.gd")
const Runner = preload("res://demos/attribute_map/runner.gd")

const MUD: StringName = &"mud"
const SLOWED: StringName = &"slowed"

## How much move_speed the mud rule takes off, everywhere it reaches.
const MUD_AMOUNT: float = -2.0

## The pack's own map. Rules and flags put here reach every runner in the pack.
@export var pack: FoxAttributeMap

## The node the runners in the pack sit under. Being under it is what puts a runner in the pack.
@export var pack_node: Node2D

## Where the fox goes when it leaves. Nothing here holds a map, so out here it inherits nothing.
@export var track: Node2D

@export var fox: Runner

#endregion


#region Built-In Virtuals

func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	match key.keycode:
		KEY_1:
			_toggle_mud()
		KEY_2:
			pack.increment_flag(SLOWED)
		KEY_3:
			pack.decrement_flag(SLOWED)
		KEY_4:
			fox.attributes.increment_flag(SLOWED)
		KEY_5:
			fox.attributes.decrement_flag(SLOWED)
		KEY_SPACE:
			_toggle_pack()

#endregion


#region Private

## One rule on the pack slows every runner in it, because add_rule passes it down. The badger runs
## outside the pack and keeps its pace.
func _toggle_mud() -> void:
	if pack.get_rule_summary().has(MUD):
		pack.remove_rule(MUD)
		return

	pack.add_rule(FlatRule.new(MUD, &"move_speed", MUD_AMOUNT))


## Moving the fox out from under the pack unregisters its map, which takes back the rules and flag
## stacks the pack had given it. Stacks the fox raised on itself are its own and stay.
func _toggle_pack() -> void:
	if fox.get_parent() == pack_node:
		fox.reparent(track, true)
	else:
		fox.reparent(pack_node, true)

#endregion
