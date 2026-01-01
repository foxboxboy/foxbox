#@tool
extends SkeletonIK3D

@export var is_active := true

func _ready() -> void:
	if is_active:
		start()
	else:
		stop()
