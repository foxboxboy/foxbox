# One runner.
#
# Its map holds a move_speed that rules change, and a slowed flag that changes no data whatsoever.
# This script is the thing that decides what either of them means for how fast it actually goes.
extends Node2D


#region Variables

const SLOWED: StringName = &"slowed"

## move_speed is a small number, so it needs scaling to be a number of pixels.
const PIXELS_PER_UNIT: float = 46.0

## What one stack of slowed costs. Halves the pace at two stacks, and however many pile up it
## never quite reaches a standstill.
const SLOW_PER_STACK: float = 0.5

## Shown in the readout and above the runner.
@export var label: String = ""

## Written into the map as move_speed on the first frame. Rules take it from there.
@export var starting_speed: float = 5.0

@export var attributes: FoxAttributeMap

## Runs from one to the other, then starts again.
@export var lap_start: float = 70.0
@export var lap_end: float = 1090.0

#endregion


#region Built-In Virtuals

func _ready() -> void:
	attributes.set_data(&"move_speed", starting_speed)
	attributes.add_data_to_group(&"move_speed", &"movement")


func _process(delta: float) -> void:
	position.x += get_pace() * PIXELS_PER_UNIT * delta
	if position.x > lap_end:
		position.x = lap_start

#endregion


#region Public API

## The move_speed the map is holding. This is the number rules change.
func get_speed() -> float:
	var speed: float = attributes.get_data(&"move_speed", 0.0)
	return speed


## How fast it travels, which is not the same thing.
## [br][br]
## The slowed flag stores nothing and changes no data. It is a marker, and this is the code that
## decides a marker means easing off. The map has no idea that is what slowed does.
func get_pace() -> float:
	var stacks: int = attributes.get_flag_stacks(SLOWED)
	return get_speed() / (1.0 + SLOW_PER_STACK * stacks)


## Whether this runner's map is inheriting from another one.
func is_in_a_pack() -> bool:
	return attributes.get_parent_map() != null

#endregion
