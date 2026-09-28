class_name StatusComponent
extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

var config: PlayerConfig
var health: float
var stamina: float
var dead: bool = false
var exhausted: bool = false
var _regen_remaining: float = 0.0

func setup(settings: PlayerConfig) -> void:
	config = settings
	health = config.max_health
	stamina = config.max_stamina

func damage(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	var applied := minf(amount, health)
	health -= applied
	health_changed.emit(health, config.max_health)
	damaged.emit(applied)
	if health <= 0.0:
		dead = true
		died.emit()

func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	health = minf(health + amount, config.max_health)
	health_changed.emit(health, config.max_health)

func can_sprint() -> bool:
	return not dead and not exhausted and stamina > 0.0

func consume_stamina(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	stamina = maxf(0.0, stamina - amount)
	_regen_remaining = config.regen_delay
	if stamina <= 0.0:
		exhausted = true
	stamina_changed.emit(stamina, config.max_stamina)

func tick(delta: float, sprinting: bool) -> void:
	if dead:
		return
	if sprinting:
		consume_stamina(config.sprint_cost * delta)
		return
	var available := maxf(0.0, delta - _regen_remaining)
	_regen_remaining = maxf(0.0, _regen_remaining - delta)
	if available > 0.0 and stamina < config.max_stamina:
		stamina = minf(config.max_stamina, stamina + config.stamina_regen * available)
		if stamina >= minf(config.exhaustion_recovery, config.max_stamina):
			exhausted = false
		stamina_changed.emit(stamina, config.max_stamina)
