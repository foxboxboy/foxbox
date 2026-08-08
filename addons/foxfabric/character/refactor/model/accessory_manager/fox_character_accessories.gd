extends FoxNode3D
class_name FoxCharacterAccessories
## Manages dynamically equipping rigid and skinned cosmetic items.

## Rigid accessories are directly "popped" onto the bones via BoneAttachment3D.
## Skinned accessories deform and shape themselves according to the skeleton assigned.
## [br]
## The skeleton is meant to be the same as the character and the skinned accessories
## should have the same skeleton as the character.

## Emitted when a rigid accessory is equipped.
signal rigid_equipped(accessory: Node3D, bone_name: String)
## Emitted when a skinned accessory is added.
signal skinned_equipped(accessory: Node3D, slot_name: String)

## Emitted when a rigid accessory is removed.
signal rigid_removed(accessory: Node3D, slot_name: String)
## Emitted when a skinned accessory is removed.
signal skinned_removed(accessory: Node3D, slot_name: String)



## The skeleton that the rigid accessories will attach to and the 
## skinned accessories will deform to.
@export var skeleton: Skeleton3D

## Tracks all instances of skinned accessories.
var _skinned_slots: Dictionary = {}

## Tracks all instances of rigid accessories.
var _rigid_accessories: Array = []


func _ready() -> void:
	if get_node(".") is Skeleton3D:
		skeleton = get_node(".")
	
	assert(skeleton != null, "ERROR: FoxCharacterAccessories needs a Skeleton3D assigned!")



#region Rigid Accessories

## Attaches a rigid item to any bone by its string name.
func equip_rigid_accessory(accessory: Node3D, bone_name: String, reset_transform := true) -> void:
	var bone_idx = skeleton.find_bone(bone_name)
	if bone_idx == -1:
		push_error("ERROR: Bone '" + bone_name + "' does not exist on skeleton!")
		return

	var attachment: BoneAttachment3D = null
	for child in skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			attachment = child
			break

	if not attachment:
		attachment = BoneAttachment3D.new()
		attachment.bone_name = bone_name
		skeleton.add_child(attachment)

	empty_rigid_accessory_slot(bone_name)

	attachment.add_child(accessory)
	
	_rigid_accessories.append(accessory)
	
	if reset_transform:
		accessory.position = Vector3.ZERO
		accessory.rotation = Vector3.ZERO
	
	rigid_equipped.emit(accessory, bone_name)


## Returns true if a rigid accessory could be found under a bone.
func has_rigid_accessory_in_slot(bone_name: String) -> bool:
	return get_rigid_accessories_in_slot(bone_name).size() != 0


## Returns all rigid accessories assigned to a bone.
func get_rigid_accessories_in_slot(bone_name: String) -> Array:
	var accessory_array = []
	
	for child in skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			for item in child.get_children():
				if _rigid_accessories.has(item):
					accessory_array.append(item)
	
	return accessory_array


## Removes all rigid accessories assigned to a bone. 
func empty_rigid_accessory_slot(bone_name: String) -> void:
	for child in skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name == bone_name:
			for item in child.get_children():
				if _rigid_accessories.has(item):
					item.queue_free()

					_rigid_accessories.erase(item)
					
					rigid_removed.emit(item, bone_name)


## Clears all rigid accessories from their slots.
## This effectively wipes the character back to having no rigid accessories. 
func clear_all_rigid_accessories() -> void:
	for child in skeleton.get_children():
		if child is BoneAttachment3D:
			empty_rigid_accessory_slot(child.bone_name)
	
	_rigid_accessories.clear()

#endregion







#region Skinned Accessories

## Equips a raw .gltf scene wrapper and automatically re-routes its internal meshes
## to use the skeleton assigned to this FoxCharacterAccessories,
## [br]
## Keeps track of the skinned accessory by the slot_name provided so that it can
## be found or removed later.
func equip_skinned_accessory(accessory_root: Node3D, slot_name: String) -> void:
	empty_skinned_accessory_slot(slot_name)
	
	add_child(accessory_root)
	accessory_root.position = Vector3.ZERO
	accessory_root.rotation = Vector3.ZERO
	
	_skinned_slots[slot_name] = accessory_root
	
	var meshes = accessory_root.find_children("*", "MeshInstance3D", true, false)
	
	if meshes.is_empty():
		push_warning("WARNING: No MeshInstance3D found inside skinned accessory: " + str(accessory_root.name))
		return
		
	for mesh in meshes:
		mesh.skeleton = mesh.get_path_to(skeleton)
	
	skinned_equipped.emit(accessory_root, slot_name)


## Returns true if we have a value for that skinned slot.
func has_skinned_accessory_slot(slot_name: String) -> bool:
	return _skinned_slots.has(slot_name)


## Returns dictionary showing all skinned slots. Each key is the name of
## the slot and the value is the Node its assigned to.
func get_skinned_accessory_slots() -> Dictionary:
	return _skinned_slots


## Removes a skinned accessory by its slot name.
func empty_skinned_accessory_slot(slot_name: String) -> void:
	if _skinned_slots.has(slot_name):
		var accessory = _skinned_slots[slot_name]
		
		if is_instance_valid(accessory):
			accessory.queue_free() 
			
		_skinned_slots.erase(slot_name)
		
		skinned_removed.emit(accessory, slot_name)


## Clears all skinned accessories from their slots.
## This effectively wipes the character back to having no skinned accessories. 
func clear_all_skinned_accessories() -> void:
	var current_slots = _skinned_slots.keys()
		
	for slot_name in current_slots:
		empty_skinned_accessory_slot(slot_name)


#endregion





#region Both

## Clears all accessories from their slots.
## This effectively wipes the character back to having no accessories. 
func clear_all_accessories() -> void:
	clear_all_rigid_accessories()
	clear_all_skinned_accessories()

#endregion
