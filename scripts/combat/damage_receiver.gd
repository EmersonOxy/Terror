class_name DamageReceiver
extends StaticBody3D

signal damaged(data: DamageData)
signal died
@export var max_health: float = 100.0
@export var hit_offset: Vector3 = Vector3(0, 0.9, 0)
var health: float
var dead: bool = false

func _ready() -> void:
	health = max_health

func damage_point() -> Vector3:
	return to_global(hit_offset)

# Collision objects implementing this contract can be hit without weapon changes.
func take_damage(data: DamageData) -> bool:
	if dead or data.amount <= 0.0:
		return false
	health = maxf(0.0, health - data.amount)
	damaged.emit(data)
	if health == 0.0:
		dead = true
		died.emit()
	return true
