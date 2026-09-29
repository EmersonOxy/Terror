class_name LootEntry
extends Resource

@export var item: ItemDefinition
@export_range(0.0, 1.0) var chance: float = 1.0
@export_range(1, 99) var min_quantity: int = 1
@export_range(1, 99) var max_quantity: int = 1
@export var guaranteed: bool = false
