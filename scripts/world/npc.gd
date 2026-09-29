class_name NPC
extends StaticBody3D

@export var npc_id: StringName
@export var display_name: String
@export var dialogue: DialogueSequence
@export var shop: ShopComponent
@export var label_node: Label3D
@export var mesh_node: MeshInstance3D

var _narrative: NarrativeSystem
var _interaction_prompt: String = ""

func setup(narrative: NarrativeSystem) -> void:
	_narrative = narrative
	_update_prompt()

func _update_prompt() -> void:
	if shop != null and shop.shop_data != null:
		_interaction_prompt = "Conversar / Comprar"
	elif dialogue != null:
		_interaction_prompt = "Conversar"
	else:
		_interaction_prompt = "Interagir"

func can_interact(_actor: Node3D) -> bool:
	return true

func get_interaction_text(_actor: Node3D) -> String:
	return _interaction_prompt

func interact(_actor: Node3D) -> void:
	if dialogue != null and _narrative != null:
		_narrative.play_sequence(dialogue, npc_id)
		if shop != null:
			# Open shop after dialogue finishes
			_narrative.sequence_finished.connect(_on_dialogue_done, CONNECT_ONE_SHOT)
	elif shop != null:
		shop_requested.emit()

signal shop_requested
signal interaction_started

func _on_dialogue_done(_id: StringName, cancelled: bool) -> void:
	if not cancelled:
		shop_requested.emit()
