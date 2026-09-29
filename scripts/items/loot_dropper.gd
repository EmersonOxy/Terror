class_name LootDropper
extends Node

## Spawns ItemPickups near a world position when triggered.
## Connect to Enemy.died or any other death signal.

const PICKUP := preload("res://scenes/items/item_pickup.tscn")
var _dropped: bool = false

## Rolls loot_table and spawns pickups around origin, parented under spawn_root.
func drop(loot_table: Resource, origin: Vector3, spawn_root: Node3D) -> void:
	if _dropped or loot_table == null:
		return
	_dropped = true
	var table := loot_table as LootTable
	if table == null:
		return
	var results := table.roll()
	var count := results.size()
	for i in count:
		var entry: Dictionary = results[i]
		var def: ItemDefinition = entry[&"definition"]
		var qty: int = entry[&"quantity"]
		var instance := def.create_instance(qty)
		var pickup := PICKUP.instantiate() as ItemPickup
		pickup.set_item(instance)
		spawn_root.add_child(pickup)
		# Slight spread so multiple drops don't stack exactly
		var angle := TAU * float(i) / maxf(1.0, float(count))
		var offset := Vector3(cos(angle) * 0.5, 0.0, sin(angle) * 0.5) if count > 1 else Vector3.ZERO
		pickup.global_position = origin + offset + Vector3(0, 0.185, 0)
