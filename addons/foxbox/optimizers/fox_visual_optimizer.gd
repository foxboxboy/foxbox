extends FoxNode
class_name FoxVisualOptimizer


@export_group("Settings")
## Distance at which optimizations kick in. 
@export var lod_distance: float = 15.0:
	set(new_value):
		lod_distance = new_value
		_lod_distance_sq = lod_distance * lod_distance
## Distance at which animations stop altogether.
@export var full_disable_distance: float = 25.0:
	set(new_value):
		full_disable_distance = new_value
		_full_disable_distance_sq = full_disable_distance * full_disable_distance
## How throttled the frame rate of animations will be.
@export var throttle_fps: int = 64

@export_group("Targets")
## The main visual root (Model). Will have process mode disabled when far.
@export var visual_root: Node3D
## Nodes to completely hide when far.
@export var nodes_to_hide: Array[Node3D] = []
## AnimationPlayers to throttle when far.
@export var anim_players: Array[AnimationPlayer] = []

# Internal state
var is_far: bool = false
var _camera: Camera3D
var _lod_distance_sq: float = 1.0
var _full_disable_distance_sq: float = 1.0


func _ready() -> void:
	full_disable_distance = full_disable_distance
	lod_distance = lod_distance


func _process(delta: float) -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
		if not _camera: return

	var dist_sq = get_parent().global_position.distance_squared_to(_camera.global_position)

	if dist_sq > _lod_distance_sq:
		if not is_far: 
			_go_to_sleep()
		
		if not dist_sq > _full_disable_distance_sq:
			_process_far_mode(delta)
	else:
		if is_far: _wake_up()


func _go_to_sleep():
	is_far = true

	if visual_root:
		visual_root.process_mode = Node.PROCESS_MODE_DISABLED
		#visual_root.visible = false # hide completely if very far

	for node in nodes_to_hide:
		if node: node.visible = false

	# make animations manual
	for anim in anim_players:
		anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


func _wake_up():
	is_far = false

	if visual_root:
		visual_root.process_mode = Node.PROCESS_MODE_INHERIT
		#visual_root.visible = true

	for node in nodes_to_hide:
		if node: node.visible = true

	for anim in anim_players:
		anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS


func _process_far_mode(delta: float):
	# "stutter" Update
	if anim_players.is_empty(): return

	# only update animations once every 'throttle_fps' frames
	# using instance_id ensures all 200 units don't update on the same frame
	if Engine.get_process_frames() % throttle_fps == get_instance_id() % throttle_fps:
		for anim in anim_players:
			anim.advance(delta * throttle_fps)
