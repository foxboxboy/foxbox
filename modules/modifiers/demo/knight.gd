extends TateComponent
class_name TateDemoKnight

signal health_updated(current: float, max_val: float)
signal damage_updated(current: float)
signal speed_updated(current: float)
signal upgrades_changed(upgrade_list : Array[TateModifierInstance])

@export var sprite_2d: Sprite2D
@export var weapon_socket : Marker2D

@export var modifier_manager : TateModifierManager
@export var weapon_slot_policy: TateModifierSlotPolicy
@export var upgrade_slot_policy: TateModifierSlotPolicy

@export var health_component : TateModifiableBoundedNode

@export var damage_component := TateModifiableStat.new(4.0)
@export var speed_component := TateModifiableStat.new(2.0)

func _ready() -> void:		
	damage_component.value_changed.connect(_on_damage_component_value_changed)
	speed_component.value_changed.connect(_on_speed_component_value_changed)
	
	pass


func clear_all_modifiers():
	modifier_manager.remove_all_modifiers()


func add_upgrade(upgrade : TateModifier):
	upgrade_slot_policy.try_add(upgrade, self)


func set_weapon(weapon : TateModifier):
	weapon_slot_policy.try_add(weapon, self)


func add_status_effect(status_effect : TateModifier):
	modifier_manager.add_modifier(status_effect, self)


func _process(_delta: float) -> void:
	sprite_2d.scale.x = sin(Time.get_ticks_msec() / 1000.0) / 2.0


func _on_health_component_updated(current: float, max_val: float) -> void:
	health_updated.emit(current, max_val)


func _on_damage_component_value_changed(current: float) -> void:
	damage_updated.emit(current)


func _on_speed_component_value_changed(current: float) -> void:
	speed_updated.emit(current)


func _on_upgrade_slot_policy_slots_updated(current_slots: Array[TateModifierInstance]) -> void:
	upgrades_changed.emit(current_slots)
