class_name DialogueLine
extends Resource

@export var speaker_id: StringName
@export var speaker_name: String
@export_multiline var text: String
@export var duration: float = 0.0

func display_duration() -> float:
	return duration if duration > 0.0 else clampf(1.2 + text.length() * 0.055, 2.0, 10.0)
