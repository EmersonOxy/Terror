class_name DialogueDummy
extends Interactable

@export var sequence: DialogueSequence
var director: Node

func can_interact(actor: Node3D) -> bool:
	return sequence != null and is_instance_valid(director) and director.can_converse(actor)

func interact(actor: Node3D) -> void:
	if can_interact(actor):
		director.start_dialogue(sequence, actor)
