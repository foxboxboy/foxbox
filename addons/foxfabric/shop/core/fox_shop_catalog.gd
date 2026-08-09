@icon("uid://bqldp3yklt16r")
class_name FoxShopCatalog
extends FoxResource
## An ordered list of [FoxShopItem] resources offered by a shop.
##
## [FoxShopCatalog] holds no transaction logic of its own. A catalog is only the stock list, so the same one can
## be shared between several shops or swapped out to change what a single shop sells.

## The items this catalog offers, in the order they should be presented.
@export var options: Array[FoxShopItem] = []


## Returns the number of items in this catalog.
func size() -> int:
	return options.size()


## Returns the [FoxShopItem] at [param index].
## [br][br]
## Returns [code]null[/code] when [param index] is out of range rather than erroring, so callers
## must check the result before using it.
func get_option(index: int) -> FoxShopItem:
	if index >= 0 and index < options.size():
		return options[index]
	return null
