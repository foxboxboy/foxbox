extends Node

signal move_input(input_direction: Vector2)
signal look_input(mouse_relative: Vector2)
signal jump_pressed
signal jump_held
signal jump_released
signal zoom_in
signal zoom_out
signal sprint_pressed
signal sprint_released
signal free_cam_pressed
signal free_cam_released
signal dash_pressed

#func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		look_input.emit(event.relative)

func _process(_delta):
	# Using Godot's built-in vector getter for WASD/Arrows
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	move_input.emit(input_dir)
	
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	if Input.is_action_pressed("jump"):
		jump_held.emit()
	if Input.is_action_just_released("jump"):
		jump_released.emit()
	
	if Input.is_action_just_pressed("dash"):
		dash_pressed.emit()
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in.emit()
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_out.emit()
	
	if Input.is_action_pressed("sprint"):
		sprint_pressed.emit()
	elif Input.is_action_just_released("sprint"):
		sprint_released.emit()

	if Input.is_action_pressed("free_cam"):
		free_cam_pressed.emit()
	elif Input.is_action_just_released("free_cam"):
		free_cam_released.emit()
