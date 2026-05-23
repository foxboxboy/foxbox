class_name FoxShopCatalog
extends FoxResource

@export var options: Array[FoxShopItem] = []

func size() -> int:
	return options.size()

func get_option(index: int) -> FoxShopItem:
	if index >= 0 and index < options.size():
		return options[index]
	return null
