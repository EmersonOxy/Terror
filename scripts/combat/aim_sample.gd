class_name AimSample
extends RefCounted

var origin: Vector3
var target: Vector3
var direction: Vector3
var active: bool = false

func _init(from: Vector3, to: Vector3, precise: bool = false) -> void:
	origin = from
	target = to
	direction = from.direction_to(to)
	active = precise
