extends AnimatableBody3D

@export var a : Vector3
@export var b : Vector3
@export var time := 2.0

func _ready() -> void:
	move()


func move():
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_property(self, "position", b, time)
	move_tween.tween_property(self, "position", a, time)
	
	await get_tree().create_timer(2 * time).timeout
	
	move()
