extends TateModifier
class_name TateDemoModifierSwordWeapon

@export var sword_scene : PackedScene

func _on_execute(target: Node) -> void:
	if target is TateDemoKnight:
		var new_sword := sword_scene.instantiate()
		if target.weapon_socket.get_child_count() > 0:
			target.weapon_socket.get_child(0).queue_free()
		target.weapon_socket.add_child(new_sword)


func _on_remove(target : Node) -> void:
	pass#if target is TateDemoKnight:
		#target.weapon_socket.get_child(0).queue_free()
