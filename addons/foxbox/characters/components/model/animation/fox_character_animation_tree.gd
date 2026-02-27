extends FoxNode
class_name FoxCharacterAnimationTree

signal swing_right_started
signal swing_right_ended
signal swing_left_started
signal swing_left_ended


@export var animation_tree : AnimationTree

@onready var _animation_player : AnimationPlayer = get_node(animation_tree.anim_player)
@onready var _base_movement = animation_tree.get("parameters/BaseMovement/playback")
@onready var _upper_body = animation_tree.get("parameters/UpperBody/playback")

const PATH_LOCOMOTION_PLAYBACK = "parameters/BaseMovement/playback"
const PATH_LOCOMOTION_CROUCH_BLEND = "parameters/BaseMovement/Crouch/blend_position"
const PATH_LOCOMOTION_STAND_BLEND = "parameters/BaseMovement/Stand/blend_position"
const PATH_UPPER_BODY_PLAYBACK = "parameters/UpperBody/playback"
const PATH_TRIGGER_SWING = "parameters/Swing/request"
const PATH_AIR_BLEND = "parameters/BaseMovement/AirLogic/blend_position"


## blend_amount: -1.0 = full backwards, 0.0 = neutral, 1.0 = full fowardwards
func update_movement(blend_amount: float) -> void:
	blend_amount = clampf(blend_amount, -1, 1)
	
	# Just update BOTH. It's cleaner than checking state.
	animation_tree.set(PATH_LOCOMOTION_CROUCH_BLEND, blend_amount)
	animation_tree.set(PATH_LOCOMOTION_STAND_BLEND, blend_amount)


func transition_to_crouch() -> void:
	_base_movement.travel("Crouch")

func transition_to_stand() -> void:
	_base_movement.travel("Stand")

func transition_to_air() -> void:
	_base_movement.travel("AirLogic")


func update_air_physics(vertical_velocity: float) -> void:	
	var blend_multiplier := 3.0
	var raw_blend := clampf(vertical_velocity * blend_multiplier, -1.0, 1.0)
	
	var blend_steps := 4
	var stepped_blend : float = round(raw_blend * blend_steps) / blend_steps
		
	animation_tree.set(PATH_AIR_BLEND, stepped_blend)


func swing(use_right_hand : bool = true) -> void:
	var animation_name = "swing_right" if use_right_hand else "swing_left"
	var start_signal = swing_right_started if use_right_hand else swing_left_started
	var end_signal = swing_right_ended if use_right_hand else swing_left_ended
	
	start_signal.emit()
	
	_upper_body.start(animation_name)
	animation_tree.set(PATH_TRIGGER_SWING, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# Wait for animation to finish, then emit signal
	var clip_duration = _animation_player.get_animation(animation_name).length
	await get_tree().create_timer(clip_duration).timeout
	
	end_signal.emit()
