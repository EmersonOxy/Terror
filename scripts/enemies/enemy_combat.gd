class_name EnemyCombat
extends Node

signal attack_started
signal attack_resolved(hit: bool)
var actor: CollisionObject3D
var config: EnemyDefinition
var cooldown: float = 0.0
var windup_remaining: float = 0.0
var winding_up: bool = false
var _target: Node3D
var _ray := PhysicsRayQueryParameters3D.new()

func setup(owner_body: CollisionObject3D, settings: EnemyDefinition) -> void:
	actor = owner_body
	config = settings
	_ray.collision_mask = 11
	_ray.exclude = [actor.get_rid()]

func can_hit(subject: Node3D) -> bool:
	if not is_instance_valid(subject) or not subject.has_method("take_damage"):
		return false
	if actor.global_position.distance_to(subject.global_position) > config.attack_range:
		return false
	_ray.from = actor.global_position + Vector3.UP * config.height * 0.6
	_ray.to = subject.damage_point() if subject.has_method("damage_point") else subject.global_position
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(_ray)
	return not hit.is_empty() and hit.collider == subject

func begin(subject: Node3D) -> bool:
	if winding_up or cooldown > 0.0 or not can_hit(subject):
		return false
	_target = subject
	winding_up = true
	windup_remaining = config.attack_windup
	cooldown = config.attack_cooldown
	attack_started.emit()
	return true

func cancel() -> void:
	winding_up = false
	windup_remaining = 0.0
	_target = null

func tick(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if not winding_up:
		return
	windup_remaining = maxf(0.0, windup_remaining - delta)
	if windup_remaining > 0.0:
		return
	var subject := _target
	cancel()
	var hit := false
	if can_hit(subject):
		var point: Vector3 = subject.damage_point() if subject.has_method("damage_point") else subject.global_position
		hit = subject.take_damage(DamageData.new(config.attack_damage, actor, point, actor.global_position.direction_to(subject.global_position)))
	attack_resolved.emit(hit)
