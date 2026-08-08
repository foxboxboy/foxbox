class_name FoxSimplePrice
extends FoxPrice
## Basic price implementation using [int] and [FoxSimpleWallet].

## The cost of the item.
@export var cost: int = 0

## The symbol used for display (e.g., "$", "G", "pts").
@export var currency_symbol: String = "$"

## Returns [code]true[/code] if the provided [param wallet] (must be a [FoxSimpleWallet]) 
## has sufficient funds to cover the [member cost]. 
## Returns [code]false[/code] if the funds are insufficient or if an 
## incompatible [FoxWallet] type is provided.
func can_be_paid_by(wallet: FoxWallet) -> bool:
	var simple_wallet := wallet as FoxSimpleWallet
	if simple_wallet:
		return simple_wallet.funds >= cost
		
	push_error("FoxSimplePrice: Expected a FoxSimpleWallet, but received an incompatible type.")
	return false

## Deducts the [member cost] from the provided [param wallet].
## [br][br]
## Returns [code]false[/code] without touching the wallet when the funds are insufficient or an
## incompatible [FoxWallet] type is provided.
func pay(wallet: FoxWallet) -> bool:
	# can_be_paid_by already reports an incompatible wallet type
	if not can_be_paid_by(wallet):
		return false

	var simple_wallet := wallet as FoxSimpleWallet
	simple_wallet.funds -= cost
	return true

## Returns the cost as a formatted [String] with the [member currency_symbol].
func get_display_string() -> String:
	return currency_symbol + str(cost)
