extends CanvasLayer

@export var player: Player
@export var cameras: CameraSystem
@export var backdrop: Control
@export var panel: InventoryPanel
@export var toast: Label
var is_open: bool = false
var held_by_tab: bool = false
var pinned_by_i: bool = false
var _previous_mouse: Input.MouseMode
var _toast_time: float = 0.0

func _ready() -> void:
	panel.setup(player.items)
	backdrop.hide()
	player.items.feedback.connect(_feedback)

func _input(event: InputEvent) -> void:
	if event.is_action("inventory_hold") and not event.is_echo():
		held_by_tab = event.is_pressed()
	elif event.is_action_pressed("inventory_toggle"):
		pinned_by_i = not pinned_by_i
	elif is_open and event.is_action_pressed("release_mouse"):
		pinned_by_i = false
	else:
		return
	_apply_open(held_by_tab or pinned_by_i)
	get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	pinned_by_i = value
	_apply_open(held_by_tab or pinned_by_i)

func _apply_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	player.controls_locked = value
	cameras.controls_locked = value
	backdrop.visible = value
	if value:
		player.combat.tick(0.0, false)
		_previous_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		player.interaction.tick(player.movement.facing, false)
		panel.refresh()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if cameras.mode == "Isometrica" else _previous_mouse

func _feedback(text: String) -> void:
	toast.text = text
	_toast_time = 3.0

func _process(delta: float) -> void:
	_toast_time = maxf(0.0, _toast_time - delta)
	toast.visible = not is_open and _toast_time > 0.0

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.controls_locked = false
	if is_instance_valid(cameras):
		cameras.controls_locked = false
