extends Node

@onready var gui = $GUI
@onready var knight_stats = $Knight/StatsComponent # The UnitStatHandler node

# You can drag and drop your .tres effect files here in the inspector
@export var chase_upgrade_effect: TateEffect 
@export var fire_damage_effect: TateEffect

func _ready() -> void:
	# 1. Connect GUI button signals to our logic
	#gui.speed_button_pressed.connect(_on_speed_request)
	#gui.fire_button_pressed.connect(_on_fire_request)
	
	# 2. Bridge the Knight's health to the GUI
	pass
	#knight_stats.health_resource.value_changed.connect(gui.update_health_bar)


func _on_gui_clear_all_effects_button_pressed() -> void:
	knight_stats.clear_all_effects()


func _on_gui_chase_button_pressed() -> void:
	knight_stats.apply_effect(chase_upgrade_effect)


func _on_gui_lance_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_poison_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_set_on_fire_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_sword_button_pressed() -> void:
	pass # Replace with function body.


func _on_gui_wind_up_button_pressed() -> void:
	pass # Replace with function body.


func _on_stats_component_speed_stat_value_changed(new_value: float) -> void:
	gui.speed_label.text = str(new_value)
