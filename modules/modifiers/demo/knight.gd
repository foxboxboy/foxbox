extends Node

@onready var stats_component : Node = $StatsComponent
@onready var health_component : Node = $HealthComponent

func _ready() -> void:
	print(stats_component.active_effects)
	print(health_component.current_health)
