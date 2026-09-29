class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []
@export_range(0, 10) var max_drops: int = 3

## Rolls the table once and returns an array of {definition, quantity} dictionaries.
func roll() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for entry in entries:
		if entry == null or entry.item == null:
			continue
		if results.size() >= max_drops and not entry.guaranteed:
			continue
		var drop := entry.guaranteed or randf() <= entry.chance
		if drop:
			var qty := randi_range(entry.min_quantity, entry.max_quantity) if entry.max_quantity > entry.min_quantity else entry.min_quantity
			results.append({&"definition": entry.item, &"quantity": qty})
	return results
