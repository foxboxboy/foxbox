extends Control

@onready var pause_screen: Panel = $PauseScreen

@onready var w: Button = $Control/W
@onready var a: Button = $Control/A
@onready var s: Button = $Control/S
@onready var d: Button = $Control/D

func _ready() -> void:
	unpause()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pause()
			
		else:
			unpause()


func pause():
	get_tree().paused = true
	pause_screen.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func unpause():
	get_tree().paused = false
	pause_screen.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	
	a.modulate.a = clamp(-input_dir.x + 0.5,0.5,1)
	d.modulate.a = clamp(input_dir.x + 0.5,0.5,1)
	s.modulate.a = clamp(-input_dir.y + 0.5,0.5,1)
	w.modulate.a = clamp(input_dir.y + 0.5,0.5,1)
		
