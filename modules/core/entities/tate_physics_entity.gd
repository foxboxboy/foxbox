extends TateComponent3D
class_name TatePhysicsEntity3D

enum MaterialType { WOOD, METAL, FLESH, PLASTIC, HOLLOW_METAL }

@export var rigid_body : RigidBody3D
@export var material_type: MaterialType = MaterialType.WOOD
@export var impact_sound_stream_player : AudioStreamPlayer

func _ready():
	# this is so we know when we hit stuff
	rigid_body.contact_monitor = true
	rigid_body.max_contacts_reported = 1
	
	rigid_body.body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	print(body)
	
	play_impact_sound()


func play_impact_sound():
	if impact_sound_stream_player:
		impact_sound_stream_player.play()


func use(user: Node):
	rigid_body.apply_central_impulse(Vector3.UP * 2.0)
	
	print("User: ",user)


func knockback(amount: float, hit_pos: Vector3, impulse_dir: Vector3):
	rigid_body.apply_impulse(impulse_dir * amount, hit_pos - rigid_body.global_position)
	
	play_impact_sound()
