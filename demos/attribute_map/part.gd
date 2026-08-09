# One part of the tank: the hull, the turret, the cannon, the machine gun.
#
# Each one owns a map, and a part's map inherits from the one above it purely because the part sits
# under that part in the tree. Nothing here wires them together.
class_name DemoTankPart
extends Node2D


#region Variables

const DAMAGE: StringName = &"damage"
const FIRE_RATE: StringName = &"fire_rate"
const STUNNED: StringName = &"crew_stunned"

## Shown in the readout and on the part itself.
@export var label: String = ""

@export var attributes: FoxAttributeMap

## Written into the map on the first frame as the base value of a [FoxModifiableStat]. A plain
## Dictionary so it can be typed straight into the scene, keys as strings.
@export var stats: Dictionary = {}

## The group every one of this part's stats is filed under. A rule can then act on the lot of them
## without knowing what any particular part carries.
@export var group: StringName = &""

## What this part shoots at. Only the parts that shoot need one.
@export var target: DemoTankWall

var _cooldown: float = 0.0

#endregion


#region Built-In Virtuals

func _ready() -> void:
	for key: String in stats:
		var stat: StringName = StringName(key)

		# Through a typed local, because a Dictionary lookup comes back as a Variant.
		var base: float = stats[key]

		# The map stores any Variant, so what goes in is a stat rather than a bare number. Rules
		# then stack modifiers on it instead of overwriting it, which is what makes them come off
		# cleanly no matter what order they went on in.
		attributes.set_data(stat, FoxModifiableStat.new(base))

		if group != &"":
			attributes.add_data_to_group(stat, group)


func _process(delta: float) -> void:
	if not can_fire():
		return

	_cooldown -= delta
	if _cooldown > 0.0:
		return

	_cooldown = 1.0 / get_stat(FIRE_RATE)
	target.take_damage(get_stat(DAMAGE))

#endregion


#region Public API

## The stat's value once every modifier on it has been counted.
func get_stat(key: StringName) -> float:
	var stat: FoxModifiableStat = attributes.get_data(key, null)
	if stat == null:
		return 0.0

	return stat.value


## The hull and the turret hold no damage, so they never shoot whatever happens to them.
## [br][br]
## A stunned crew does not shoot either. That flag stores nothing and changes no data; this is the
## code that decides what it means, and the map has no idea.
func can_fire() -> bool:
	if attributes.has_flag(STUNNED):
		return false

	return get_stat(DAMAGE) > 0.0 and get_stat(FIRE_RATE) > 0.0


## Every stat this part is holding, in the order it was written in.
func get_stats() -> Array[StringName]:
	return attributes.get_data_keys()

#endregion
