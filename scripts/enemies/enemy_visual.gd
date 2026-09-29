class_name EnemyVisual
extends Node3D

@export var mesh: MeshInstance3D
@export var label: Label3D
var _material: StandardMaterial3D

func _ready() -> void:
	_material = StandardMaterial3D.new()
	mesh.material_override = _material

func present(facing: Vector3, state: String, current: float, config: EnemyDefinition) -> void:
	var local_facing: Vector3 = get_parent().global_basis.inverse() * facing
	rotation.y = atan2(-local_facing.x, -local_facing.z)
	label.visible = config.show_label
	label.text = "%s | %s
HP %.0f / %.0f" % [config.display_name, state, current, config.max_health]
	var color := Color(0.55, 0.28, 0.24)
	if state == "ATTACK":
		color = Color(1.0, 0.7, 0.12)
	elif state == "HIT_REACTION":
		color = Color(1.0, 0.8, 0.75)
	elif state == "DEAD":
		color = Color(0.2, 0.2, 0.22)
		mesh.rotation.z = PI * 0.5
		mesh.position.y = config.radius
	_material.albedo_color = color
