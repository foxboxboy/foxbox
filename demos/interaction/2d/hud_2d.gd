# The readout. Reads state, never changes any.
extends Label




#region Variables

## Typed against the preloaded scripts rather than class_names, so the demo does not put names as
## ordinary as Player2D and Hands2D into every project that opens it.
const Player2D = preload("res://demos/interaction/2d/player_2d.gd")
const Hands2D = preload("res://demos/interaction/2d/hands_2d.gd")

@export var player: Player2D
@export var hands: Hands2D

#endregion




#region Built-In Virtuals

func _process(_delta: float) -> void:
	var upright: String = "on" if hands.is_upright() else "off"
	if hands.is_upright():
		# Worth saying, or right dragging looks broken rather than overruled.
		upright += "  (held level, so turning has no effect)"

	text = "\n".join([
		"Arrows move, mouse aims, left click picks up and puts down",
		"Right drag turns what you are holding, Space toggles upright",
		"",
		"pointing at:  %s" % _pointing_at(),
		"holding:      %s" % ("yes" if hands.is_holding() else "no"),
		"keep upright: %s" % upright,
	])

#endregion




#region Private

## The name of whatever the sensor has found, using the prop's own label when it has one.
## [br][br]
## The label is asked for by name, so the readout never has to know what kind of node it is
## looking at. An interactable sitting under something with no label falls back to the node name.
func _pointing_at() -> String:
	var target: FoxInteractableArea2D = player.get_target()
	if target == null:
		return "nothing"

	var prop: Node = target.get_parent()
	if prop == null:
		return String(target.name)

	if &"label" in prop:
		return String(prop.get(&"label"))

	return String(prop.name)

#endregion
