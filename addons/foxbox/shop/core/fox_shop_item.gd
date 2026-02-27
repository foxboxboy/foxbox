class_name FoxShopItem
extends FoxResource
## A container for a single item, unit, or upgrade available for purchase.





#region Variables

@export_group("Display")

## The name of the option (e.g., "Super Cool Sword").
@export var display_name: StringName

## The icon representing this option in a menu or slot.
@export var icon: Texture2D

## A brief description of what this option does.
@export_multiline var description: String


@export_group("Transaction")

## The cost requirement. Drop a [FoxSimplePrice] or a custom [FoxPrice] here.
@export var price: FoxPrice

## The actual content being purchased (e.g., a [PackedScene], or any [Resource]).
@export var product: Resource

#endregion
