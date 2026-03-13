class_name FoxCharacterStateMachine
extends FoxStateMachine

@export var physics_body: CharacterBody3D
@export var model: FoxCharacterModel
@export var character: FoxCharacter

func _ready() -> void:
	super._ready()
	
	for child in get_children():
		if child is FoxCharacterState:
			child.physics_body = physics_body
			child.model = model
			child.character = character
