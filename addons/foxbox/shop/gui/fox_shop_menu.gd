class_name FoxShopMenu
extends FoxControl
## Generates and manages a visual grid of [FoxShopSlot] nodes.


#region Signals

## Emitted when a successful transaction is completed.
signal item_purchased(item: FoxShopItem)

## Emitted when a purchase attempt fails (e.g., insufficient funds).
signal purchase_denied(item: FoxShopItem, reason: StringName)

## Emitted when the user hovers or selects an item in the menu.
signal item_focused(item: FoxShopItem)

## Emitted when the user stops hovering or deselects an item.
signal item_unfocused(item: FoxShopItem)

## Emitted after [method populate] has finished adding all slots to the container.
signal catalog_populated

#endregion


#region Variables

## The [PackedScene] containing a [FoxShopSlot] to instantiate.
@export var slot_scene: PackedScene

## The UI container (e.g., HBoxContainer) that holds the instantiated slots.
@export var container: Control

var _current_wallet: FoxWallet = null

#endregion





#region Public API

## Clears the current UI and populates it from a [FoxShopCatalog].
func populate(catalog: FoxShopCatalog, wallet: FoxWallet = null) -> void:
	_current_wallet = wallet
	_clear_all_options()
	
	for item in catalog.options:
		add_item(item)
	
	update_affordability()
	catalog_populated.emit()


## Instantiates and adds a single [FoxShopSlot] to the menu.
func add_item(item: FoxShopItem) -> void:
	var slot = slot_scene.instantiate() as FoxShopSlot
	container.add_child(slot)
	
	slot.setup(item)
	
	# Connect to the slot's explicit buy button signals
	slot.buy_button_pressed.connect(_on_slot_pressed)
	slot.buy_button_focused.connect(func(i): item_focused.emit(i))
	slot.buy_button_unfocused.connect(func(i): item_unfocused.emit(i))
	
	# Initial affordability check
	if _current_wallet:
		var can_buy = item.price.can_be_paid_by(_current_wallet) if item.price else true
		slot.set_affordability(can_buy)


## Updates the visual affordability state of all child slots based on the current wallet.
func update_affordability(wallet: FoxWallet = _current_wallet) -> void:
	_current_wallet = wallet
	
	for slot in container.get_children():
		if slot is FoxShopSlot and slot.data:
			var can_buy = true
			if slot.data.price and _current_wallet:
				can_buy = slot.data.price.can_be_paid_by(_current_wallet)
				
			slot.set_affordability(can_buy)

#endregion


#region Private Logic

func _clear_all_options() -> void:
	for child in container.get_children():
		child.queue_free()


func _on_slot_pressed(item: FoxShopItem) -> void:
	# If there's no price, we treat it as a free "claimable" item
	if not item.price:
		item_purchased.emit(item)
		return
		
	# Check if we have a wallet to pay with
	if not _current_wallet:
		push_warning("FoxShopMenu: Attempted purchase without a wallet.")
		return
		
	# Execute transaction
	if item.price.can_be_paid_by(_current_wallet):
		item.price.pay(_current_wallet)
		item_purchased.emit(item)
		update_affordability()
	else:
		purchase_denied.emit(item, &"insufficient_funds")

#endregion
