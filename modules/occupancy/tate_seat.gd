# tates_lib/modules/occupancy/tate_seat.gd
extends TateComponent
class_name TateSeat
## Provides a way of reparenting a single node and update its
## transform. Literally just a seat.

## Emitted when this Seat gains a new occupant.
signal occupant_sat(occupant : Node, seat : TateSeat)
signal occupant_left(occupant : Node, seat : TateSeat)
signal occupant_changed(occupant : Node, seat : TateSeat)

## (Optional) The node that will be used for position
## and rotation. Leave blank to make this the marker. 
@export var marker : Node
## The name of this seat
# OH MY GOD I CAN JUST RENAME THE SEAT NODE
#@export var role_name: StringName

## The child occupant currently sittng in this seat..
var occupant: Node = null


func _ready() -> void:
	child_order_changed.connect(_occupant_changed)
	
	if marker == null:
		marker = self
		
	if marker.get("global_position") == null:
		printerr("ERROR: TateSeat.marker doesn't have a global_position. ",get_path())
	if marker.get("global_rotation") == null:
		printerr("ERROR: TateSeat.marker doesn't have a global_rotation. ",get_path())


## Returns true if there is an occupant. 
## Returns false if there is no occupant.
func has_occupant() -> bool:
	return occupant != null


## Returns the current occupant.
func get_occupant() -> Node:
	return occupant


## Reparents a node to become this seats occupant.
func sit(new_occupant: Node) -> void:
	if occupant != null:
		printerr("ERROR: TateSeat already has an occupant but \
		another is trying to be assigned! "\
		,new_occupant," ",get_path())
	
	occupant = new_occupant
	new_occupant.reparent(self)
	occupant_sat.emit(new_occupant, self)
	
	if new_occupant is Node2D or new_occupant is Node3D:
		new_occupant.global_position = marker.global_position
		new_occupant.global_rotation = marker.global_rotation
	
	if new_occupant is Node2D or new_occupant is Node3D:
		new_occupant.global_position = marker.global_position
		new_occupant.global_rotation = marker.global_rotation


func _occupant_changed():
	occupant_changed.emit(occupant, self)
	
	if not is_instance_valid(occupant) or occupant.get_parent() != self:
		if is_instance_valid(occupant):
			occupant_left.emit(occupant, self)
		occupant = null
