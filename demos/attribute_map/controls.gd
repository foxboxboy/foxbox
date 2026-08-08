# The buttons. Each one is something you can do to the tank, and the tree works out the rest.
extends VBoxContainer


#region Variables

const FlatRule = preload("res://demos/attribute_map/rules/flat_rule.gd")
const BiggerCannon = preload("res://demos/attribute_map/rules/bigger_cannon.gd")
const KnockedOut = preload("res://demos/attribute_map/rules/knocked_out.gd")

const BOOST: StringName = &"boost"
const BIGGER: StringName = &"bigger cannon"
const WRECKED: StringName = &"knocked out"
const STUNNED: StringName = &"crew_stunned"

## The top of the tree. Everything added here reaches every part below it.
@export var tank: FoxAttributeMap

## The knocked-out rule remembers what it took, so it goes straight on the weapon it applies to.
@export var cannon: FoxAttributeMap

@export var target: Node

## How much the boost is currently worth. Rules are not edited in place, so changing it means
## taking the old rule off and putting a new one on under the same id.
var _boost: int = 0

#endregion


#region Built-In Virtuals

func _ready() -> void:
	_button("+1 damage on the tank", _boost_up)
	_button("-1 damage on the tank", _boost_down)
	_button("bigger cannon", _toggle_bigger_cannon)
	_button("cannon knocked out", _toggle_knocked_out)
	_button("stun the crew", _toggle_stun)
	_button("repair the wall", _repair)

#endregion


#region Private

func _button(text: String, pressed: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(pressed)
	add_child(button)


func _boost_up() -> void:
	_set_boost(_boost + 1)


func _boost_down() -> void:
	_set_boost(_boost - 1)


## Targets damage, so it reaches every map under the tank and lands on the two that shoot. The hull
## and the turret track it and are not touched, because neither of them holds a damage.
func _set_boost(amount: int) -> void:
	_boost = amount
	tank.remove_rule(BOOST)

	if _boost != 0:
		tank.add_rule(FlatRule.new(BOOST, &"damage", float(_boost)))


func _toggle_bigger_cannon() -> void:
	if tank.get_rule_summary().has(BIGGER):
		tank.remove_rule(BIGGER)
		return

	tank.add_rule(BiggerCannon.new(BIGGER))


func _toggle_knocked_out() -> void:
	if cannon.get_rule_summary().has(WRECKED):
		cannon.remove_rule(WRECKED)
		return

	cannon.add_rule(KnockedOut.new(WRECKED))


## A flag on the tank reaches every part under it, and each part decides for itself what it means.
func _toggle_stun() -> void:
	if tank.has_flag(STUNNED):
		tank.erase_flag(STUNNED)
		return

	tank.increment_flag(STUNNED)


func _repair() -> void:
	target.call(&"reset")

#endregion
