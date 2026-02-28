extends FoxModifier
class_name FoxDemoModifierSwordWeapon

@export var sword_scene : PackedScene

func _on_execute(target: Node) -> void:
	if target is FoxDemoKnight:
		var new_sword := sword_scene.instantiate()
		if target.weapon_socket.get_child_count() > 0:
			target.weapon_socket.get_child(0).queue_free()
		target.weapon_socket.add_child(new_sword)


func _on_reapply(_target: Node, _stack: int = 1) -> void:
	pass

func _on_remove(_target : Node) -> void:
	if _target is FoxDemoKnight:
		_target.weapon_socket.get_child(0).queue_free()
