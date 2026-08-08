# The readout.
extends Label




#region Variables

const Player2D = preload("res://demos/interaction/2d/player_2d.gd")
const Hands2D = preload("res://demos/interaction/2d/hands_2d.gd")

@export var player: Player2D
@export var hands: Hands2D

#endregion




#region Built-In Virtuals

func _process(_delta: float) -> void:
	var upright: String = "on" if hands.is_upright() else "off"
	if hands.is_upright():
		# Worth saying, or right dragging looks broken.
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

## The prop's own label when it has one, falling back to the node name.
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
