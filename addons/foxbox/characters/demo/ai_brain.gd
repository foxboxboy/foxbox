extends Node

@export var my_character : FoxCharacter
@export var player_character : FoxCharacter

func _process(delta: float) -> void:
	my_character.look_at_position_smooth(player_character.global_position, delta)
