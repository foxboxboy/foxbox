extends TateNode3D
class_name TateCharacterHitbox

@export var collision_shape : CollisionShape3D

@export_group("Crouch Settings")
@export var stand_height : float = 2.2
@export var crouch_height : float = 1.8

# Pre-calculate positions to keep feet on the ground
# Assuming the pivot is at the center of the capsule
@onready var _stand_y : float = stand_height / 2.0
@onready var _crouch_y : float = crouch_height / 2.0

func _ready() -> void:
	stand()

func crouch() -> void:
	_animate_shape(crouch_height, _crouch_y)

func stand() -> void:
	_animate_shape(stand_height, _stand_y)

func _animate_shape(target_h: float, target_y: float) -> void:
	# The exact same logic as before, just encapsulated
	var tween = create_tween().set_parallel(true)
	tween.tween_property(collision_shape.shape, "height", target_h, 0.2)
	tween.tween_property(collision_shape, "position:y", target_y, 0.2)
