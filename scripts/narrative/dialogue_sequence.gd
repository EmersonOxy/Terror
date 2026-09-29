class_name DialogueSequence
extends Resource

enum Priority { LOW, NORMAL, HIGH }
@export var sequence_id: StringName
@export var lines: Array[DialogueLine] = []
@export var priority: Priority = Priority.NORMAL
@export var interruptible: bool = true
@export var interactive: bool = false

func is_valid() -> bool:
	if sequence_id.is_empty() or lines.is_empty():
		return false
	for line in lines:
		if line == null or line.text.strip_edges().is_empty():
			return false
	return true
