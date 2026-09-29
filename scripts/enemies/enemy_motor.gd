class_name EnemyMotor
extends Node

@export var movement: MovementComponent
@export var agent: NavigationAgent3D
var actor: CharacterBody3D
var config: EnemyDefinition
var direction: Vector3 = Vector3.FORWARD
var path_updates: int = 0
var _goal: Vector3
var _has_goal: bool = false
var _remaining: float = 0.0

func setup(body: CharacterBody3D, collider: CollisionShape3D, settings: EnemyDefinition) -> void:
	actor = body
	config = settings
	# Reuse approved physical movement/step solver without changing Player settings.
	var physics := PlayerConfig.new()
	physics.walk_speed = config.walk_speed
	physics.sprint_speed = config.chase_speed
	physics.acceleration = config.acceleration
	physics.deceleration = config.deceleration
	physics.gravity = config.gravity
	physics.radius = config.radius
	physics.standing_height = config.height
	physics.step_height = config.step_height
	physics.floor_snap = config.floor_snap
	movement.setup(actor, collider, physics)
	agent.path_desired_distance = config.waypoint_distance
	agent.target_desired_distance = config.waypoint_distance
	agent.radius = config.radius
	agent.height = config.height

func stop() -> void:
	_has_goal = false
	direction = Vector3.ZERO
	actor.velocity.x = 0.0
	actor.velocity.z = 0.0

func tick(delta: float, destination: Variant, chasing: bool) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	direction = Vector3.ZERO
	if destination != null and NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0:
		var goal: Vector3 = destination
		if not _has_goal or (_remaining == 0.0 and _goal.distance_to(goal) > config.destination_threshold):
			_goal = goal
			_has_goal = true
			_remaining = config.path_update_interval
			agent.target_position = goal
			path_updates += 1
		var next := agent.get_next_path_position()
		if not agent.is_navigation_finished():
			direction = Vector3(next.x - actor.global_position.x, 0, next.z - actor.global_position.z).normalized()
	else:
		_has_goal = false
	movement.tick(delta, direction, false, chasing, true)
