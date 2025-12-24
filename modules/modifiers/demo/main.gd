extends Node

@onready var gui = $GUI
@onready var knight : TateDemoKnight = $Knight # The UnitStatHandler node

@export var chase_upgrade: TateDemoModifierChaseUpgrade 
@export var wind_up_upgrade: TateDemoModifierWindUpUpgrade

@export var lance_weapon: TateModifier
@export var sword_weapon: TateModifier

@export var fire_status_effect: TateModifier
@export var poison_status_effect: TateModifier

func _ready() -> void:
	# UPDATE HEALTH
	var current_health : float = knight.health_component.value
	var max_health : float = knight.health_component.max_value
	gui.health_label.text = str(current_health)
	_on_knight_health_updated(current_health, max_health)
	
	# UPDATE SPEED
	_on_knight_speed_updated(knight.speed_component.value)
	
	# UPDATE DAMAGE
	_on_knight_damage_updated(knight.damage_component.value)


func _on_gui_clear_all_modifiers_button_pressed() -> void:
	knight.clear_all_modifiers()


func _on_gui_chase_button_pressed() -> void:
	knight.add_upgrade(chase_upgrade)


func _on_gui_lance_button_pressed() -> void:
	knight.set_weapon(lance_weapon)


func _on_gui_poison_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_set_on_fire_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_sword_button_pressed() -> void:
	knight.set_weapon(sword_weapon)


func _on_gui_wind_up_button_pressed() -> void:
	knight.add_upgrade(wind_up_upgrade)


func _on_stats_component_speed_stat_value_changed(new_value: float) -> void:
	gui.speed_label.text = str(new_value)


func _on_knight_damage_updated(current: float) -> void:
	gui.damage_label.text = str(current)


func _on_knight_speed_updated(current: float) -> void:
	gui.speed_label.text = str(current)


func _on_knight_health_updated(current: float, max_val: float) -> void:
	gui.health_label.text = str(current)
	
	var health_bar : ProgressBar = gui.health_bar
	
	health_bar.value = current
	health_bar.max_value = max_val


func _on_knight_upgrades_changed(upgrade_list: Array[TateModifierNode]) -> void:
	gui.clear_upgrade_entries()
	
	for upgrade in upgrade_list:
		gui.add_upgrade_entry(upgrade.modifier_data.modifier_id)


func _process(delta: float) -> void:
	pass#print(knight.weapon_slot_policy.slots)
