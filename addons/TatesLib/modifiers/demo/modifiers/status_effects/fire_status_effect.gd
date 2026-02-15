extends TateModifier
class_name TateDemoModifierFireStatusEffect

@export var damage_per_tick: float = 5.0
@export var tick_interval: float = 1.0

@export var flame_scene : PackedScene

var timer : Timer

func _on_execute(target: Node) -> void:
	timer = Timer.new()
	timer.name = "BurnTimer"
	timer.wait_time = tick_interval
	timer.autostart = true
	
	timer.timeout.connect(func(): _apply_burn_damage(target))
	
	if flame_scene:
		var new_flame = flame_scene.instantiate()
		target.get_node("Visuals").add_child(new_flame)
	
	target.get_node("Logic/ModifierManager").add_child(timer)


func _apply_burn_damage(target: Node) -> void:
	
	var health_component : TateModifiableBoundedNode
	
	if target is TateDemoKnight:
		health_component = target.health_component

	
	if health_component:
		health_component.subtract(damage_per_tick)


func _on_remove(target : Node) -> void:
	var flame = target.get_node_or_null("Visuals/Flame")
	if flame:
		flame.queue_free()
	if timer:
		timer.queue_free()
