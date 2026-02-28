class_name FoxDemoKnight
extends FoxNode

#region Signals

signal health_updated(current: float, max_val: float)
signal damage_updated(current: float)
signal speed_updated(current: float)
signal upgrades_changed(upgrade_list: Array[FoxModifierInstance])

#endregion


#region Variables

@export_group("Components")
@export var sprite_2d: Sprite2D
@export var weapon_socket: Marker2D

@export_group("Modifier System")
@export var modifier_manager: FoxModifierManager
@export var weapon_slot_policy: FoxModifierSlotPolicy
@export var upgrade_slot_policy: FoxModifierSlotPolicy

# Assuming you have these from your separate math module
@export var health_component: FoxStatPool
@export var damage_component := FoxModifiableStat.new(4.0)
@export var speed_component := FoxModifiableStat.new(2.0)

#endregion


#region Private Logic

func _ready() -> void:        
	# Listen to your math components for changes
	if damage_component:
		damage_component.value_changed.connect(_on_damage_component_value_changed)
	if speed_component:
		speed_component.value_changed.connect(_on_speed_component_value_changed)
	if health_component:
		health_component.updated.connect(_on_health_component_updated)
		
	# Listen to the slot policy to update the UI when upgrades change!
	if upgrade_slot_policy:
		upgrade_slot_policy.slots_updated.connect(_on_upgrade_slot_policy_slots_updated)


func _process(_delta: float) -> void:
	if sprite_2d:
		# Just a little breathing animation
		sprite_2d.scale.x = 1.0 + (sin(Time.get_ticks_msec() / 1000.0) * 0.1)


# --- Signal Callbacks ---

func _on_health_component_updated(current: float, max_val: float) -> void:
	health_updated.emit(current, max_val)

func _on_damage_component_value_changed(current: float) -> void:
	damage_updated.emit(current)

func _on_speed_component_value_changed(current: float) -> void:
	speed_updated.emit(current)

func _on_upgrade_slot_policy_slots_updated(current_slots: Array[FoxModifierInstance]) -> void:
	upgrades_changed.emit(current_slots)

#endregion


#region Public API

func clear_all_modifiers() -> void:
	modifier_manager.remove_all_modifiers()

func add_upgrade(upgrade: FoxModifier) -> void:
	upgrade_slot_policy.try_add(upgrade, self)

func set_weapon(weapon: FoxModifier) -> void:
	weapon_slot_policy.try_add(weapon, self)

func add_status_effect(status_effect: FoxModifier) -> void:
	# Status effects bypass slot policies and go straight to the sandbox!
	modifier_manager.add_modifier(status_effect, self)

#endregion
