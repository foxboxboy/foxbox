class_name DemoPlayerJsonFile2
extends FoxJsonFile


func _get_format() -> int:
	return 2


func _migrate(contents: Dictionary, from_format: int) -> Dictionary:
	print("Upgrading json file from format ",from_format," to format 2")
	
	if from_format == 1:
		contents["transform"] = contents["position"]
		contents.erase("position")
	return contents
