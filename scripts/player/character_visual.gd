class_name CharacterVisual
extends Node3D

var obstruction_highlight := VisualHighlight.new()

func _ready() -> void:
	obstruction_highlight.setup(self)

func set_obstruction_strength(value: float) -> void:
	obstruction_highlight.apply(value)

func _exit_tree() -> void:
	obstruction_highlight.apply(0.0)

# Visual contract only. Gameplay works without a visual instance.
func present(direction: Vector3, height_ratio: float, dead: bool, delta: float, turn_speed: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-turn_speed * delta))
	scale.y = lerpf(scale.y, height_ratio, 1.0 - exp(-18.0 * delta))
	rotation.z = lerp_angle(rotation.z, PI * 0.5 if dead else 0.0, 1.0 - exp(-5.0 * delta))
