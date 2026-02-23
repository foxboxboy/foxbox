extends Node


@onready var guy: Sprite2D = $Guy
@onready var guy_2: Sprite2D = $Guy2
@onready var occupancy_component: FoxSeatManager2D = $OccupancyComponent

@onready var guy_marker: Marker2D = $GuyMarker
@onready var guy_2_marker: Marker2D = $Guy2Marker


func _on_sit_button_pressed() -> void:
	if guy.get_parent() == self:
		occupancy_component.try_sit(guy)
	else:
		guy.reparent(self)
		guy.global_position = guy_marker.global_position


func _on_sit_button_2_pressed() -> void:
	if guy_2.get_parent() == self:
		occupancy_component.try_sit(guy_2)
	else:
		guy_2.reparent(self)
		guy_2.global_position = guy_2_marker.global_position
