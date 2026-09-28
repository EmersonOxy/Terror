class_name MovementComponent
extends Node

var config: PlayerConfig
var body: CharacterBody3D
var collider: CollisionShape3D
var crouched: bool = false
var sprinting: bool = false
var state: String = "parado"
var facing: Vector3 = Vector3.FORWARD
var _standing_shape: CapsuleShape3D

func setup(actor: CharacterBody3D, shape_node: CollisionShape3D, settings: PlayerConfig) -> void:
	body = actor
	collider = shape_node
	config = settings
	collider.shape = collider.shape.duplicate()
	_standing_shape = CapsuleShape3D.new()
	_standing_shape.radius = config.radius
	_standing_shape.height = config.standing_height
	body.floor_snap_length = config.floor_snap
	body.floor_constant_speed = true
	_set_crouched(false)

func tick(delta: float, direction: Vector3, wants_crouch: bool, wants_sprint: bool, alive: bool) -> void:
	if alive:
		if wants_crouch:
			_set_crouched(true)
		elif crouched and can_stand():
			_set_crouched(false)
	else:
		direction = Vector3.ZERO
	sprinting = alive and wants_sprint and not crouched and direction.length_squared() > 0.01
	var speed := config.crouch_speed if crouched else (config.sprint_speed if sprinting else config.walk_speed)
	var target := direction * speed
	var rate := config.acceleration if direction.length_squared() > 0.01 else config.deceleration
	var horizontal := Vector3(body.velocity.x, 0.0, body.velocity.z).move_toward(target, rate * delta)
	if not alive:
		horizontal = Vector3.ZERO
	body.velocity.x = horizontal.x
	body.velocity.z = horizontal.z
	body.velocity.y = -config.gravity * delta if body.is_on_floor() else body.velocity.y - config.gravity * delta
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	_try_step(horizontal * delta)
	body.move_and_slide()
	state = "morto" if not alive else ("agachado" if crouched else ("correndo" if sprinting else ("andando" if horizontal.length() > 0.1 else "parado")))

func can_stand() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _standing_shape
	query.transform = Transform3D(Basis.IDENTITY, body.global_position + Vector3.UP * (config.standing_height * 0.5 + 0.01))
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	return body.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _set_crouched(value: bool) -> void:
	crouched = value
	var height := config.crouching_height if value else config.standing_height
	collider.shape.radius = config.radius
	collider.shape.height = height
	collider.position.y = height * 0.5

func _try_step(motion: Vector3) -> void:
	if not body.is_on_floor() or motion.length_squared() < 0.000001 or config.step_height <= 0.0:
		return
	var hit := KinematicCollision3D.new()
	if not body.test_move(body.global_transform, motion, hit):
		return
	if hit.get_normal().dot(Vector3.UP) > cos(body.floor_max_angle):
		return
	var lift := Vector3.UP * (config.step_height + 0.02)
	if body.test_move(body.global_transform, lift):
		return
	var raised := body.global_transform
	raised.origin += lift
	var probe := motion.normalized() * maxf(motion.length(), config.radius + 0.05)
	if body.test_move(raised, probe):
		return
	raised.origin += probe
	var landing := KinematicCollision3D.new()
	if not body.test_move(raised, -lift, landing):
		return
	if landing.get_normal().dot(Vector3.UP) < cos(body.floor_max_angle):
		return
	var rise := lift.y + landing.get_travel().y
	if rise <= 0.01 or rise > config.step_height + 0.01:
		return
	body.global_position.y += rise
	body.velocity.y = 0.0
