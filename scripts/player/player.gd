class_name Player
extends CharacterBody3D

@export var config: PlayerConfig
@export var collider: CollisionShape3D
@export var visual: CharacterVisual
@export var movement: MovementComponent
@export var status: StatusComponent
@export var interaction: InteractionComponent

# Injected by the scene composition root; no camera dependency.
var movement_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	status.setup(config)
	movement.setup(self, collider, config)
	interaction.setup(self, config)

func _physics_process(delta: float) -> void:
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := movement_basis * Vector3(axis.x, 0.0, axis.y)
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized() * axis.length()
	movement.tick(delta, direction, Input.is_action_pressed("crouch"), Input.is_action_pressed("sprint") and status.can_sprint(), not status.dead)
	status.tick(delta, movement.sprinting)
	interaction.tick(movement.facing, not status.dead)
	if is_instance_valid(visual):
		var height_ratio := config.crouching_height / config.standing_height if movement.crouched else 1.0
		visual.present(movement.facing, height_ratio, status.dead, delta, config.turn_speed)

func receive_damage(amount: float) -> void:
	status.damage(amount)

func recover_health(amount: float) -> void:
	status.heal(amount)
