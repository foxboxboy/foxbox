# The camera is fixed, so aiming means turning two raycasts to follow the cursor: one for what
# you are pointing at, one for where the cursor lands in the world.
extends Camera3D




#region Variables

## Long enough to reach the far wall.
const CURSOR_RANGE: float = 100.0

@export var interaction_sensor: FoxInteractionRayCast3D
@export var cursor_raycast: RayCast3D

## Set while the cursor is captured for a turn, when it reports the middle of the window.
var aiming_frozen: bool = false

#endregion




#region Built-In Virtuals

func _ready() -> void:
	cursor_raycast.enabled = true


func _physics_process(_delta: float) -> void:
	if aiming_frozen:
		return

	var direction: Vector3 = _local_mouse_direction()
	interaction_sensor.target_position = direction * interaction_sensor.interaction_range
	cursor_raycast.target_position = direction * CURSOR_RANGE
	cursor_raycast.force_raycast_update()

#endregion




#region Public API

## What the sensor is pointing at, or [code]null[/code].
func get_target() -> FoxInteractableArea3D:
	return interaction_sensor.get_current_target()


## Where the ray struck, falling back to [param fallback] when it hit nothing.
## [br][br]
## Take hold here, not at the cursor. The cursor is usually well past the object, which gives a
## lever longer than the object itself.
func get_hit_point(fallback: Vector3) -> Vector3:
	return interaction_sensor.get_collision_point() if interaction_sensor.is_colliding() else fallback


## Where the cursor lands in the world. Points at the sky and it falls back to the far end of the
## cast, so what you are holding hangs at arm's length instead of snapping to the camera.
func get_cursor_world_point() -> Vector3:
	if cursor_raycast.is_colliding():
		return cursor_raycast.get_collision_point()

	return cursor_raycast.to_global(cursor_raycast.target_position)

#endregion




#region Private

## The cursor's direction through the world, in this camera's own space so it can go straight into
## a child raycast's target_position.
func _local_mouse_direction() -> Vector3:
	var world_normal: Vector3 = project_ray_normal(get_viewport().get_mouse_position())
	return global_transform.basis.inverse() * world_normal

#endregion
