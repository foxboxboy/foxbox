extends TateNode3D
class_name TateCharacterCameraPivot

@export var shoulder_camera_pivot : Marker3D
@export var first_person_camera_pivot : Marker3D


func _ready() -> void:
	assert(shoulder_camera_pivot != null, "ERROR: No shoulder_camera_pivot assigned to TateCharacterCameraPivot: "+str(get_path()))
	assert(first_person_camera_pivot != null, "ERROR: No first_person_camera_pivot assigned to TateCharacterCameraPivot: "+str(get_path()))
