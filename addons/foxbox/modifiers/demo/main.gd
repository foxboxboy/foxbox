extends Node

@onready var gui = $GUI
@onready var knight : TateDemoKnight = $Knight # The UnitStatHandler node

@export var chase_upgrade: TateDemoModifierChaseUpgrade 
@export var wind_up_upgrade: TateDemoModifierWindUpUpgrade
@export var health_upgrade: TateDemoModifierHealthUpgrade

@export var lance_weapon: TateDemoModifierLanceWeapon
@export var sword_weapon: TateDemoModifierSwordWeapon

@export var fire_status_effect: TateDemoModifierFireStatusEffect
@export var poison_status_effect: TateModifier

func _ready() -> void:
	# UPDATE HEALTH
	var current_health : float = knight.health_component.current
	var max_health : float = knight.health_component.base
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


func _on_gui_health_button_pressed() -> void:
	knight.add_upgrade(health_upgrade)


func _on_gui_lance_button_pressed() -> void:
	knight.set_weapon(lance_weapon)


func _on_gui_poison_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_set_on_fire_button_pressed() -> void:
	knight.add_status_effect(fire_status_effect)


func _on_gui_sword_button_pressed() -> void:
	knight.set_weapon(sword_weapon)


func _on_gui_wind_up_button_pressed() -> void:
	knight.add_upgrade(wind_up_upgrade)


func _on_knight_damage_updated(current: float) -> void:
	gui.damage_label.text = str(snappedf(current,0.1))


func _on_knight_speed_updated(current: float) -> void:
	gui.speed_label.text = str(snappedf(current,0.1))


func _on_knight_health_updated(current: float, max_val: float) -> void:
	if gui == null or gui.health_label == null:
		return
	
	gui.health_label.text = str(snappedf(current,0.1)) + " / " + str(snappedf(max_val,0.1))
	
	var health_bar : ProgressBar = gui.health_bar
	
	health_bar.value = snappedf(current,0.1)
	health_bar.max_value = snappedf(max_val,0.1)


func _on_knight_upgrades_changed(upgrade_list: Array[TateModifierInstance]) -> void:
	gui.clear_upgrade_entries()
	
	for upgrade in upgrade_list:
		gui.add_upgrade_entry(upgrade.modifier_data.modifier_id)


func _process(_delta: float) -> void:
	pass#print(knight.health_component.max_stat.value)
