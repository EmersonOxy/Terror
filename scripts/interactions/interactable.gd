class_name Interactable
extends Area3D

@export var interaction_priority: float = 0.0
@export var prompt: String = "Interagir"

func can_interact(_actor: Node3D) -> bool:
	return true

func interact(_actor: Node3D) -> void:
	pass

func get_interaction_text(_actor: Node3D) -> String:
	return prompt
