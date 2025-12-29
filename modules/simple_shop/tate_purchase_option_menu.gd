#tate_lib/modules/simple_shop/tate_purchase_option_menu.gd
extends TateComponentUI
class_name TatePurchaseOptionMenu
## Manages a list of purchase option slots as children in a container.

@export var slot_scene: PackedScene
@export var container: Control

## Emitted when a slot is pressed.
signal slot_pressed(option : TatePurchaseOption)


var current_funds := 0:
	set(value):
		current_funds = value
		update_affordability()


func _ready() -> void:
	update_affordability()


## Updates the TatePurchaseOptionSlot's based on
## current_funds. For example, if all the sudden
## a player drops to $2 and an option is $3 it will
## make itself obvious it can't be bought.
func update_affordability(_current_funds: int = current_funds) -> void:
	for slot in container.get_children():
		if slot is TatePurchaseOptionSlot:
			var can_buy = TateShopService.can_purchase(slot.data, _current_funds)
			slot.set_affordability(can_buy)


## Wipes the current UI.
func clear_all_options() -> void:
	for child in container.get_children():
		child.queue_free()


## Adds a single purchase option with an optional explicit cost.
func add_option(option: TatePurchaseOption, override_cost: float = NAN) -> void:
	var slot = slot_scene.instantiate() as TatePurchaseOptionSlot
	container.add_child(slot)
	
	if is_nan(override_cost):
		slot.setup(option)
	else:
		slot.setup(option, override_cost)
	
	slot.pressed.connect(_on_slot_pressed)
	
	update_affordability()



## Populates the menu with cards from a catalog.
func populate(catalog: TatePurchaseCatalog, override_costs: Array = []) -> void:
	clear_all_options()
	
	var index := 0
	for option in catalog.array:
		var slot = slot_scene.instantiate() as TatePurchaseOptionSlot
		container.add_child(slot)
		
		if override_costs.is_empty():
			slot.setup(option)
		else:
			slot.setup(option, override_costs[index])
		
		slot.pressed.connect(_on_slot_pressed)
		
		index += 1


func _on_slot_pressed(option: TatePurchaseOption) -> void:
	slot_pressed.emit(option)
