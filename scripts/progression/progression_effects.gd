class_name ProgressionEffects
extends RefCounted

## Applies upgrade effects to existing components. Called by the composition
## root whenever an upgrade rank changes. The ProgressionComponent itself never
## touches Status or Inventory.

const VITALITY := &"vitality"
const CONDITIONING := &"conditioning"
const BACKPACK := &"backpack"

## Applies one rank of an upgrade. value_per_rank comes from the UpgradeDefinition.
static func apply(upgrade_id: StringName, value: float, status: StatusComponent, inventory: InventoryComponent) -> void:
	match upgrade_id:
		VITALITY:
			_increase_max_health(status, value)
		CONDITIONING:
			_increase_max_stamina(status, value)
		BACKPACK:
			_increase_capacity(inventory, int(value))

## Increases max HP and current HP by the same amount.
## 50/100 + 5 → 55/105, 100/100 + 5 → 105/105.
static func _increase_max_health(status: StatusComponent, amount: float) -> void:
	status.config.max_health += amount
	status._on_modifiers_changed()

## Increases max stamina and current stamina by the same amount.
static func _increase_max_stamina(status: StatusComponent, amount: float) -> void:
	status.config.max_stamina += amount
	status._on_modifiers_changed()

## Increases inventory capacity by amount (int slots).
static func _increase_capacity(inventory: InventoryComponent, amount: int) -> void:
	inventory.set_capacity(inventory.capacity() + amount)
