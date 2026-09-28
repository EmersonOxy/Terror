class_name CameraAimProvider
extends AimProvider

@export var actor: CollisionObject3D
var camera: Camera3D
var use_cursor: bool = false
@export var query_distance: float = 150.0

func sample(origin: Vector3, facing: Vector3, aiming: bool) -> AimSample:
	if not is_instance_valid(camera) or (not use_cursor and not aiming):
		return super.sample(origin, facing, false)
	var screen := camera.get_viewport().get_mouse_position() if use_cursor else camera.get_viewport().get_visible_rect().size * 0.5
	var start := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var query := PhysicsRayQueryParameters3D.create(start, start + direction * query_distance, 9, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit.position if not hit.is_empty() else start + direction * query_distance
	if hit.is_empty() and use_cursor:
		var plane_hit: Variant = Plane(Vector3.UP, origin.y).intersects_ray(start, direction)
		if plane_hit != null:
			target = plane_hit
	# The shot always starts at the actor; this camera ray never deals damage.
	return AimSample.new(origin, target, true)
