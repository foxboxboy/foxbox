# DemoDummy
extends RefCounted

var health: float = 100.0

# This overrides the print() behavior so it looks clean in the console
func _to_string() -> String:
	return "[Dummy HP: %s]" % health
