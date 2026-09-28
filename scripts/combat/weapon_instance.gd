class_name WeaponInstance
extends ItemInstance

@export_range(0, 100) var ammo_in_magazine: int = 0

func is_valid() -> bool:
	return super.is_valid() and definition is WeaponDefinition
