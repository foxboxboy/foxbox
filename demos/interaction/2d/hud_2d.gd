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
	var upright := "on" if hands.is_upright() else "off"
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
func _pointing_at() -> String:
	var target := player.get_target()
	if target == null:
		return "nothing"

	var prop := target.get_parent()
	return str(prop.label) if prop and "label" in prop else prop.name

#endregion
