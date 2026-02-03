extends Node3D

# TWEAK THESE VALUES
@export var max_push_distance: float = -0.4  # Meters to push forward
@export var max_drop_distance: float = -1.5  # Meters to push down
@export var activation_threshold: float = -45.0 # Angle to start pushing
@export var max_look_down_angle: float = -89.0 # "Toes" angle

#@export var camera : Camera3D #= get_parent() # Assuming parent is the Camera3D
@onready var default_position: Vector3 = position # Remember start pos

func _process(delta):
	apply_safety_offset(delta)

func apply_safety_offset(delta):
	max_push_distance = 1  # Meters to push forward
	max_drop_distance = -1.0  # Meters to push down
	activation_threshold = -45.0 # Angle to start pushing
	max_look_down_angle = -89.0 # "Toes" angle
	
	var current_pitch = rad_to_deg(self.global_rotation.x)
	
	# NOTE: In Godot, looking down is usually NEGATIVE (-90).
	# If your project has looking down as POSITIVE, flip these checks.
	if current_pitch < activation_threshold:
		
		# 1. Calculate Severity (0.0 to 1.0)
		var range_span = abs(max_look_down_angle - activation_threshold)
		var degrees_past_threshold = abs(current_pitch - activation_threshold)
		var push_factor = clamp(degrees_past_threshold / range_span, 0.0, 1.0)
		
		# 2. Calculate Offset
		# Forward is -Z in Godot
		var forward_push = Vector3(0, 0, -max_push_distance) * push_factor
		var down_push = Vector3(0, -max_drop_distance, 0) * push_factor
		
		# 3. Apply
		position = default_position + forward_push + down_push
		
	else:
		# Smoothly snap back if looking up
		position = position.lerp(default_position, 5.0 * delta)
