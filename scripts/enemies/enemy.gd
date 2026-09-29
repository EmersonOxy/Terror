class_name Enemy
extends CharacterBody3D

enum State { IDLE, PATROL, CHASE, ATTACK, HIT_REACTION, DEAD }
signal state_changed(previous: State, current: State)
signal player_detected(target: Node3D)
signal player_lost(target: Node3D)
signal health_changed(current: float, maximum: float)
signal damaged(data: DamageData)
signal died(enemy: Enemy)
@export var definition: EnemyDefinition
@export var collider: CollisionShape3D
@export var health: HealthComponent
@export var motor: EnemyMotor
@export var perception: EnemyPerception
@export var combat: EnemyCombat
@export var visual: EnemyVisual
@export var patrol_points: Array[Node3D] = []
var state: State = State.IDLE
var facing: Vector3 = Vector3.FORWARD
var _patrol_index: int = 0
var _patrol_wait: float = 0.0
var _stagger: float = 0.0

func _ready() -> void:
	facing = -global_basis.z
	health.health_changed.connect(func(value: float, maximum: float): health_changed.emit(value, maximum))
	health.damaged.connect(_damaged)
	health.died.connect(_die)
	health.setup(definition.max_health)
	motor.setup(self, collider, definition)
	perception.setup(self, definition)
	combat.setup(self, definition)
	perception.detected.connect(func(target: Node3D): player_detected.emit(target))
	perception.lost.connect(func(target: Node3D): player_lost.emit(target))
	_present()

func set_candidate(value: Node3D) -> void:
	perception.clear()
	perception.candidate = value
	if value == null and state != State.DEAD:
		combat.cancel()
		motor.stop()
		_set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	perception.tick(delta, facing)
	combat.tick(delta)
	if health.dead:
		return
	var destination: Variant = null
	var looking := facing
	if _stagger > 0.0:
		_stagger = maxf(0.0, _stagger - delta)
		_set_state(State.HIT_REACTION)
	elif combat.winding_up:
		_set_state(State.ATTACK)
		if is_instance_valid(perception.target):
			looking = perception.target.global_position - global_position
	elif is_instance_valid(perception.target):
		_set_state(State.CHASE)
		looking = perception.last_known_position - global_position
		if perception.visible_target and combat.begin(perception.target):
			_set_state(State.ATTACK)
		elif not (perception.visible_target and global_position.distance_to(perception.last_known_position) < definition.attack_range * 0.8):
			destination = perception.last_known_position
	else:
		destination = _patrol(delta)
	motor.tick(delta, destination, state == State.CHASE)
	if motor.direction.length_squared() > 0.0:
		looking = motor.direction
	looking.y = 0.0
	if not looking.is_zero_approx():
		var yaw := lerp_angle(atan2(-facing.x, -facing.z), atan2(-looking.x, -looking.z), 1.0 - exp(-definition.turn_speed * delta))
		facing = Basis(Vector3.UP, yaw) * Vector3.FORWARD
	_present()

func _patrol(delta: float) -> Variant:
	if patrol_points.is_empty():
		_set_state(State.IDLE)
		return null
	_patrol_wait = maxf(0.0, _patrol_wait - delta)
	if _patrol_wait > 0.0:
		_set_state(State.IDLE)
		return null
	var point := patrol_points[_patrol_index]
	if not is_instance_valid(point):
		_set_state(State.IDLE)
		return null
	if global_position.distance_to(point.global_position) <= definition.waypoint_distance + 0.1:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_patrol_wait = definition.patrol_wait
		_set_state(State.IDLE)
		return null
	_set_state(State.PATROL)
	return point.global_position

func _set_state(value: State) -> void:
	if value == state:
		return
	var previous := state
	state = value
	state_changed.emit(previous, state)

func damage_point() -> Vector3:
	return global_position + Vector3.UP * definition.height * 0.6

func take_damage(data: DamageData) -> bool:
	return health.take_damage(data)

func _damaged(data: DamageData) -> void:
	combat.cancel()
	motor.stop()
	if not health.dead:
		_stagger = definition.stagger_duration
		_set_state(State.HIT_REACTION)
	# Receiving damage does not grant omniscient visual detection.
	damaged.emit(data)
	_present()

func _die() -> void:
	combat.cancel()
	perception.clear()
	motor.stop()
	_set_state(State.DEAD)
	collision_layer = 0
	collision_mask = 0
	collider.set_deferred("disabled", true)
	_present()
	set_physics_process(false)
	died.emit(self)
	get_tree().create_timer(definition.corpse_lifetime).timeout.connect(queue_free)

func _present() -> void:
	if is_instance_valid(visual):
		visual.present(facing, State.keys()[state], health.current, definition)
