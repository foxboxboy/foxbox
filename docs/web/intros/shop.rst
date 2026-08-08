The shop does not define what a currency is. It asks a :ref:`class_FoxPrice` whether a
:ref:`class_FoxWallet` can afford something, then tells it to perform the transaction. Both
questions are answered by your own code, so a currency can be an integer, a list of items, a
reputation value, or a level requirement.

Classes
-------

:ref:`class_FoxWallet` is an empty base type. It declares no members. A price casts it to the
concrete wallet type it expects and returns ``false`` if it receives anything else, so this is a
runtime check rather than a compile time one.

:ref:`class_FoxPrice` decides affordability and performs the transaction.

:ref:`class_FoxShopItem` holds display fields and a price, plus a product. The product is a
plain ``Resource`` and can be anything.

:ref:`class_FoxShopCatalog` is an ordered list of items.

:ref:`class_FoxSimpleWallet` and :ref:`class_FoxSimplePrice` are an ``int`` implementation.

Writing a custom currency
-------------------------

Extend :ref:`class_FoxWallet` to hold the currency and :ref:`class_FoxPrice` to spend it.

.. code-block:: gdscript

    # scrap_wallet.gd
    class_name ScrapWallet
    extends FoxWallet

    @export var scrap: Array[StringName] = []

.. code-block:: gdscript

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
            return false
        var w := wallet as ScrapWallet
        for id in required:
            w.scrap.erase(id)
        return true

    func get_display_string() -> String:
        return ", ".join(required)

Implementing pay
----------------

``pay`` must confirm the payment can go through before applying any part of it. A refused call
leaves the wallet unchanged. It returns ``true`` when the transaction happened and ``false``
when it did not.

.. note::

    A refusal does not necessarily mean insufficient funds. :ref:`class_FoxShopMenu` reports
    ``&"payment_refused"``, and a price can refuse for any reason it defines. Do not display
    that to the player as "not enough money" without checking what your price meant.
