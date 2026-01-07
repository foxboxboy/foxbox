extends TateNode3D
class_name TatePhysicsEntity3D

enum MaterialType { WOOD, METAL, FLESH, PLASTIC, HOLLOW_METAL }

@export var rigid_body : RigidBody3D
@export var material_type: MaterialType = MaterialType.WOOD
@export var impact_sound_stream_player : AudioStreamPlayer3D

func _ready():
	# this is so we know when we hit stuff
	rigid_body.contact_monitor = true
	rigid_body.max_contacts_reported = 1
	
	rigid_body.body_entered.connect(_on_body_entered)


func _physics_process(delta):
	# Store the velocity at the end of the frame so we have it 
	# when the collision happens on the NEXT frame.
	_last_velocity = rigid_body.linear_velocity



# Settings
@export var min_impact_force: float = 2.0 # Minimum speed to trigger sound
@export var vertical_impact_threshold: float = 5.0 # Higher threshold for landing (falling)
var _last_velocity: Vector3 = Vector3.ZERO

func _on_body_entered(body):
	
	# Calculate how hard we hit
	var impact_vector = _last_velocity
	var force = impact_vector.length()
	
	print(force)

	# 1. HARD CUTOFF: Ignore tiny nudges (like sliding or slow walking)
	if force < min_impact_force:
		return

	# 2. FLOOR FILTER: Differentiate "Walking" from "Falling"
	# If the impact is mostly vertical (falling), use a higher threshold.
	var is_vertical_impact = abs(impact_vector.y) > abs(impact_vector.x) + abs(impact_vector.z)

	if is_vertical_impact:
		# We hit the floor (or ceiling). Only play if it was a hard fall.
		# This filters out normal walking/jumping bobbing.
		if abs(impact_vector.y) < vertical_impact_threshold:
			return
		# Optional: Play a specific "Land" sound here?
		
	# 3. PLAY SOUND
	# Use 'force' to modulate volume (harder hit = louder)
	play_impact_sound(force)


#func _on_body_entered(body):
#	print(body)
#	
#	play_impact_sound()


func play_impact_sound(force : float):
	if impact_sound_stream_player:
		impact_sound_stream_player.play()


func use(user: Node):
	rigid_body.apply_central_impulse(Vector3.UP * 2.0)
	
	print("User: ",user)


func knockback(amount: float, hit_pos: Vector3, impulse_dir: Vector3):
	rigid_body.apply_impulse(impulse_dir * amount, hit_pos - rigid_body.global_position)
	
	play_impact_sound(amount)
