extends Control
## A demo script showing how to bridge the FoxShop library with game logic.

#region Variables

@export_group("Components")
@export var shop_menu: FoxShopMenu
@export var money_label: Label
@export var details_label: Label
@export var add_money_button: Button

@export_group("Data")
## A catalog created in the Inspector containing FoxShopItems.
@export var starting_catalog: FoxShopCatalog

## The player's data state.
var player_wallet: FoxSimpleWallet = FoxSimpleWallet.new()

#endregion


#region Private Logic

func _ready() -> void:
	# 1. Setup the wallet
	player_wallet.funds = 100
	_update_money_ui()
	
	# 2. Connect to the Shop signals
	shop_menu.item_purchased.connect(_on_item_purchased)
	shop_menu.purchase_denied.connect(_on_purchase_denied)
	shop_menu.item_focused.connect(_on_item_focused)
	shop_menu.item_unfocused.connect(_on_item_unfocused)
	add_money_button.pressed.connect(_on_add_money_button_pressed)
	
	# 3. Open the shop!
	shop_menu.populate(starting_catalog, player_wallet)


func _update_money_ui() -> void:
	if money_label:
		money_label.text = "Wallet: $" + str(player_wallet.funds)

#endregion


#region Signal Callbacks

func _on_item_purchased(item: FoxShopItem) -> void:
	print("Bought: ", item.display_name)
	_update_money_ui()
	
	# Product handling: Shows the flexibility of the Resource system
	if item.product is PackedScene:
		var instance = item.product.instantiate()
		add_child(instance)
	elif item.product:
		print("Item had product: ", item.product)


func _on_purchase_denied(item: FoxShopItem, reason: StringName) -> void:
	print("Purchase failed for ", item.display_name, ". Reason: ", reason)



func _on_item_focused(item: FoxShopItem) -> void:
	if details_label:
		details_label.text = item.description
	print("Item focused: ", item.display_name)


func _on_item_unfocused(item: FoxShopItem) -> void:
	if details_label:
		details_label.text = "Select an item..."
	print("Item focus lost. ",item.display_name)


func _on_add_money_button_pressed() -> void:
	player_wallet.funds += 50
	_update_money_ui()
	shop_menu.update_affordability()

#endregion
