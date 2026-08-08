# Number keys act on the cart, Space takes the fox on and off it.
#
# Keys are read as raw events rather than named actions, so this works in a project that has not
# set up an input map.
extends Node


#region Variables

const FlatRule = preload("res://demos/attribute_map/flat_rule.gd")
const Entity = preload("res://demos/attribute_map/entity.gd")

const MUD: StringName = &"mud"
const SLOWED: StringName = &"slowed"

## How much the mud rule takes off move_speed, everywhere it reaches.
const MUD_AMOUNT: float = -2.0

@export var cart: Entity
@export var fox: Entity

## Where the fox stands once it is off the cart. Being under this instead of under the cart is the
## whole difference: the map looks up the tree, so leaving the cart leaves its map behind too.
@export var kerb: Node2D

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
			cart.attributes.increment_flag(SLOWED)
		KEY_3:
			cart.attributes.decrement_flag(SLOWED)
		KEY_4:
			fox.attributes.increment_flag(SLOWED)
		KEY_5:
			fox.attributes.decrement_flag(SLOWED)
		KEY_SPACE:
			_toggle_riding()

#endregion


#region Private

## One rule on the cart slows everything riding in it, because add_rule passes it down.
func _toggle_mud() -> void:
	if cart.attributes.get_rule_summary().has(MUD):
		cart.attributes.remove_rule(MUD)
		return

	cart.attributes.add_rule(FlatRule.new(MUD, &"move_speed", MUD_AMOUNT))


## Moving the fox out from under the cart unregisters its map, which takes back the rules and flag
## stacks the cart had given it. Stacks the fox raised on itself are its own and stay.
func _toggle_riding() -> void:
	if fox.get_parent() == cart:
		fox.reparent(kerb, false)
	else:
		fox.reparent(cart, false)

#endregion
