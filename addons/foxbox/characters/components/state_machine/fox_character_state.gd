## Base state for all character-driven states in the Foxbox framework.
##
## [FoxCharacterState] extends the generic [FoxState] by introducing strictly typed 
## variables for core character components. These variables are automatically 
## injected by the parent [FoxCharacterStateMachine] during initialization.
##
## Specific implementations should extend this class and use 
## [annotation @export] to define their own specific motor needs.
@abstract class_name FoxCharacterState
extends FoxState

## The physics node of the character.
## Used by states and motors to apply velocity, detect floors, and handle world collisions.
var physics_body: CharacterBody3D

## The visual and animation controller for the character.
## Used by states to command stances (e.g., crouch, stand) and trigger animations.
var model: FoxCharacterModel

## Mediator for the entire character that exposes a huge API and inputs. 
var character: FoxCharacter
