class_name WeaponDefinition
extends ItemDefinition

enum WeaponType { MELEE, RANGED }
@export var weapon_type: WeaponType = WeaponType.MELEE
@export_range(0.1, 200.0) var damage: float = 25.0
@export_range(0.05, 5.0) var attack_interval: float = 0.55
@export_range(0.0, 100.0) var stamina_cost: float = 18.0
@export_range(0.1, 100.0) var range: float = 1.8
@export_group("Ranged")
@export_range(1, 100) var magazine_capacity: int = 6
@export_range(0.1, 10.0) var reload_duration: float = 1.4
@export var ammunition: ItemDefinition

func create_instance(count: int = 1) -> ItemInstance:
	var item := WeaponInstance.new()
	item.definition = self
	item.quantity = count
	item.ammo_in_magazine = magazine_capacity if weapon_type == WeaponType.RANGED else 0
	return item

func is_valid() -> bool:
	return super.is_valid() and equip_slot == EquipSlot.WEAPON and damage > 0.0 and range > 0.0 and attack_interval > 0.0
