#@tool
extends SkeletonIK3D

@export var should_start := true

func _ready() -> void:
	
	if should_start:
		start()
	else:
		stop()
