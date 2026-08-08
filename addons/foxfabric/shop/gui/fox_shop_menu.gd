@icon("uid://cyjgtwr8kquwp")
class_name FoxShopMenu
extends FoxControl
## A UI controller that populates and manages a list of shop items.
##
## Handles the instantiation of UI slots and routes purchase requests.

## The [PackedScene] to instantiate for each item.
@export var slot_scene: PackedScene

## The parent [Control] node where instantiated slots are added.
@export var container: Control

## The active wallet used to evaluate affordability.
var _current_wallet: FoxWallet = null


#region Signals

## Emitted when an item is successfully purchased.
signal item_purchased(item: FoxShopItem)

## Emitted when a purchase is attempted but fails.
## [br][br]
## [param reason] is [code]&"no_wallet"[/code] when no wallet is assigned, or
## [code]&"payment_refused"[/code] when the item's [FoxPrice] declined. The price decides why,
## and it does not have to be affordability, so do not present this to the player as
## "not enough money" without checking what your own [FoxPrice] meant by it.
signal purchase_denied(item: FoxShopItem, reason: StringName)

## Emitted when a specific item's slot gains UI focus.
signal item_focused(item: FoxShopItem)

## Emitted when a specific item's slot loses UI focus.
signal item_unfocused(item: FoxShopItem)

## Emitted after the menu finishes instantiating the new catalog.
signal catalog_populated

#endregion


#region Public API

## Clears the container and populates it with items from the given [param catalog].
func populate(catalog: FoxShopCatalog, wallet: FoxWallet = null) -> void:
	_current_wallet = wallet
	_clear_all_options()
	
	for item in catalog.options:
		add_item(item)
	
	update_affordability()
	catalog_populated.emit()


## Instantiates a new slot for the given [param item] and connects its signals.
func add_item(item: FoxShopItem) -> void:
	var slot = slot_scene.instantiate() as FoxShopSlot
	container.add_child(slot)
	
	slot.setup(item)
	
	slot.buy_button_pressed.connect(_on_slot_pressed)
	slot.buy_button_focused.connect(item_focused.emit)
	slot.buy_button_unfocused.connect(item_unfocused.emit)
	
	if _current_wallet:
		var can_buy = item.price.can_be_paid_by(_current_wallet) if item.price else true
		slot.set_affordability(can_buy)


## Forces all child slots to recalculate affordability.
func update_affordability(wallet: FoxWallet = _current_wallet) -> void:
	_current_wallet = wallet
	
	for slot in container.get_children():
		if slot is FoxShopSlot and slot.data:
			var can_buy = true
			if slot.data.price and _current_wallet:
				can_buy = slot.data.price.can_be_paid_by(_current_wallet)
				
			slot.set_affordability(can_buy)

#endregion


#region Private

func _clear_all_options() -> void:
	for child in container.get_children():
		child.queue_free()


func _on_slot_pressed(item: FoxShopItem) -> void:
	if not item.price:
		item_purchased.emit(item)
		return
		
	if not _current_wallet:
		push_warning("FoxShopMenu: Attempted purchase without a wallet.")
		purchase_denied.emit(item, &"no_wallet")
		return
		
	if item.price.pay(_current_wallet):
		item_purchased.emit(item)
		update_affordability()
	else:
		purchase_denied.emit(item, &"payment_refused")

#endregion
