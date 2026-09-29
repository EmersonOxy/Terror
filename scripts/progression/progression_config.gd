class_name ProgressionConfig
extends Resource

## XP curve
@export_group("XP Curve")
@export var base_xp: float = 100.0
@export var growth_factor: float = 1.55
@export var max_level: int = 20

## Points
@export_group("Points")
@export var points_per_level: int = 1
