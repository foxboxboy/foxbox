# The cart, and each rider on it. Fills its own map in and nothing else.
#
# A map finds its parent map by walking up the tree, so a rider's map inherits from the cart's
# purely because the rider sits under the cart. Nothing here wires them together.
extends Node2D


## Shown in the readout.
@export var label: String = ""

## Written into the map as move_speed on the first frame. Rules act on it from there.
@export var move_speed: float = 5.0

@export var attributes: FoxAttributeMap


func _ready() -> void:
	attributes.set_data(&"move_speed", move_speed)
	attributes.add_data_to_group(&"move_speed", &"movement")


## What move_speed has been changed to by whatever rules are active.
func get_speed() -> float:
	var speed: float = attributes.get_data(&"move_speed", 0.0)
	return speed
