class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damaged(data: DamageData)
signal died
var maximum: float = 100.0
var current: float = 100.0
var dead: bool = false

func setup(maximum_health: float) -> void:
	maximum = maxf(1.0, maximum_health)
	current = maximum
	dead = false
	health_changed.emit(current, maximum)

func take_damage(data: DamageData) -> bool:
	if dead or data == null or data.amount <= 0.0:
		return false
	current = maxf(0.0, current - data.amount)
	dead = current == 0.0
	health_changed.emit(current, maximum)
	damaged.emit(data)
	if dead:
		died.emit()
	return true
