class_name DamageData
extends RefCounted

var amount: float
var source: Node3D
var hit_position: Vector3
var direction: Vector3

func _init(value: float = 0.0, actor: Node3D = null, position: Vector3 = Vector3.ZERO, heading: Vector3 = Vector3.FORWARD) -> void:
	amount = value
	source = actor
	hit_position = position
	direction = heading
