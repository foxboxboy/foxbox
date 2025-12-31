#@tool
extends SkeletonIK3D

@export var is_active := true

func _process(_delta: float) -> void:
	if is_active:
		start()
	else:
		stop()
