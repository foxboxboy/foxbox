# The buttons. Each one is something you can do to the tank, and the tree works out the rest.
#
# The buttons themselves are in the scene, wired to the methods below through the Node tab, which
# is where Godot expects to find them.
extends VBoxContainer


#region Variables

const FlatRule = preload("res://demos/attribute_map/rules/flat_rule.gd")
const BiggerCannon = preload("res://demos/attribute_map/rules/bigger_cannon.gd")
const KnockedOut = preload("res://demos/attribute_map/rules/knocked_out.gd")
const Wall = preload("res://demos/attribute_map/wall.gd")

const BOOST: StringName = &"boost"
const BIGGER: StringName = &"bigger cannon"
const WRECKED: StringName = &"knocked out"
const STUNNED: StringName = &"crew_stunned"

## How far the boost can be wound down. The machine gun only has three damage to give, and a
## weapon doing less than none of it is not a thing worth showing.
const WEAKEST: int = -3

## And a ceiling, so holding the button down cannot run away with it.
const STRONGEST: int = 20

## The top of the tree. Everything added here reaches every part below it.
@export var tank: FoxAttributeMap

## Knocking a weapon out is about that weapon, so the rule goes straight on it. Put on the tank it
## would take out the machine gun as well.
@export var cannon: FoxAttributeMap

@export var wall: Wall

## How much the boost is currently worth. Rules are not edited in place, so changing it means
## taking the old rule off and putting a new one on under the same id.
var _boost: int = 0

#endregion


#region Public API

## Read by the readout, so the buttons going quiet at the limit has something to point at.
func get_boost() -> int:
	return _boost

#endregion


#region Buttons

func _on_boost_up_pressed() -> void:
	_set_boost(_boost + 1)


func _on_boost_down_pressed() -> void:
	_set_boost(_boost - 1)


func _on_bigger_cannon_pressed() -> void:
	if tank.get_rule_summary().has(BIGGER):
		tank.remove_rule(BIGGER)
		return

	tank.add_rule(BiggerCannon.new(BIGGER))


func _on_knocked_out_pressed() -> void:
	if cannon.get_rule_summary().has(WRECKED):
		cannon.remove_rule(WRECKED)
		return

	cannon.add_rule(KnockedOut.new(WRECKED))


## A flag on the tank reaches every part under it, and each part decides for itself what it means.
func _on_stun_pressed() -> void:
	if tank.has_flag(STUNNED):
		tank.erase_flag(STUNNED)
		return

	tank.increment_flag(STUNNED)


func _on_repair_pressed() -> void:
	wall.reset()

#endregion


#region Private

## Targets damage, so it reaches every map under the tank and lands on the two that shoot. The hull
## and the turret track it and are not touched, because neither of them holds a damage.
func _set_boost(amount: int) -> void:
	_boost = clampi(amount, WEAKEST, STRONGEST)
	tank.remove_rule(BOOST)

	if _boost != 0:
		tank.add_rule(FlatRule.new(BOOST, &"damage", float(_boost)))

#endregion
