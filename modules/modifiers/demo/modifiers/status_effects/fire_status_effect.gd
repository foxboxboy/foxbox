extends TateModifier
class_name TateDemoModifierFireStatusEffect
# project/modifiers/burn_modifier.gd

@export var damage_per_tick: float = 5.0
@export var tick_interval: float = 1.0

# This modifier will be STACKING or UNIQUE depending on your game rules.
# For fire, usually UNIQUE (refresh duration) or ADDITIVE (more damage).

func _on_execute(target: Node) -> void:
	# We create a local timer node to handle the ticking logic
	# and child it to the TateModifierNode itself.
	var timer = Timer.new()
	timer.name = "BurnTimer"
	timer.wait_time = tick_interval
	timer.autostart = true
	
	# Connect the timer to a function that damages the target
	timer.timeout.connect(func(): _apply_burn_damage(target))
	
	# The 'target' in _on_execute is the Unit. 
	# But where do we put the timer? 
	# Best place is to find the active TateModifierNode that called this.
	target.get_node("Logic/ModifierManager/" + modifier_id).add_child(timer)

func _apply_burn_damage(target: Node) -> void:
	# Find the health node using your standardized address
	var health = target.get_node_or_null("Logic/HullHealth")
	if health:
		health.subtract(damage_per_tick)
