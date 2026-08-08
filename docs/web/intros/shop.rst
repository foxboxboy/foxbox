A transaction system that refuses to define what money is.

Most shop code assumes currency is an integer. That assumption survives until you want to trade
scrap parts for a weapon, charge reputation for a quest, or gate a purchase behind a level
requirement. Here the shop only ever asks two questions: *can this be paid?* and *pay it*. What
those mean is entirely up to you.

The pieces
----------

:ref:`class_FoxWallet`
    An empty marker type. It has no members at all. Be aware of what that means in practice: a
    price receives a wallet, casts it to the concrete type it understands, and refuses politely
    if it gets something else. You get flexibility, not compile time safety.

:ref:`class_FoxPrice`
    Decides affordability and performs the transaction. This is where your rules live.

:ref:`class_FoxShopItem` and :ref:`class_FoxShopCatalog`
    What is on offer. An item pairs display fields with a price and a product, where the product
    is a plain ``Resource`` so it can be anything your project defines.

:ref:`class_FoxSimpleWallet` and :ref:`class_FoxSimplePrice`
    An integer implementation, ready to use and worth reading as the reference for writing
    your own.

Currency that is not a number
-----------------------------

.. code-block:: gdscript

    # scrap_wallet.gd
    class_name ScrapWallet
    extends FoxWallet

    @export var scrap: Array[StringName] = []


    # scrap_price.gd
    class_name ScrapPrice
    extends FoxPrice

    @export var required: Array[StringName] = []

    func can_be_paid_by(wallet: FoxWallet) -> bool:
        var w := wallet as ScrapWallet
        if not w:
            return false
        for id in required:
            if not w.scrap.has(id):
                return false
        return true

    func pay(wallet: FoxWallet) -> bool:
        if not can_be_paid_by(wallet):
            return false          # refuse before changing anything
        var w := wallet as ScrapWallet
        for id in required:
            w.scrap.erase(id)
        return true

    func get_display_string() -> String:
        return ", ".join(required)

The contract for ``pay``
------------------------

An implementation must confirm the payment can go through **before applying any part of it**, so
a refused call leaves the wallet exactly as it was. It returns ``true`` when the transaction
happened and ``false`` when it was refused.

A refusal does not necessarily mean insufficient funds, which is why
:ref:`class_FoxShopMenu` reports ``&"payment_refused"`` rather than guessing. Do not present
that to a player as "not enough money" without checking what your own price meant by it.
