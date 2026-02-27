class_name FoxShopCatalog
extends FoxResource
## A collection of [FoxShopItem] resources used to populate shops.


## The list of purchaseable options in this catalog.
@export var options: Array[FoxShopItem] = []


## Returns the number of options in the catalog.
func size() -> int:
	return options.size()


## Returns a specific [FoxShopItem] by its index.
func get_option(index: int) -> FoxShopItem:
	if index >= 0 and index < options.size():
		return options[index]
	return null
