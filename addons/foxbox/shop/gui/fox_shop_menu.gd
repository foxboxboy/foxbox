class_name FoxShopMenu
extends FoxControl

@export var slot_scene: PackedScene
@export var container: Control

var _current_wallet: FoxWallet = null

signal item_purchased(item: FoxShopItem)
signal purchase_denied(item: FoxShopItem, reason: StringName)
signal item_focused(item: FoxShopItem)
signal item_unfocused(item: FoxShopItem)
signal catalog_populated

func populate(catalog: FoxShopCatalog, wallet: FoxWallet = null) -> void:
	_current_wallet = wallet
	_clear_all_options()
	
	for item in catalog.options:
		add_item(item)
	
	update_affordability()
	catalog_populated.emit()

func add_item(item: FoxShopItem) -> void:
	var slot = slot_scene.instantiate() as FoxShopSlot
	container.add_child(slot)
	
	slot.setup(item)
	
	slot.buy_button_pressed.connect(_on_slot_pressed)
	slot.buy_button_focused.connect(func(i): item_focused.emit(i))
	slot.buy_button_unfocused.connect(func(i): item_unfocused.emit(i))
	
	if _current_wallet:
		var can_buy = item.price.can_be_paid_by(_current_wallet) if item.price else true
		slot.set_affordability(can_buy)

func update_affordability(wallet: FoxWallet = _current_wallet) -> void:
	_current_wallet = wallet
	
	for slot in container.get_children():
		if slot is FoxShopSlot and slot.data:
			var can_buy = true
			if slot.data.price and _current_wallet:
				can_buy = slot.data.price.can_be_paid_by(_current_wallet)
				
			slot.set_affordability(can_buy)

func _clear_all_options() -> void:
	for child in container.get_children():
		child.queue_free()

func _on_slot_pressed(item: FoxShopItem) -> void:
	if not item.price:
		item_purchased.emit(item)
		return
		
	if not _current_wallet:
		push_warning("FoxShopMenu: Attempted purchase without a wallet.")
		return
		
	if item.price.can_be_paid_by(_current_wallet):
		item.price.pay(_current_wallet)
		item_purchased.emit(item)
		update_affordability()
	else:
		purchase_denied.emit(item, "insufficient_funds")
