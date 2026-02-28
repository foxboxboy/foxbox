extends Node
## The root controller for the Modifier Demo scene.

@export var chase_upgrade: FoxDemoModifierChaseUpgrade 
@export var wind_up_upgrade: FoxDemoModifierWindUpUpgrade
@export var health_upgrade: FoxDemoModifierHealthUpgrade

@export var lance_weapon: FoxDemoModifierLanceWeapon
@export var sword_weapon: FoxDemoModifierSwordWeapon

@export var fire_status_effect: FoxDemoModifierFireStatusEffect

@onready var gui = $GUI
@onready var knight: FoxDemoKnight = $Knight 

func _ready() -> void:
	# 1. Wire GUI buttons to the Knight's API
	gui.chase_button_pressed.connect(func(): knight.add_upgrade(chase_upgrade))
	gui.wind_up_button_pressed.connect(func(): knight.add_upgrade(wind_up_upgrade))
	gui.health_button_pressed.connect(func(): knight.add_upgrade(health_upgrade))
	
	gui.lance_button_pressed.connect(func(): knight.set_weapon(lance_weapon))
	gui.sword_button_pressed.connect(func(): knight.set_weapon(sword_weapon))
	
	gui.set_on_fire_button_pressed.connect(func(): knight.add_status_effect(fire_status_effect))
	gui.clear_all_modifiers_button_pressed.connect(func(): knight.clear_all_modifiers())
	
	# 2. Wire Knight's stat signals to the GUI display
	knight.health_updated.connect(gui.update_health_display)
	knight.damage_updated.connect(gui.update_damage_display)
	knight.speed_updated.connect(gui.update_speed_display)
	knight.upgrades_changed.connect(gui.update_upgrade_list)

	# Force an initial UI update
	knight._on_damage_component_value_changed(knight.damage_component.value)
	knight._on_speed_component_value_changed(knight.speed_component.value)
	knight._on_health_component_updated(knight.health_component.current, knight.health_component.max_value)
