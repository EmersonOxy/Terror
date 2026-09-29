class_name EnemyPerception
extends Node

signal detected(target: Node3D)
signal lost(target: Node3D)
var actor: CollisionObject3D
var config: EnemyDefinition
var candidate: Node3D
var target: Node3D
var visible_target: bool = false
var last_known_position: Vector3
var memory_remaining: float = 0.0
var scans: int = 0
var _remaining: float = 0.0
var _ray := PhysicsRayQueryParameters3D.new()

func setup(owner_body: CollisionObject3D, settings: EnemyDefinition) -> void:
	actor = owner_body
	config = settings
	_ray.collision_mask = 11
	_ray.exclude = [actor.get_rid()]

func clear() -> void:
	var previous := target
	target = null
	visible_target = false
	memory_remaining = 0.0
	if is_instance_valid(previous):
		lost.emit(previous)

func tick(delta: float, facing: Vector3) -> void:
	if not is_instance_valid(candidate):
		clear()
		return
	memory_remaining = maxf(0.0, memory_remaining - delta)
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = config.perception_interval
		visible_target = can_see(candidate, facing)
		scans += 1
		if visible_target:
			last_known_position = candidate.global_position
			memory_remaining = config.lose_target_delay
			if target != candidate:
				target = candidate
				detected.emit(target)
	if target != null and memory_remaining == 0.0 and not visible_target:
		clear()

func can_see(subject: Node3D, facing: Vector3) -> bool:
	if not is_instance_valid(subject):
		return false
	var offset := subject.global_position - actor.global_position
	if offset.length_squared() > config.detection_range * config.detection_range:
		return false
	var horizontal := Vector3(offset.x, 0, offset.z).normalized()
	if not horizontal.is_zero_approx() and facing.dot(horizontal) < cos(deg_to_rad(config.field_of_view * 0.5)):
		return false
	_ray.from = actor.global_position + Vector3.UP * config.height * 0.75
	_ray.to = subject.damage_point() if subject.has_method("damage_point") else subject.global_position
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(_ray)
	return not hit.is_empty() and hit.collider == subject
