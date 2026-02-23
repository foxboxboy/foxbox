extends FoxNode3D
class_name FoxCharacterHands

## Handles IK and hand slots for things like items.

@export var left_hand_slot : Marker3D
@export var right_hand_slot : Marker3D

@export var left_hand_ik : TwoBoneIK3D
@export var right_hand_ik : TwoBoneIK3D






#region Holding Nodes

func empty_hands() -> void:
	empty_right_hand()
	empty_left_hand()


func empty_left_hand() -> void:
	for child in left_hand_slot.get_children():
		remove_child(child)


func empty_right_hand() -> void:
	for child in right_hand_slot.get_children():
		remove_child(child)


## Returns true if a node was replaced.
func hold_node(node : Node, left_handed := false) -> bool:
	var cleared := false
	
	if left_handed:
		if left_hand_has_node(): 
			empty_left_hand()
			cleared = true
		left_hand_slot.add_child(node)
	else:
		if right_hand_has_node(): 
			empty_right_hand()
			cleared = true
		right_hand_slot.add_child(node)
		
	if node is Node3D:
		node.position = Vector3.ZERO
		node.rotation = Vector3.ZERO
	
	return cleared


func left_hand_has_node() -> bool:
	return left_hand_slot.get_child_count() > 0


func right_hand_has_node() -> bool:
	return right_hand_slot.get_child_count() > 0


func get_right_hand_node() -> Node:
	if not right_hand_has_node():
		push_warning("WARNING: No node found under right hand for FoxCharacterHands: ",get_path())
		return null
	return right_hand_slot.get_child(0)


func get_left_hand_node() -> Node:
	if not right_hand_has_node():
		push_warning("WARNING: No node found under left hand for FoxCharacterHands: ",get_path())
		return null
	return left_hand_slot.get_child(0)

#endregion







#region Items

func hold_item(item : FoxHoldableItem, left_handed := false):
	
	# this exists for readability
	var right_handed := not left_handed
	
	if item.is_two_handed():
		empty_hands()
	elif right_handed:
		empty_right_hand()
	elif left_handed:
		empty_left_hand()
	
	
	hold_node(item, left_handed)

	if item.main_hand_target == null:
		return
	if item.main_elbow_pole == null:
		return
	

	
	## MAIN HAND
	if right_handed:
		enable_right_hand_ik(item.main_hand_target, item.main_elbow_pole)
	elif left_handed:
		enable_left_hand_ik(item.main_hand_target, item.main_elbow_pole)
	
	
	## SECONDARY
	if item.off_hand_target == null:
		return
	if item.off_elbow_pole == null:
		return
	
	if left_handed:
		enable_right_hand_ik(item.off_hand_target, item.off_elbow_pole)
	elif right_handed:
		enable_left_hand_ik(item.off_hand_target, item.off_elbow_pole)
	
#endregion







#region IK

func enable_right_hand_ik(target_node : Node3D, pole_node : Node3D) -> void:
	right_hand_ik.set_target_node(0,target_node.get_path())
	right_hand_ik.set_pole_node(0,pole_node.get_path())
	right_hand_ik.active = true


func disable_right_hand_ik() -> void:
	right_hand_ik.active = false


func enable_left_hand_ik(target_node : Node3D, pole_node : Node3D) -> void:
	left_hand_ik.set_target_node(0,target_node.get_path())
	left_hand_ik.set_pole_node(0,pole_node.get_path())
	left_hand_ik.active = true


func disable_left_hand_ik() -> void:
	left_hand_ik.active = false

#endregion
