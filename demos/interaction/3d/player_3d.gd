# Where you are looking. Nothing about carrying lives here.
#
# The camera is fixed, so aiming means turning two raycasts to follow the cursor: one to find
# what you are pointing at, and one to find where in the world the cursor lands.
extends Camera3D




#region Variables

## How far to cast when looking for the point under the cursor. Long enough to reach the far
## side of the room, since it only has to find the floor.
const CURSOR_RANGE: float = 100.0

## Finds what you are pointing at.
@export var interaction_sensor: FoxInteractionRayCast3D

## Finds where the cursor lands in the world, which is where a held object is carried to.
@export var cursor_raycast: RayCast3D

## Set while the cursor is captured for a turn. A captured cursor reports the middle of the
## window, so aiming at it would swing everything to the centre of the screen.
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


## Where the sensor's ray struck, falling back to [param fallback] when it hit nothing.
## [br][br]
## This is the point to take hold of. The cursor is not: the sensor only points towards it, so
## the cursor is normally well past the object, and grabbing there gives a lever longer than the
## object itself.
func get_hit_point(fallback: Vector3) -> Vector3:
	return interaction_sensor.get_collision_point() if interaction_sensor.is_colliding() else fallback


## Where the cursor lands in the world. Falls back to the far end of the cast when it points at
## the sky, so a held object hangs out at arm's length rather than snapping to the camera.
func get_cursor_world_point() -> Vector3:
	if cursor_raycast.is_colliding():
		return cursor_raycast.get_collision_point()

	return cursor_raycast.to_global(cursor_raycast.target_position)

#endregion




#region Private

## The cursor's direction through the world, expressed in this camera's own space so it can be
## handed straight to a child raycast's target_position.
func _local_mouse_direction() -> Vector3:
	var world_normal: Vector3 = project_ray_normal(get_viewport().get_mouse_position())
	return global_transform.basis.inverse() * world_normal

#endregion
