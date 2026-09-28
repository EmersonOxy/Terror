class_name Player
extends CharacterBody3D

@export var config: PlayerConfig
@export var collider: CollisionShape3D
@export var visual: CharacterVisual
@export var movement: MovementComponent
@export var status: StatusComponent
@export var interaction: InteractionComponent
@export var inventory: InventoryComponent
@export var equipment: EquipmentComponent
@export var items: ItemActions
var controls_locked: bool = false

# Injected by the scene composition root; no camera dependency.
var movement_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	status.setup(config)
	movement.setup(self, collider, config)
	interaction.setup(self, config)

func _physics_process(delta: float) -> void:
	var axis := Vector2.ZERO if controls_locked else Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := movement_basis * Vector3(axis.x, 0.0, axis.y)
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		direction = direction.normalized() * axis.length()
	if controls_locked:
		velocity.x = 0.0
		velocity.z = 0.0
	var crouch_intent := movement.crouched if controls_locked else Input.is_action_pressed("crouch")
	movement.tick(delta, direction, crouch_intent, not controls_locked and Input.is_action_pressed("sprint") and status.can_sprint(), not status.dead)
	status.tick(delta, movement.sprinting)
	interaction.tick(movement.facing, not status.dead and not controls_locked)
	items.drop_direction = movement.facing
	if is_instance_valid(visual):
		var height_ratio := config.crouching_height / config.standing_height if movement.crouched else 1.0
		visual.present(movement.facing, height_ratio, status.dead, delta, config.turn_speed)

func receive_damage(amount: float) -> void:
	status.damage(amount)

func recover_health(amount: float) -> void:
	status.heal(amount)

func collect_item(item: ItemInstance) -> int:
	return items.collect(item) if not controls_locked else 0
