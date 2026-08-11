extends FoxTest


## A price whose currency is a list of parts rather than a number, mirroring the example in
## the FoxWallet docs. Proves the module really is currency agnostic.
class ScrapWallet extends FoxWallet:
	var scrap: Array[StringName] = []


class ScrapPrice extends FoxPrice:
	var required: Array[StringName] = []

	func can_be_paid_by(wallet: FoxWallet) -> bool:
		var w: ScrapWallet = wallet as ScrapWallet
		if not w:
			return false
		for id: StringName in required:
			if not w.scrap.has(id):
				return false
		return true

	func pay(wallet: FoxWallet) -> bool:
		if not can_be_paid_by(wallet):
			return false
		var w: ScrapWallet = wallet as ScrapWallet
		for id: StringName in required:
			w.scrap.erase(id)
		return true

	func get_display_string() -> String:
		return ", ".join(required)


func run() -> void:
	suite = "shop"
	_affordability()
	_paying_deducts()
	_refusal_leaves_the_wallet_untouched()
	_display_string()
	_catalog_bounds()
	_non_numeric_currency()
	_random_purchase_sequences_never_overdraw()


func _affordability() -> void:
	start_case("can_be_paid_by")
	var w: FoxSimpleWallet = FoxSimpleWallet.new()
	w.funds = 100

	var p: FoxSimplePrice = FoxSimplePrice.new()
	p.cost = 50
	check(p.can_be_paid_by(w), "enough funds is affordable")

	p.cost = 100
	check(p.can_be_paid_by(w), "exactly enough is affordable")

	p.cost = 101
	check(not p.can_be_paid_by(w), "one short is not affordable")


func _paying_deducts() -> void:
	start_case("paying")
	var w: FoxSimpleWallet = FoxSimpleWallet.new()
	w.funds = 100
	var p: FoxSimplePrice = FoxSimplePrice.new()
	p.cost = 30

	var ok: bool = p.pay(w)
	check(ok, "a valid payment reports success")
	check_equal(w.funds, 70, "funds are reduced by the cost")

	p.pay(w)
	p.pay(w)
	check_equal(w.funds, 10, "repeated payments keep deducting while affordable")


## Regression: pay() used to deduct unconditionally, so calling it without checking
## affordability first would silently drive the wallet past zero.
func _refusal_leaves_the_wallet_untouched() -> void:
	start_case("refusal is atomic")
	var w: FoxSimpleWallet = FoxSimpleWallet.new()
	w.funds = 10
	var p: FoxSimplePrice = FoxSimplePrice.new()
	p.cost = 999

	var ok: bool = p.pay(w)
	check(not ok, "an unaffordable payment reports failure")
	check_equal(w.funds, 10, "a refused payment does not touch the wallet at all")


func _display_string() -> void:
	start_case("display string")
	var p: FoxSimplePrice = FoxSimplePrice.new()
	p.cost = 42
	p.currency_symbol = "G"
	check_equal(p.get_display_string(), "G42", "symbol and cost are concatenated")


func _catalog_bounds() -> void:
	start_case("catalog bounds")
	var c: FoxShopCatalog = FoxShopCatalog.new()
	check_equal(c.size(), 0, "a fresh catalog is empty")
	check_equal(c.get_option(0), null, "reading an empty catalog returns null rather than erroring")

	var item: FoxShopItem = FoxShopItem.new()
	item.display_name = &"Apple"
	c.options.append(item)

	check_equal(c.size(), 1, "size tracks the options array")
	check_equal(c.get_option(0), item, "index 0 returns the first item")
	check_equal(c.get_option(1), null, "one past the end returns null")
	check_equal(c.get_option(-1), null, "a negative index returns null")


## The whole point of the abstraction: currency that is not a number at all.
func _non_numeric_currency() -> void:
	start_case("currency as a list of parts")
	var w: ScrapWallet = ScrapWallet.new()
	w.scrap = [&"bolt", &"spring", &"gear"]

	var p: ScrapPrice = ScrapPrice.new()
	p.required = [&"bolt", &"gear"]

	check(p.can_be_paid_by(w), "having every required part is affordable")
	check(p.pay(w), "paying with parts succeeds")
	check_equal(w.scrap.size(), 1, "only the required parts were consumed")
	check(w.scrap.has(&"spring"), "the unrelated part is still there")

	check(not p.can_be_paid_by(w), "the same price is no longer affordable")
	check(not p.pay(w), "a second payment is refused")
	check_equal(w.scrap.size(), 1, "the refused payment consumed nothing")

	start_case("wrong wallet type")
	var wrong: FoxSimpleWallet = FoxSimpleWallet.new()
	wrong.funds = 9999
	check(not p.can_be_paid_by(wrong), "an incompatible wallet is never affordable")


func _random_purchase_sequences_never_overdraw() -> void:
	start_case("invariant: funds never go negative")
	var breaches: int = 0

	for i: int in 200:
		var w: FoxSimpleWallet = FoxSimpleWallet.new()
		w.funds = rng.randi_range(0, 200)
		var p: FoxSimplePrice = FoxSimplePrice.new()

		for j: int in 25:
			p.cost = rng.randi_range(0, 60)
			p.pay(w)
			if w.funds < 0:
				breaches += 1

	check_equal(breaches, 0, "5000 unchecked pay() calls never pushed a wallet below zero")
