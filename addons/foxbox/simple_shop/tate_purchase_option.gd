#tate_lib/modules/simple_shop/tate_purchase_option.gd
extends TateResource
class_name TatePurchaseOption
## A container for a single item, unit, or upgrade available for purchase.

@export_group("Display")
## The name for this option (ex: "Super Cool Sword").
@export var display_name: StringName
## Icon a card or something else.
@export var icon: Texture2D
## A brief description of what this option does.
@export_multiline var description: String

@export_group("Transaction")
@export var cost: int = 0
## Any extra resource you want to pass along with this
## purchase option.
@export var payload: Resource
