class_name UpgradeDefinition
extends Resource

## Unique identifier for this upgrade path.
@export var id: StringName = &""
## Name shown in the progression menu.
@export var display_name: String = ""
## Short description of the effect.
@export var description: String = ""
## Maximum times this upgrade can be purchased.
@export var max_rank: int = 5
## Value added per rank (e.g. +5 HP, +5 stamina, +1 slot).
@export var value_per_rank: float = 5.0
