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
## [br][br]
## Implementations must confirm the payment can go through before applying any part of it, so a
## refused call leaves the wallet exactly as it was. What "can go through" means is entirely up
## to the implementation. It does not have to be a number comparison, and it does not have to
## reject negative or empty results.
## [br][br]
## Returns [code]true[/code] if the transaction was applied and [code]false[/code] if it was
## refused. A refusal does not necessarily mean insufficient funds.
@abstract
func pay(wallet: FoxWallet) -> bool

## Returns a formatted string representing the cost (e.g., "$50").
@abstract
func get_display_string() -> String
