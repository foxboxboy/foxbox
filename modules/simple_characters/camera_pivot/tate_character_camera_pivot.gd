extends TateNode3D
class_name TateCharacterCameraPivot

@export var shoulder_camera_pivot : Marker3D
@export var first_person_camera_pivot : Marker3D


func _ready() -> void:
	stand()
	assert(shoulder_camera_pivot != null, "ERROR: No shoulder_camera_pivot assigned to TateCharacterCameraPivot: "+str(get_path()))
	assert(first_person_camera_pivot != null, "ERROR: No first_person_camera_pivot assigned to TateCharacterCameraPivot: "+str(get_path()))


@export_group("Crouch Settings")
@export var stand_height : float = 2.0
@export var crouch_height : float = 1.8


func crouch() -> void:
	_animate_shape(crouch_height)

func stand() -> void:
	_animate_shape(stand_height)

func _animate_shape(target_y: float) -> void:
	# The exact same logic as before, just encapsulated
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.2)
