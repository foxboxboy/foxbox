# The readout. Reads state, never changes any.
extends Label




#region Variables

## Typed against the preloaded scripts rather than class_names, so the demo does not put names as
## ordinary as Player3D and Hands3D into every project that opens it.
const Player3D = preload("res://demos/interaction/3d/player_3d.gd")
const Hands3D = preload("res://demos/interaction/3d/hands_3d.gd")

@export var player: Player3D
@export var hands: Hands3D

#endregion




#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"Mouse aims, left click picks up and puts down",
		"Right drag turns what you are holding, wheel raises and lowers it",
		"",
		"pointing at:  %s" % _pointing_at(),
		"holding:      %s" % ("yes" if hands.is_holding() else "no"),
		"lift:         %.1f m" % hands.get_lift(),
	])

#endregion




#region Private

## The name of whatever the sensor has found. Interactables sit under the object they belong to,
## so the parent is the interesting name.
func _pointing_at() -> String:
	var target := player.get_target()
	if target == null:
		return "nothing"

	var owner_node := target.get_parent()
	return owner_node.name if owner_node else target.name

#endregion
