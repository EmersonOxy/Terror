class_name InteractionComponent
extends Node

signal target_changed(target: Interactable)
var current: Interactable
var actor: CharacterBody3D
var config: PlayerConfig
var _query: PhysicsShapeQueryParameters3D

func setup(player: CharacterBody3D, settings: PlayerConfig) -> void:
	actor = player
	config = settings
	_query = PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = config.interaction_range
	_query.shape = sphere
	_query.collision_mask = 4
	_query.collide_with_areas = true
	_query.collide_with_bodies = false

func tick(facing: Vector3, enabled: bool) -> void:
	var best: Interactable = null
	var score := -INF
	if enabled:
		_query.transform = Transform3D(Basis.IDENTITY, actor.global_position + Vector3.UP * 0.7)
		for result in actor.get_world_3d().direct_space_state.intersect_shape(_query, 32):
			var candidate := result.collider as Interactable
			if candidate == null or not candidate.can_interact(actor):
				continue
			var offset := candidate.global_position - _query.transform.origin
			if offset.length() > config.interaction_range:
				continue
			var flat := Vector3(offset.x, 0.0, offset.z)
			var alignment := facing.dot(flat.normalized())
			if flat.length() > 0.3 and alignment < config.interaction_dot:
				continue
			var ray := PhysicsRayQueryParameters3D.create(_query.transform.origin, candidate.global_position, 1, [actor.get_rid()])
			if not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				continue
			var rank := candidate.interaction_priority * 10.0 + alignment - offset.length()
			if rank > score:
				best = candidate
				score = rank
	if current != best:
		current = best
		target_changed.emit(current)
	if enabled and is_instance_valid(current) and Input.is_action_just_pressed("interact"):
		current.interact(actor)
