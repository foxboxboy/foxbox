extends FoxNode3D
class_name FoxHoldableItem
## An item that can be held by a FoxCharacter.
## Utilizes IK targets and poles to hold the item. 
## When setting up, keep at 0,0,0.

## The main hand that will be used for IK.
@export var main_hand_target: Marker3D
## The off hand that will be used for IK. Leave blank for a one handed item.
@export var off_hand_target: Marker3D

## The "pole" used for the elbow IK. In other words, where the elbow will be magnetized to.
## This is to prevent animation errors and give more control of the IK animation.
@export var main_elbow_pole: Marker3D
## The "pole" used for the elbow IK. In other words, where the elbow will be magnetized to.
## This is to prevent animation errors and give more control of the IK animation.
## Leave blank for a one handed item.
@export var off_elbow_pole: Marker3D


func _ready() -> void:
	if off_hand_target and main_hand_target == null:
		push_warning("WARNING: FoxHoldableItem has a off_hand_target but no main_hand_target, ",get_path())
	if off_elbow_pole and main_elbow_pole == null:
		push_warning("WARNING: FoxHoldableItem has a off_elbow_pole but no main_elbow_pole, ",get_path())



func is_two_handed() -> bool:
	return off_hand_target != null
