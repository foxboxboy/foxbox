extends TateNode3D
class_name TateCameraArm
## Zooms in or out depending on input to a maxiumum amount based on sensitivity

signal spring_length_changed(new_spring_length)

@export var max_zoom := 200.0
@export var sensitivity := 1.0
@export var default_lerp_speed := 0.05
@export var spring_arm : SpringArm3D
@export var target_spring_length := 5.0


var lerp_speed := 0.05

## Determines if the camera can be zoomed in and out
var is_active := true


func _ready():
	if spring_arm == null:
		spring_arm = _find_spring_arm()
	
	lerp_speed = default_lerp_speed
	emit_signal("spring_length_changed", spring_arm.spring_length)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_update_spring_length()


func _find_spring_arm() -> SpringArm3D:
	if is_instance_of(self, SpringArm3D):
		return get_node(".")
	elif get_parent() is SpringArm3D:
		return get_parent()
	else:
		assert(spring_arm != null, "ERROR: No spring_arm was assigned nor could be found for TateCameraArm. "+str(get_path()))
	
	return null


func zoom_in():
	if is_active:
		change_zoom(sensitivity)


func zoom_out():
	if is_active:
		change_zoom(-sensitivity)


func get_zoom_percentage() -> float:
	return spring_arm.spring_length / max_zoom


func _update_spring_length():
	spring_arm.spring_length = lerpf(spring_arm.spring_length,target_spring_length,lerp_speed)
	emit_signal("spring_length_changed", spring_arm.spring_length)


func change_zoom(amount : float):
	target_spring_length = target_spring_length + amount
	target_spring_length = clamp(target_spring_length,0.0, max_zoom)
