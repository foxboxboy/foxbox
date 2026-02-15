extends FoxNode
class_name FoxDemoKnight

signal health_updated(current: float, max_val: float)
signal damage_updated(current: float)
signal speed_updated(current: float)
signal upgrades_changed(upgrade_list : Array[FoxModifierInstance])

@export var sprite_2d: Sprite2D
@export var weapon_socket : Marker2D

@export var modifier_manager : FoxModifierManager
@export var weapon_slot_policy: FoxModifierSlotPolicy
@export var upgrade_slot_policy: FoxModifierSlotPolicy

@export var health_component : FoxModifiableBoundedNode

@export var damage_component := FoxModifiableStat.new(4.0)
@export var speed_component := FoxModifiableStat.new(2.0)

func _ready() -> void:		
	damage_component.value_changed.connect(_on_damage_component_value_changed)
	speed_component.value_changed.connect(_on_speed_component_value_changed)
	
	pass


func clear_all_modifiers():
	modifier_manager.remove_all_modifiers()


func add_upgrade(upgrade : FoxModifier):
	upgrade_slot_policy.try_add(upgrade, self)


func set_weapon(weapon : FoxModifier):
	weapon_slot_policy.try_add(weapon, self)


func add_status_effect(status_effect : FoxModifier):
	modifier_manager.add_modifier(status_effect, self)


func _process(_delta: float) -> void:
	sprite_2d.scale.x = sin(Time.get_ticks_msec() / 1000.0) / 2.0


func _on_health_component_updated(current: float, max_val: float) -> void:
	health_updated.emit(current, max_val)


func _on_damage_component_value_changed(current: float) -> void:
	damage_updated.emit(current)


func _on_speed_component_value_changed(current: float) -> void:
	speed_updated.emit(current)


func _on_upgrade_slot_policy_slots_updated(current_slots: Array[FoxModifierInstance]) -> void:
	upgrades_changed.emit(current_slots)
