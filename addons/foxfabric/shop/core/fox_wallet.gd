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
