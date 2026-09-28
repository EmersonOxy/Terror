class_name ItemPickup
extends Interactable

@export var item: ItemInstance
@export var label: Label3D
@export var visual_root: Node3D
var _runtime_item: bool = false

func set_item(value: ItemInstance) -> void:
	item = value
	_runtime_item = true

func _ready() -> void:
	# Scene Resources are templates, never shared mutable quantities.
	if not _runtime_item and item != null:
		item = item.copy_with_quantity(item.quantity)
	if item != null and item.definition != null and item.definition.world_visual != null:
		for child in visual_root.get_children():
			child.queue_free()
		visual_root.add_child(item.definition.world_visual.instantiate())
	_update_label()

func can_interact(actor: Node3D) -> bool:
	return item != null and item.is_valid() and actor.has_method("collect_item")

func get_interaction_text(_actor: Node3D) -> String:
	return "Pegar %s x%d" % [item.definition.display_name, item.quantity]

func interact(actor: Node3D) -> void:
	if not can_interact(actor):
		return
	actor.collect_item(item)
	if item.quantity == 0:
		queue_free()
	else:
		_update_label()

func _update_label() -> void:
	if label and item != null and item.is_valid():
		label.text = "%s x%d" % [item.definition.display_name, item.quantity]
