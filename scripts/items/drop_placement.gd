class_name DropPlacement
extends RefCounted

const RADIUS: float = 0.18

static func find_position(actor: CharacterBody3D, forward: Vector3) -> Variant:
	var space := actor.get_world_3d().direct_space_state
	var start := actor.global_position + Vector3.UP * 0.7
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [actor.get_rid()]
	for angle in [0.0, PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0, PI]:
		for distance in [1.0, 0.55]:
			var ahead: Vector3 = start + forward.normalized().rotated(Vector3.UP, angle) * distance
			var ray := PhysicsRayQueryParameters3D.create(start, ahead, 1, [actor.get_rid()])
			if not space.intersect_ray(ray).is_empty():
				continue
			ray.from = ahead
			ray.to = ahead + Vector3.DOWN * 1.5
			var floor_hit := space.intersect_ray(ray)
			if floor_hit.is_empty() or floor_hit.normal.dot(Vector3.UP) < cos(actor.floor_max_angle):
				continue
			var position: Vector3 = floor_hit.position + floor_hit.normal * (RADIUS + 0.005)
			ray.from = start
			ray.to = position
			if not space.intersect_ray(ray).is_empty():
				continue
			query.transform = Transform3D(Basis.IDENTITY, position)
			if space.intersect_shape(query, 1).is_empty():
				return position
	return null
