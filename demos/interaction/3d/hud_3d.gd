# The readout.
extends Label




#region Variables

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

## The object's own label when it has one, falling back to the node name.
func _pointing_at() -> String:
	var target: FoxInteractableArea3D = player.get_target()
	if target == null:
		return "nothing"

	var prop: Node = target.get_parent()
	if prop == null:
		return String(target.name)

	if &"label" in prop:
		return String(prop.get(&"label"))

	return String(prop.name)

#endregion
