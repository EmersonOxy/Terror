class_name ItemInstance
extends Resource

@export var definition: ItemDefinition
@export_range(0, 999) var quantity: int = 1

static func create(data: ItemDefinition, count: int = 1) -> ItemInstance:
	return data.create_instance(count) if data != null else null

func is_valid() -> bool:
	return definition != null and definition.is_valid() and quantity > 0

func can_stack_with(other: ItemInstance) -> bool:
	return other != null and definition == other.definition and get_script() == other.get_script() and definition.max_stack > 1

# Specialized instances may override stacking/copying when new state is introduced.
func copy_with_quantity(count: int) -> ItemInstance:
	var copy := duplicate(true) as ItemInstance
	copy.definition = definition
	copy.quantity = count
	return copy
