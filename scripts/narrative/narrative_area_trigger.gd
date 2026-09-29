class_name NarrativeAreaTrigger
extends Area3D

@export var narrative_event_id: StringName
var actor: Node3D
var narrative: NarrativeSystem

func _ready() -> void:
	body_entered.connect(_entered)

func _entered(body: Node3D) -> void:
	if body == actor and is_instance_valid(narrative):
		narrative.request_event(narrative_event_id)
