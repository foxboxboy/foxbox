# modules/core/effects/effect.gd
@abstract
class_name TateModifier
extends Resource
## Abstract base for status effects, upgrades, and instant actions.

enum StackMode { UNIQUE, STACKING, ADDITIVE }

#@export_group("Metadata")
@export var effect_id: String = "generic_effect"

## How the effect will be applied.
## StackMode.UNIQUE = New Weapon
## StackMode.STACKING = Stat Boost
## StackMode.ADDIDITIVE = Timed Buff
@export var stack_mode: StackMode = StackMode.UNIQUE

## How long this effect will last. Leave as -1 for indefinite.
@export var duration: float = -1 # -1 for permanent

## Logic to run when applied
func execute(target: Node) -> void:
	_on_execute(target)

## Logic to run when time runs out or it's removed
func remove(target: Node) -> void:
	_on_remove(target)

# Virtual methods for implementation
func _on_execute(_target: Node) -> void: pass
func _on_remove(_target: Node) -> void: pass
