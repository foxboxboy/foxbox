extends Control

@export var upgrade_entry: PackedScene
@onready var upgrade_list: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/UpgradeList

@onready var damage_label: Label = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/DamageLabel
@onready var health_label: Label = $VBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/HealthLabel
@onready var speed_label: Label = $VBoxContainer/PanelContainer3/MarginContainer/HBoxContainer/SpeedLabel
@onready var health_bar: ProgressBar = $HealthBar

signal wind_up_button_pressed
signal chase_button_pressed
signal health_button_pressed
signal lance_button_pressed
signal sword_button_pressed
signal set_on_fire_button_pressed
signal poison_button_pressed
signal clear_all_modifiers_button_pressed


# --- Button Callbacks (Connect your UI buttons to these!) ---

func _on_wind_up_button_pressed() -> void:
	wind_up_button_pressed.emit()

func _on_chase_button_pressed() -> void:
	chase_button_pressed.emit()

func _on_health_button_pressed() -> void:
	health_button_pressed.emit()

func _on_lance_button_pressed() -> void:
	lance_button_pressed.emit()

func _on_sword_button_pressed() -> void:
	sword_button_pressed.emit()

func _on_set_on_fire_button_pressed() -> void:
	set_on_fire_button_pressed.emit()

func _on_poison_button_pressed() -> void:
	poison_button_pressed.emit()

func _on_clear_all_modifiers_button_pressed() -> void:
	clear_all_modifiers_button_pressed.emit()
	for child in upgrade_list.get_children():
		child.queue_free()


# --- Display Updates ---

func update_health_display(current: float, max_val: float) -> void:
	if health_label:
		health_label.text = str(snappedf(current, 0.1)) + " / " + str(snappedf(max_val, 0.1))
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func update_damage_display(current: float) -> void:
	if damage_label:
		damage_label.text = str(snappedf(current, 0.1))

func update_speed_display(current: float) -> void:
	print(current)
	
	if speed_label:
		speed_label.text = str(snappedf(current, 0.1))

func update_upgrade_list(slots: Array[FoxModifierInstance]) -> void:
	# Clear the old UI list
	for child in upgrade_list.get_children():
		child.queue_free()
		
	# Rebuild it, showing the active stacks!
	for instance in slots:
		if upgrade_entry:
			var new_entry = upgrade_entry.instantiate()
			upgrade_list.add_child(new_entry)
			# Assuming your UI entry has a label named 'name_label'
			new_entry.name_label.text = str(instance.modifier_id) + " (x" + str(instance.stack) + ")"
