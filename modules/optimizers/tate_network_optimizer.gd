extends TateComponent
class_name TateNetworkOptimizer
## Looks for a method called "set_network_role"
## in its target components.

## This script might be redundant.

@export var target_components: Array[Node] = []

## If true, it also notifies the parent node (the root of the scene).
@export var notify_root: bool = true

func _ready() -> void:
	# makes sure the MultiplayerAPI auth is fully assigned
	# this might not be needed and could actually cause some
	# bugs
	await get_tree().process_frame
	
	update_network_role()


func update_network_role():
	
	var is_server = is_multiplayer_authority()
	
	
	
	if notify_root:
		var parent = get_parent()
		
		assert(parent.has_method("set_network_role"),"ERROR: TateNetworkOptimizer\
		could not find method set_network_role on its parent "+str(parent.get_path()))
		
		if parent.has_method("set_network_role"):
			parent.set_network_role(is_server)
	
	
	
	for component in target_components:
		if not component:
			continue
		
		assert(component.has_method("set_network_role"),"ERROR: TateNetworkOptimizer\
		could not find method set_network_role on component "+str(component.get_path()))
		
		if component.has_method("set_network_role"):
			component.set_network_role(is_server)
