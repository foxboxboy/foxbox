extends Node

signal move_input(input_direction: Vector2)
signal look_input(mouse_relative: Vector2)
signal jump()
signal zoom_in()
signal zoom_out()

#func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		look_input.emit(event.relative)

func _process(_delta):
	# Using Godot's built-in vector getter for WASD/Arrows
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	move_input.emit(input_dir)
	
	if Input.is_action_pressed("ui_accept"):
		jump.emit()
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in.emit()
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_out.emit()
