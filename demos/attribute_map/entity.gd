# The cart, and each rider on it. Fills its own map in and reacts to its own flags.
#
# A map finds its parent map by walking up the tree, so a rider's map inherits from the cart's
# purely because the rider sits under the cart. Nothing here wires them together.
extends Node2D


#region Variables

const SLOWED: StringName = &"slowed"

## Stacks needed to reach full tint. Past this it cannot get any dimmer.
const FULLY_SLOWED: int = 4

## What a slowed thing fades towards.
const SLOWED_TINT: Color = Color(0.35, 0.42, 0.55)

## Shown in the readout.
@export var label: String = ""

## Written into the map as move_speed on the first frame. Rules act on it from there.
@export var move_speed: float = 5.0

@export var attributes: FoxAttributeMap

## Tinted while this thing is slowed.
@export var body: Polygon2D

#endregion


#region Built-In Virtuals

func _ready() -> void:
	attributes.set_data(&"move_speed", move_speed)
	attributes.add_data_to_group(&"move_speed", &"movement")

	attributes.flag_changed.connect(_on_flag_changed)

#endregion


#region Public API

## What move_speed has been changed to by whatever rules are active.
func get_speed() -> float:
	var speed: float = attributes.get_data(&"move_speed", 0.0)
	return speed

#endregion


#region Private

## A flag changes no data by itself. Something has to read it and decide what it means, and here
## that is this: a slowed thing goes dim, and dimmer the more stacks it is carrying. The map never
## knows that is what slowed does.
func _on_flag_changed(flag: StringName, stacks: int) -> void:
	if flag != SLOWED:
		return

	var depth: float = minf(stacks, FULLY_SLOWED) / float(FULLY_SLOWED)
	body.modulate = Color.WHITE.lerp(SLOWED_TINT, depth)

#endregion
