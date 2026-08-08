extends Node3D

@onready var target: FoxHurtArea3D = $Target
@onready var attacker: FoxHitArea3D = $Attacker
@onready var raygun: FoxHitRayCast3D = $Raygun
@onready var sweeper: FoxHitShapeCast3D = $Sweeper

func _ready() -> void:
	print("\n--- 🦊 STARTING FOXFABRIC PIPELINE TESTS ---\n")
	
	# Wire up the listening stations
	target.hit_received.connect(_on_target_received)
	attacker.hit_delivered.connect(_on_attacker_delivered)
	raygun.hit_delivered.connect(_on_raygun_delivered)
	sweeper.hit_delivered.connect(_on_sweeper_delivered)
	
	_run_test_1_area_overlap()


func _run_test_1_area_overlap() -> void:
	print("[TEST 1] Testing Area3D Overlap Pipeline...")
	attacker.payload = "Melee Slash (50 DMG)"
	attacker.global_position = target.global_position
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Move the attacker away so it doesn't block the raycast
	attacker.global_position = Vector3(5, 0, 0)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	_run_test_2_raycast_fire()


func _run_test_2_raycast_fire() -> void:
	print("\n[TEST 2] Testing RayCast3D Hitscan Pipeline...")
	raygun.payload = {
		"damage": 100,
		"is_critical": true,
		"element": "Plasma"
	}
	raygun.fire()
	
	_run_test_3_shapecast_sweep()


func _run_test_3_shapecast_sweep() -> void:
	print("\n[TEST 3] Testing ShapeCast3D Sweep Pipeline...")
	# Passing an Array this time to prove Variant flexibility
	sweeper.payload = ["Stun", 2.5, Vector3.UP]
	sweeper.fire()
	
	print("\n--- 🏁 TESTS COMPLETE ---\n")


#region Test Observers (Signal Callbacks)

func _on_target_received(payload: Variant) -> void:
	print("   🟢 TARGET RECEIVED payload: ", payload)

func _on_attacker_delivered(payload: Variant, hit_target: FoxHurtArea3D) -> void:
	print("   🟢 ATTACKER DELIVERED payload to: ", hit_target.name)

func _on_raygun_delivered(payload: Variant, hit_target: FoxHurtArea3D) -> void:
	print("   🟢 RAYGUN DELIVERED payload to: ", hit_target.name)

func _on_sweeper_delivered(payload: Variant, hit_target: FoxHurtArea3D) -> void:
	print("   🟢 SWEEPER DELIVERED payload to: ", hit_target.name)

#endregion
