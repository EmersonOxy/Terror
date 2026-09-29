class_name BuildResolver
extends Node

signal build_changed
signal build_activated(build_id: StringName)
signal build_deactivated(build_id: StringName)

@export var equipment: EquipmentComponent
@export var modifiers: PlayerModifiers
@export var build_definitions: Array[BuildDefinition] = []

var active_build: BuildDefinition

func _ready() -> void:
	equipment.item_equipped.connect(_on_equipped)
	equipment.item_unequipped.connect(_on_unequipped)

func _on_equipped(slot: ItemDefinition.EquipSlot, item: ItemInstance) -> void:
	if not is_instance_valid(modifiers):
		return
	var source_id := StringName("equipment:" + str(slot))
	modifiers.add_modifiers(source_id, item.definition.modifiers)
	_recalculate_build()

func _on_unequipped(slot: ItemDefinition.EquipSlot, _item: ItemInstance) -> void:
	if not is_instance_valid(modifiers):
		return
	var source_id := StringName("equipment:" + str(slot))
	modifiers.remove_modifiers(source_id)
	_recalculate_build()

func _recalculate_build() -> void:
	var head = equipment.get_equipped(ItemDefinition.EquipSlot.HEAD)
	var body = equipment.get_equipped(ItemDefinition.EquipSlot.BODY)
	var weapon = equipment.get_equipped(ItemDefinition.EquipSlot.WEAPON)
	
	var new_build: BuildDefinition = null
	
	if head != null and body != null and weapon != null:
		var w_head = head.definition.weight_class
		var w_body = body.definition.weight_class
		var w_weapon = weapon.definition.weight_class
		
		if w_head != ItemDefinition.WeightClass.NONE and w_head == w_body and w_body == w_weapon:
			new_build = _find_build_for_weight(w_head)
			
	if new_build != active_build:
		if active_build != null:
			var source_id = StringName("build:" + active_build.id)
			modifiers.remove_modifiers(source_id)
			build_deactivated.emit(active_build.id)
			
		active_build = new_build
		
		if active_build != null:
			var source_id = StringName("build:" + active_build.id)
			modifiers.add_modifiers(source_id, active_build.modifiers)
			build_activated.emit(active_build.id)
			
		build_changed.emit()

func _find_build_for_weight(weight: ItemDefinition.WeightClass) -> BuildDefinition:
	for b in build_definitions:
		if b != null and b.required_weight_class == weight:
			return b
	return null
