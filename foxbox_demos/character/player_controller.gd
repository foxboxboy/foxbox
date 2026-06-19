class_name PlayerController
extends Node
## Captures mouse input, steers the Pawn, and pitches the camera gimbal.

@export_group("Nodes")
@export var pawn: GameCharacter
@export var aim_gimbal: FoxAimGimbal3D

@export_group("Settings")
@export var mouse_sensitivity: float = 0.003
@export var free_look_return_speed: float = 10.0

var is_free_looking: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		if Input.is_action_pressed("free_look"): # E.g., holding the Alt key
			is_free_looking = true
			# Feed BOTH X and Y to the gimbal. The body stays still!
			aim_gimbal.apply_rotation_input(event.relative * mouse_sensitivity)
			
		else:
			is_free_looking = false
			# 1. Pitch the camera up and down (Y-axis goes to Gimbal)
			aim_gimbal.apply_rotation_input(Vector2(0, event.relative.y) * mouse_sensitivity)
			
			# 2. Turn the whole character left and right (X-axis goes to Pawn)
			pawn.rotate_y(-event.relative.x * mouse_sensitivity)


func _process(delta: float) -> void:
	# Smoothly snap the gimbal's yaw back to center when we let go of Free Look!
	if not is_free_looking and aim_gimbal.yaw != 0.0:
		aim_gimbal.yaw = move_toward(aim_gimbal.yaw, 0.0, delta * free_look_return_speed)


func _physics_process(_delta: float) -> void:
	if not pawn: return
		
	# ---------------------------------------------------------
	# INTENTS
	# ---------------------------------------------------------
	# Because the Pawn actually rotated this time, its local 'forward' perfectly matches 
	# the camera's 'forward'. We just hand the raw WASD input straight to the dashboard!
	
	pawn.intent_movement = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	
	pawn.intent_sprint = Input.is_action_pressed("sprint")
	pawn.intent_crouch = Input.is_action_pressed("crouch")
	
	if Input.is_action_just_pressed("jump"):
		pawn.intent_jump = true
		
	if Input.is_action_just_pressed("dash"):
		pawn.intent_dash = true
		
	if Input.is_action_just_released("jump"):
		pawn.intent_jump_released = true
