# demo/traits/demo/gui.gd
extends Control

@onready var damage_label: Label = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/DamageLabel
@onready var health_label: Label = $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/HealthLabel
@onready var speed_label: Label = $VBoxContainer/PanelContainer3/MarginContainer/HBoxContainer/SpeedLabel

signal wind_up_button_pressed
signal chase_button_pressed
signal lance_button_pressed
signal sword_button_pressed
signal set_on_fire_button_pressed
signal poison_button_pressed
signal clear_all_effects_button_pressed

@export var health_bar : ProgressBar

func update_health_bar(current: float, max_val: float, _min_val: float):
	health_bar.max_value = max_val
	health_bar.value = current


func _on_wind_up_button_pressed() -> void:
	wind_up_button_pressed.emit()


func _on_chase_button_pressed() -> void:
	chase_button_pressed.emit()


func _on_lance_button_pressed() -> void:
	lance_button_pressed.emit()


func _on_sword_button_pressed() -> void:
	sword_button_pressed.emit()


func _on_set_on_fire_button_pressed() -> void:
	set_on_fire_button_pressed.emit()


func _on_poison_button_pressed() -> void:
	poison_button_pressed.emit()


func _on_clear_all_effects_button_pressed() -> void:
	clear_all_effects_button_pressed.emit()
