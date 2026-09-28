class_name ItemDefinition
extends Resource

enum Category { GENERIC, CONSUMABLE, WEAPON, ARMOR, KEY_ITEM }
enum EquipSlot { NONE, WEAPON, HEAD, BODY }
enum WeightClass { NONE, LIGHT, MEDIUM, HEAVY }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category = Category.GENERIC
@export_range(1, 999) var max_stack: int = 1
@export var icon: Texture2D
@export var world_visual: PackedScene
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var weight_class: WeightClass = WeightClass.NONE
@export var use_effect: ItemUseEffect

func is_valid() -> bool:
	return not id.is_empty() and max_stack >= 1 and (equip_slot == EquipSlot.NONE or max_stack == 1)
