class_name PlayerModifiers
extends Node

signal modifiers_changed

## source_id -> Array[ModifierDefinition]
var _active_modifiers: Dictionary = {}

func add_modifiers(source_id: StringName, mods: Array) -> void:
	if mods.is_empty():
		return
	_active_modifiers[source_id] = mods
	modifiers_changed.emit()

func remove_modifiers(source_id: StringName) -> void:
	if _active_modifiers.erase(source_id):
		modifiers_changed.emit()

func get_add(stat: int) -> float:
	var total := 0.0
	for mods in _active_modifiers.values():
		for m in mods:
			if m.stat == stat:
				total += m.value
	return total

func get_mult(stat: int) -> float:
	var total := 1.0
	for mods in _active_modifiers.values():
		for m in mods:
			if m.stat == stat:
				total += m.value
	return total
