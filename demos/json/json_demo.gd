extends Node2D

@onready var player: CharacterBody2D = $Player

const FILE_PATH: String = "res://demos/json/data/player.json"

func _on_save_button_pressed() -> void:
	var file: DemoPlayerJSONFile = DemoPlayerJSONFile.new()
	var data: Dictionary = {"position": FoxJSON.transform_2d_to_array(player.transform)}
	if file.write(FILE_PATH, data) != OK:
		push_error(file.get_error_message())


func _on_load_button_pressed() -> void:
	var file: DemoPlayerJSONFile = DemoPlayerJSONFile.new()
	if file.read(FILE_PATH) != OK:
		push_error(file.get_error_message())
		return
	player.transform = FoxJSON.array_to_transform_2d(file.data["position"], player.transform)



func _on_save_button_2_pressed() -> void:
	# In a real game you wouldn't have two scripts for the same file.
	#
	# We just have a "JsonFile2" here to show how it'd work if you had
	# make a game, exported it with DemoPlayerJSONFile, then updated
	# DemoPlayerJSONFile, re-exported it, and loaded that data again.
	var file: DemoPlayerJSONFile2 = DemoPlayerJSONFile2.new()
	var data: Dictionary = {"transform": FoxJSON.transform_2d_to_array(player.transform)}
	if file.write(FILE_PATH, data) != OK:
		push_error(file.get_error_message())



func _on_load_button_2_pressed() -> void:
	var file: DemoPlayerJSONFile2 = DemoPlayerJSONFile2.new()
	if file.read(FILE_PATH) != OK:
		push_error(file.get_error_message())
		return
	player.transform = FoxJSON.array_to_transform_2d(file.data["transform"], player.transform)



func _on_backup_button_pressed() -> void:
	var file: DemoPlayerJSONFile2 = DemoPlayerJSONFile2.new()
	var path : String = DemoPlayerJSONFile2.get_backup_path(FILE_PATH)
	if file.read(path) != OK:
		push_error(file.get_error_message())
		return
	player.transform = FoxJSON.array_to_transform_2d(file.data["transform"], player.transform)
