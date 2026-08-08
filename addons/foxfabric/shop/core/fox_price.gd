@icon("uid://cjf8prmuxwnac")
@abstract
class_name FoxPrice
extends FoxResource
## Abstract base class for defining currency costs.
##
## Classes extending [FoxPrice] must implement the logic for checking 
## affordability and performing transactions against a [FoxWallet].

## Returns [code]true[/code] if the provided [param wallet] can afford this price.
@abstract
func can_be_paid_by(wallet: FoxWallet) -> bool

## Performs the transaction against the provided [param wallet].
@abstract
func pay(wallet: FoxWallet) -> void

## Returns a formatted string representing the cost (e.g., "$50").
@abstract
func get_display_string() -> String
