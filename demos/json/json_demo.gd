extends Node2D

@onready var player: CharacterBody2D = $Player

const FILE_PATH: String = "user://player.json"

func _on_save_button_pressed() -> void:
	var file: DemoPlayerJsonFile = DemoPlayerJsonFile.new()
	var data: Dictionary = {"transform": FoxJson.transform_2d_to_array(player.transform)}
	if file.write(FILE_PATH, data) != OK:
		push_error(file.get_error_message())


func _on_load_button_pressed() -> void:
	var file: DemoPlayerJsonFile = DemoPlayerJsonFile.new()
	if file.read(FILE_PATH) != OK:
		push_error(file.get_error_message())
		return
	player.transform = FoxJson.array_to_transform_2d(file.data["transform"], player.transform)
