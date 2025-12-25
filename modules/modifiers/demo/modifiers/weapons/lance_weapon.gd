extends TateModifier
class_name TateDemoModifierLanceWeapon

@export var lance_scene : PackedScene

func _on_execute(target: Node) -> void:
	if target is TateDemoKnight:
		var new_lance := lance_scene.instantiate()
		if target.weapon_socket.get_child_count() > 0:
			target.weapon_socket.get_child(0).queue_free()
		target.weapon_socket.add_child(new_lance)


func _on_remove(_target : Node) -> void:
	pass#if target is TateDemoKnight:
		#target.weapon_socket.get_child(0).queue_free()
