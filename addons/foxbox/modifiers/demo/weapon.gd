class_name FoxDemoModifierWeapon
extends FoxModifier

@export var weapon_scene: PackedScene
var spawned_weapon: Node

func _on_execute(target: Node) -> void:
	if target is FoxDemoKnight and weapon_scene:
		spawned_weapon = weapon_scene.instantiate()
		target.weapon_socket.add_child(spawned_weapon)

func _on_reapply(_target: Node, _stack: int = 1) -> void:
	pass

func _on_remove(_target: Node) -> void:
	# Because the Slot Policy handles kicking out old weapons, 
	# we just safely delete the specific weapon this modifier spawned!
	if is_instance_valid(spawned_weapon):
		spawned_weapon.queue_free()
