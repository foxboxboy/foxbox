extends Node
class_name Trait

var host: Node

func _enter_tree():
	setup()

func setup():
	pass # Override this!

func undo():
	queue_free() # Removing the node removes the effect
