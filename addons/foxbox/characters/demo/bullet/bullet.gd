extends Node3D

var speed := 30.0
var lifetime := 0.5

var _lifetime_elapsed := 0.0

func _process(delta: float) -> void:
	position += basis.z * speed * delta
	
	_lifetime_elapsed += delta
	
	if _lifetime_elapsed > lifetime:
		queue_free()
