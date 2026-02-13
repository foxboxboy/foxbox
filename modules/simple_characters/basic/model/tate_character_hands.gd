extends TateNode3D
class_name TateCharacterHands

## Handles IK and hands for things like items.

@export var left_hand_target : Marker3D
@export var right_hand_target : Marker3D

@export var left_hand_ik : CCDIK3D
@export var right_hand_ik : CCDIK3D


#region Holding Nodes

func empty_hands() -> void:
	empty_right_hand()
	empty_left_hand()


func empty_left_hand() -> void:
	for child in left_hand_target.get_children():
		child.queue_free()


func empty_right_hand() -> void:
	for child in right_hand_target.get_children():
		child.queue_free()


func hold_node(node : Node, left_hand := false) -> bool:
	if left_hand:
		if left_hand_has_node(): return false
		left_hand_target.add_child(node)
		node.position = Vector3.ZERO
		return true
	else:
		if right_hand_has_node(): return false
		right_hand_target.add_child(node)
		node.position = Vector3.ZERO
		return true


func left_hand_has_node() -> bool:
	return left_hand_target.get_child_count() > 0


func right_hand_has_node() -> bool:
	return right_hand_target.get_child_count() > 0


func get_right_hand_node() -> Node:
	if not right_hand_has_node():
		push_warning("WARNING: No node found under right hand for TateCharacterHands: ",get_path())
		return null
	return right_hand_target.get_child(0)


func get_left_hand_node() -> Node:
	if not right_hand_has_node():
		push_warning("WARNING: No node found under left hand for TateCharacterHands: ",get_path())
		return null
	return left_hand_target.get_child(0)

#endregion





#region IK

func enable_right_hand_ik():
	right_hand_ik.active = true


func disable_right_hand_ik():
	right_hand_ik.active = false


func enable_left_hand_ik():
	left_hand_ik.active = true


func disable_left_hand_ik():
	left_hand_ik.active = false

#endregion
