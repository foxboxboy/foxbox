extends Node

@export var my_character : TateCharacter
@export var player_character : TateCharacter

func _process(delta: float) -> void:
	my_character.look_at_position_smooth(player_character.global_position, delta)
