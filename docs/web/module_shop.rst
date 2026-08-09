:github_url: hide

Shop
====

Wallets, prices, and catalogues for buying things. A price decides for itself whether a wallet can pay, so currency can be coins, scrap, or a specific item.

The module does not define what a currency is. It asks a :ref:`class_FoxPrice` whether a
:ref:`class_FoxWallet` can afford something, then tells it to perform the transaction.

:ref:`class_FoxWallet` declares no members. A price casts it to the wallet type it expects and
returns ``false`` otherwise, so this is a runtime check. :ref:`class_FoxShopItem` holds display
fields, a price, and a product as a plain ``Resource``. :ref:`class_FoxShopCatalog` is an ordered
list of items. :ref:`class_FoxSimpleWallet` and :ref:`class_FoxSimplePrice` are an ``int``
implementation.

Extend both to define a currency.

.. code-block:: gdscript

    class_name ScrapWallet
    extends FoxWallet

    @export var scrap: Array[StringName] = []

.. code-block:: gdscript

    class_name ScrapPrice
    extends FoxPrice

    @export var required: Array[StringName] = []

    func can_be_paid_by(wallet: FoxWallet) -> bool:
        var w: ScrapWallet = wallet
        if not w:
            return false
        for id in required:
            if not w.scrap.has(id):
                return false
        return true

    func pay(wallet: FoxWallet) -> bool:
        if not can_be_paid_by(wallet):
            return false
        var w: ScrapWallet = wallet
        for id in required:
            w.scrap.erase(id)
        return true

``pay`` must confirm the payment before applying any part of it, so a refused call leaves the
wallet unchanged.

.. note::

    A refusal does not imply insufficient funds. :ref:`class_FoxShopMenu` reports
    ``&"payment_refused"`` because a price can refuse for any reason.

.. toctree::
   :maxdepth: 1

   module_shop-core
   module_shop-gui
   module_shop-simple
