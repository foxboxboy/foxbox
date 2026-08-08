# One runner. Moves at whatever move_speed its map currently holds, and dims while it is slowed.
#
# Nothing here knows about packs or rules. It reads its own map every frame and that is all, so
# anything that changes the map changes how this moves.
extends Node2D


#region Variables

const SLOWED: StringName = &"slowed"

## move_speed is a small number, so it needs scaling to be a number of pixels.
const PIXELS_PER_UNIT: float = 46.0

## Stacks needed to reach full tint. Past this it cannot get any dimmer.
const FULLY_SLOWED: int = 4

## What a slowed runner fades towards.
const SLOWED_TINT: Color = Color(0.40, 0.45, 0.56)

## Shown in the readout and on the runner itself.
@export var label: String = ""

## Written into the map as move_speed on the first frame. Rules take it from there.
@export var starting_speed: float = 5.0

@export var attributes: FoxAttributeMap

## Tinted while this runner is slowed.
@export var body: Polygon2D

## Runs from one to the other, then starts again.
@export var lap_start: float = 70.0
@export var lap_end: float = 1090.0

#endregion


#region Built-In Virtuals

func _ready() -> void:
	attributes.set_data(&"move_speed", starting_speed)
	attributes.add_data_to_group(&"move_speed", &"movement")
	attributes.flag_changed.connect(_on_flag_changed)


func _process(delta: float) -> void:
	position.x += get_speed() * PIXELS_PER_UNIT * delta
	if position.x > lap_end:
		position.x = lap_start

#endregion


#region Public API

## What move_speed has been changed to by whatever rules are active.
func get_speed() -> float:
	var speed: float = attributes.get_data(&"move_speed", 0.0)
	return speed


## Whether this runner's map is inheriting from another one.
func is_in_a_pack() -> bool:
	return attributes.get_parent_map() != null

#endregion


#region Private

## A flag changes no data by itself. Something has to read it and decide what it means, and here
## that is this. The map never learns what slowed does.
func _on_flag_changed(flag: StringName, stacks: int) -> void:
	if flag != SLOWED:
		return

	var depth: float = minf(stacks, FULLY_SLOWED) / float(FULLY_SLOWED)
	body.modulate = Color.WHITE.lerp(SLOWED_TINT, depth)

#endregion
