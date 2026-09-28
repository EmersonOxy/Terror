class_name CameraSystem
extends Node3D

signal mode_changed(mode_name: String)
@export var config: CameraConfig
@export var target: CharacterBody3D
@export var orbit: Node3D
@export var arm: SpringArm3D
@export var third: Camera3D
@export var iso: Camera3D
@export var occlusion: IsometricOcclusion
var controls_locked: bool = false
var mode: String = "Terceira pessoa"
var yaw: float = 0.0
var pitch: float = -0.22
var focus_height: float = 1.35
var _anchor: Vector3

func _ready() -> void:
	occlusion.target = target
	_anchor = target.global_position
	focus_height = config.height
	arm.spring_length = config.distance
	arm.add_excluded_object(target.get_rid())
	iso.projection = Camera3D.PROJECTION_ORTHOGONAL if config.iso_orthographic else Camera3D.PROJECTION_PERSPECTIVE
	iso.size = config.iso_zoom
	set_mode(false)

func movement_orientation() -> Basis:
	return Basis(Vector3.UP, deg_to_rad(config.iso_yaw) if mode == "Isometrica" else yaw)

func set_mode(isometric: bool) -> void:
	if not isometric:
		occlusion.reset()
	mode = "Isometrica" if isometric else "Terceira pessoa"
	iso.current = isometric
	third.current = not isometric
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if isometric else Input.MOUSE_MODE_CAPTURED
	mode_changed.emit(mode)

func _unhandled_input(event: InputEvent) -> void:
	if controls_locked:
		return
	if event.is_action_pressed("camera_third_person"):
		set_mode(false)
	elif event.is_action_pressed("camera_isometric"):
		set_mode(true)
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and mode == "Terceira pessoa" and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * config.sensitivity
		pitch = clampf(pitch - event.relative.y * config.sensitivity, deg_to_rad(config.min_pitch), deg_to_rad(config.max_pitch))

func _physics_process(delta: float) -> void:
	_anchor = _anchor.lerp(target.global_position, 1.0 - exp(-config.follow_speed * delta))
	global_position = _anchor
	orbit.position = Vector3.UP * focus_height
	orbit.rotation = Vector3(pitch, yaw, 0.0)
	# Sweep the shoulder offset too, so the spring origin never crosses a wall.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = arm.shape
	query.transform = Transform3D(Basis.IDENTITY, orbit.global_position)
	query.motion = orbit.global_basis.x * config.shoulder
	query.collision_mask = 1
	query.exclude = [target.get_rid()]
	var fractions := get_world_3d().direct_space_state.cast_motion(query)
	arm.position.x = config.shoulder * fractions[0]
	iso.rotation_degrees = Vector3(config.iso_pitch, config.iso_yaw, 0.0)
	iso.position = Vector3.UP * config.iso_height + iso.basis.z * config.iso_distance
