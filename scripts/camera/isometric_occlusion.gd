class_name IsometricOcclusion
extends Node

@export var camera: Camera3D
@export var config: CameraConfig
var target: CharacterBody3D
var visual: CharacterVisual
var target_height: float = 1.8
var obstruction_count: int = 0
var _capsule := CapsuleShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _cache: Dictionary = {}
var _seen: Dictionary = {}
var _clock: float = 0.0
var _next_query: float = 0.0
var _highlight: float = 0.0
var _running: bool = false

func _ready() -> void:
	_query.shape = _capsule
	_query.collision_mask = 1
	_query.collide_with_areas = false
	process_physics_priority = 10

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not camera.is_current() or not (config.occlusion_enabled or config.highlight_enabled):
		reset()
		return
	_running = true
	_clock += delta
	_next_query -= delta
	if _next_query <= 0.0:
		_next_query = config.occlusion_interval
		_detect()
	obstruction_count = 0
	for id in _cache:
		var fade: ObstacleFade = _cache[id]
		var blocking := _clock - fade.last_seen <= config.occlusion_hold
		if blocking:
			obstruction_count += 1
		var goal := config.obstacle_opacity if blocking and config.occlusion_enabled else 1.0
		var duration := config.fade_out_time if goal < fade.amount else config.restore_time
		fade.apply(move_toward(fade.amount, goal, (1.0 - config.obstacle_opacity) * delta / maxf(duration, 0.001)))
	var highlighted := obstruction_count > 0 and config.highlight_enabled
	_highlight = move_toward(_highlight, config.highlight_intensity if highlighted else 0.0, config.highlight_intensity * delta / maxf(config.fade_out_time if highlighted else config.restore_time, 0.001))
	if is_instance_valid(visual):
		visual.set_obstruction_strength(_highlight)

func _detect() -> void:
	_seen.clear()
	_query.exclude = [target.get_rid()]
	_capsule.radius = config.occlusion_radius
	# Two parallel volumes cover torso and legs; orthographic rays start on
	# the projected camera plane, not at its center (important while following).
	for fraction in [0.32, 0.76]:
		var end := target.global_position + Vector3.UP * maxf(target_height * fraction, config.occlusion_radius + 0.05)
		var start := camera.project_ray_origin(camera.unproject_position(end))
		var segment := end - start
		if segment.length() <= config.occlusion_radius * 2.0:
			continue
		_capsule.height = segment.length() + config.occlusion_radius * 2.0
		var axis := segment.normalized()
		var side := axis.cross(Vector3.RIGHT).normalized()
		_query.transform = Transform3D(Basis(side, axis, side.cross(axis)), (start + end) * 0.5)
		for hit in target.get_world_3d().direct_space_state.intersect_shape(_query, 64):
			var body := hit.collider as Node3D
			if body == null or not body.is_in_group("camera_occluder") or not body.is_visible_in_tree():
				continue
			var id := body.get_instance_id()
			if _seen.has(id):
				continue
			_seen[id] = true
			if not _cache.has(id):
				_cache[id] = ObstacleFade.new(body)
				_cache[id].amount = 1.0
				body.tree_exiting.connect(_release.bind(id), CONNECT_ONE_SHOT)
			var fade: ObstacleFade = _cache[id]
			if fade.has_visible_meshes(camera.cull_mask):
				fade.last_seen = _clock

func _release(id: int) -> void:
	if _cache.has(id):
		_cache[id].restore()
		_cache.erase(id)

func reset() -> void:
	if not _running:
		return
	_running = false
	for fade in _cache.values():
		fade.restore()
		fade.last_seen = -INF
	obstruction_count = 0
	_highlight = 0.0
	_next_query = 0.0
	if is_instance_valid(visual):
		visual.set_obstruction_strength(0.0)

func _exit_tree() -> void:
	reset()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		reset()
