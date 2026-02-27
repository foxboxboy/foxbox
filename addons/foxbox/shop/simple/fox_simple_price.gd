class_name FoxSimplePrice
extends FoxPrice
## A basic single-integer cost that specifically expects a [FoxSimpleWallet].





#region Variables

## How many funds will be removed from the [FoxSimpleWallet] when using [method pay].
@export var cost: int = 0

## The symbol prepended to the cost in [method get_display_string].
@export var currency_symbol: String = "$"

#endregion





#region Public API

## Returns [code]true[/code] if the provided [FoxWallet] is a [FoxSimpleWallet] 
## and has enough funds to cover the [member cost].
func can_be_paid_by(wallet: FoxWallet) -> bool:
	var simple_wallet = wallet as FoxSimpleWallet
	if simple_wallet:
		return simple_wallet.funds >= cost
		
	push_error("FoxSimplePrice: Expected a FoxSimpleWallet, but got something else.")
	return false


## Deducts the [member cost] from the provided [FoxSimpleWallet].
func pay(wallet: FoxWallet) -> void:
	var simple_wallet = wallet as FoxSimpleWallet
	if simple_wallet:
		simple_wallet.funds -= cost
	else:
		push_error("FoxSimplePrice: Expected a FoxSimpleWallet, but got something else.")


## Returns a formatted string for UI display based on the [member currency_symbol] and the [member cost].
func get_display_string() -> String:
	return currency_symbol + str(cost)

#endregion
