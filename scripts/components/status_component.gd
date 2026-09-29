class_name StatusComponent
extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

var config: PlayerConfig
@export var modifiers: PlayerModifiers

var health: float
var stamina: float
var dead: bool = false
var exhausted: bool = false
var _regen_remaining: float = 0.0
var _prev_max_health: float = 0.0
var _prev_max_stamina: float = 0.0

func setup(settings: PlayerConfig) -> void:
	config = settings
	_prev_max_health = config.max_health
	_prev_max_stamina = config.max_stamina
	health = _prev_max_health
	stamina = _prev_max_stamina
	if modifiers:
		modifiers.modifiers_changed.connect(_on_modifiers_changed)

func effective_max_health() -> float:
	var add := modifiers.get_add(ModifierDefinition.Stat.MAX_HEALTH_ADD) if modifiers else 0.0
	return config.max_health + add

func effective_max_stamina() -> float:
	var add := modifiers.get_add(ModifierDefinition.Stat.MAX_STAMINA_ADD) if modifiers else 0.0
	return config.max_stamina + add

func _on_modifiers_changed() -> void:
	var new_max_health := effective_max_health()
	var diff_health := new_max_health - _prev_max_health
	if diff_health > 0.0 and not dead:
		health += diff_health
	health = minf(health, new_max_health)
	_prev_max_health = new_max_health
	health_changed.emit(health, new_max_health)
	
	var new_max_stamina := effective_max_stamina()
	var diff_stamina := new_max_stamina - _prev_max_stamina
	if diff_stamina > 0.0 and not dead:
		stamina += diff_stamina
	stamina = minf(stamina, new_max_stamina)
	_prev_max_stamina = new_max_stamina
	stamina_changed.emit(stamina, new_max_stamina)

func damage(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	var applied := minf(amount, health)
	health -= applied
	health_changed.emit(health, effective_max_health())
	damaged.emit(applied)
	if health <= 0.0:
		dead = true
		died.emit()

func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	var e_max := effective_max_health()
	health = minf(health + amount, e_max)
	health_changed.emit(health, e_max)

func can_sprint() -> bool:
	return not dead and not exhausted and stamina > 0.0

func consume_stamina(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	stamina = maxf(0.0, stamina - amount)
	_regen_remaining = config.regen_delay
	if stamina <= 0.0:
		exhausted = true
	stamina_changed.emit(stamina, effective_max_stamina())

func tick(delta: float, sprinting: bool) -> void:
	if dead:
		return
	if sprinting:
		var mult := modifiers.get_mult(ModifierDefinition.Stat.SPRINT_STAMINA_COST_MULT) if modifiers else 1.0
		consume_stamina((config.sprint_cost * mult) * delta)
		return
	var available := maxf(0.0, delta - _regen_remaining)
	_regen_remaining = maxf(0.0, _regen_remaining - delta)
	if available > 0.0 and stamina < effective_max_stamina():
		var e_max := effective_max_stamina()
		stamina = minf(e_max, stamina + config.stamina_regen * available)
		if stamina >= minf(config.exhaustion_recovery, e_max):
			exhausted = false
		stamina_changed.emit(stamina, e_max)
