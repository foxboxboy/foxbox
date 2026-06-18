extends Node3D

@onready var fox_aim_gimbal_3d: FoxAimGimbal3D = $Offset/FoxAimGimbal3D
@onready var cylinder: MeshInstance3D = $Cylinder

@export var sensitivity := 2.0


func _process(delta: float) -> void:
	var look_input := Input.get_vector("ui_right","ui_left","ui_down","ui_up")
	look_input *= delta * sensitivity
	fox_aim_gimbal_3d.apply_rotation_input(look_input)
	
	if Input.is_action_pressed("ui_accept"):
		fox_aim_gimbal_3d.aim_at_position(cylinder.position)
