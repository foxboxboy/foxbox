@icon("uid://c5rpdj7ur3yuj")
@abstract
class_name FoxWallet
extends FoxResource
## Abstract base class for all currency containers.
##
## Carries no members of its own. It exists as a shared type so [FoxPrice] can accept any
## currency container without knowing what the currency is.
## [br][br]
## Because there is no common interface here, a [FoxPrice] implementation is responsible for
## casting to the concrete wallet type it understands and failing gracefully when it receives
## something else. See [FoxSimplePrice] for the expected pattern.
## [br][br]
## Extend [FoxWallet] to create custom currency types, such as inventory slots, health points,
## or experience.
## [codeblock]
## # scrap_wallet.gd - currency here is a list of parts, not a number.
## class_name ScrapWallet
## extends FoxWallet
##
## @export var scrap: Array[StringName] = []
##
##
## # scrap_price.gd - the price knows how to read that specific wallet.
## class_name ScrapPrice
## extends FoxPrice
##
## @export var required: Array[StringName] = []
##
## func can_be_paid_by(wallet: FoxWallet) -> bool:
##     var w: ScrapWallet = wallet
##     if not w:
##         return false
##     for id in required:
##         if not w.scrap.has(id):
##             return false
##     return true
##
## func pay(wallet: FoxWallet) -> bool:
##     if not can_be_paid_by(wallet):
##         return false          # refuse before changing anything
##     var w: ScrapWallet = wallet
##     for id in required:
##         w.scrap.erase(id)
##     return true
##
## func get_display_string() -> String:
##     return ", ".join(required)
## [/codeblock]
## Nothing in the shop module knows what scrap is. It only asks the [FoxPrice] whether the
## trade can happen and then tells it to happen.
