# The readout. Each row is a pair of Labels in a GridContainer, so this only writes the live half.
extends VBoxContainer




#region Variables

const Player2D = preload("res://demos/interaction/2d/player_2d.gd")
const Hands2D = preload("res://demos/interaction/2d/hands_2d.gd")

@export var player: Player2D
@export var hands: Hands2D

## The value beside each row's name. The names, and the controls above them, are scene text.
@export var pointing_at: Label
@export var holding: Label
@export var upright: Label

#endregion




#region Built-In Virtuals

func _process(_delta: float) -> void:
	pointing_at.text = _pointing_at()
	holding.text = "yes" if hands.is_holding() else "no"

	if hands.is_upright():
		# Worth saying, or right dragging looks broken.
		upright.text = "on   (held level, so turning has no effect)"
	else:
		upright.text = "off"

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
		# Through a typed local, because get() comes back as a Variant.
		var written: String = prop.get(&"label")
		return written

	return String(prop.name)

#endregion
