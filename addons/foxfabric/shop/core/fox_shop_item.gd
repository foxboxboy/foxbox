@icon("uid://dq6eveqbdipqk")
class_name FoxShopItem
extends FoxResource
## A single entry in a [FoxShopCatalog], pairing what is shown to the player with what is
## exchanged.
##
## The display fields exist purely for presentation. The transaction fields are what the shop
## acts on, and neither one assumes the product is an item, a number, or anything in particular.

@export_group("Display")

## The name shown to the player.
@export var display_name: StringName

## The image shown to the player, typically in a shop slot.
@export var icon: Texture2D

## A longer description shown to the player, for tooltips or detail panels.
@export_multiline var description: String

@export_group("Transaction")

## What this item costs. The [FoxPrice] decides what currency means and whether a given
## [FoxWallet] can afford it.
@export var price: FoxPrice

## What the buyer receives. Left as a plain [Resource] so it can be anything your project
## defines, such as an inventory entry, an ability, or another [FoxEffect].
@export var product: Resource
