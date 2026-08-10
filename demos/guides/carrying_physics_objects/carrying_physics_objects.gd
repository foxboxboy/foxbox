extends Node3D

# Runnable version of the "Carrying physics objects" guide. Left click grabs whatever the ray is
# pointing at, left click again drops it.
#
# Mouse look is here so there is something to aim at. It is not part of the module, and the guide
# leaves it out.

@onready var aim: RayCast3D = $Camera3D/Aim
@onready var dragger: FoxPhysicsDragger3D = $Camera3D/Dragger
@onready var camera: Camera3D = $Camera3D

@export var look_sensitivity: float = 0.003


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_look(motion.relative)
		return

	if event.is_action_pressed(&"pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return

	if dragger.is_holding():
		dragger.release()
		return

	var body: RigidBody3D = aim.get_collider() as RigidBody3D
	if body != null:
		dragger.grab(body, aim.get_collision_point())


func _look(relative: Vector2) -> void:
	rotate_y(-relative.x * look_sensitivity)
	camera.rotate_x(-relative.y * look_sensitivity)
	camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)
