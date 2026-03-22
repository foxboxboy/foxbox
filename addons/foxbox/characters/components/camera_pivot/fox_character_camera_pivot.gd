extends FoxNode3D
class_name FoxCharacterCameraPivot
## @deprecated

@export_group("Components")
@export var shoulder_camera_pivot : Marker3D
@export var first_person_camera_pivot : Marker3D

@export_group("Crouch Settings")
@export var stand_height : float = 2.0
@export var crouch_height : float = 1.8

func _ready() -> void:
	stand()
	assert(shoulder_camera_pivot != null, "ERROR: No shoulder_camera_pivot assigned to FoxCharacterCameraPivot: "+str(get_path()))
	assert(first_person_camera_pivot != null, "ERROR: No first_person_camera_pivot assigned to FoxCharacterCameraPivot: "+str(get_path()))


func crouch() -> void:
	_animate_shape(crouch_height)

func stand() -> void:
	_animate_shape(stand_height)

func _animate_shape(target_y: float) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.2)
