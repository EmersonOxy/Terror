class_name ShopUI
extends CanvasLayer

signal open_changed(is_open: bool)
@export var player: Player
@export var cameras: CameraSystem

var _panel: PanelContainer
var _shop: ShopComponent
var _shop_grid: VBoxContainer
var _inv_grid: VBoxContainer
var _balance_label: Label
var _message_label: Label
var _shop_buttons: Array[Button] = []
var _inv_buttons: Array[Button] = []
var _open: bool = false

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 500)
	_panel.offset_left = -350
	_panel.offset_top = -250
	_panel.offset_right = 350
	_panel.offset_bottom = 250
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.07, 0.08, 0.96)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.3, 0.32, 0.34)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var title := Label.new()
	title.text = "COMÉRCIO"
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 15)
	root.add_child(_balance_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# Shop column
	var shop_col := VBoxContainer.new()
	shop_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(shop_col)
	var shop_title := Label.new()
	shop_title.text = "LOJA"
	shop_title.add_theme_font_size_override("font_size", 16)
	shop_col.add_child(shop_title)
	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_col.add_child(shop_scroll)
	_shop_grid = VBoxContainer.new()
	_shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.add_child(_shop_grid)

	# Inventory column
	var inv_col := VBoxContainer.new()
	inv_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(inv_col)
	var inv_title := Label.new()
	inv_title.text = "INVENTÁRIO (vender)"
	inv_title.add_theme_font_size_override("font_size", 16)
	inv_col.add_child(inv_title)
	var inv_scroll := ScrollContainer.new()
	inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_col.add_child(inv_scroll)
	_inv_grid = VBoxContainer.new()
	_inv_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_scroll.add_child(_inv_grid)

	_message_label = Label.new()
	_message_label.custom_minimum_size.y = 32
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_message_label)

	var close_btn := Button.new()
	close_btn.text = "Fechar [Esc]"
	close_btn.custom_minimum_size = Vector2(120, 34)
	close_btn.pressed.connect(func(): set_open(false))
	root.add_child(close_btn)

func open_shop(shop: ShopComponent) -> void:
	_shop = shop
	_shop.transaction_completed.connect(_on_feedback)
	set_open(true)

func set_open(value: bool) -> void:
	if value == _open:
		return
	_open = value
	visible = _open
	if _open:
		_refresh()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if _shop != null and _shop.transaction_completed.is_connected(_on_feedback):
			_shop.transaction_completed.disconnect(_on_feedback)
		_shop = null
	player.controls_locked = _open
	if cameras:
		cameras.set_mouse_active(not _open)
	open_changed.emit(_open)

func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		set_open(false)
		get_viewport().set_input_as_handled()

func _on_feedback(text: String) -> void:
	_message_label.text = text
	_refresh()

func _refresh() -> void:
	if not _open or _shop == null:
		return
	_balance_label.text = "Saldo: %d" % player.get_node("WalletComponent").balance()

	# Rebuild shop buttons
	for child in _shop_grid.get_children():
		child.queue_free()
	_shop_buttons.clear()
	var entries := _shop.get_entries()
	for i in entries.size():
		var entry := entries[i]
		if entry.item == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		var stock_text := "∞" if entry.stock < 0 else str(entry.available())
		btn.text = "%s — %d ¤ [%s]" % [entry.item.display_name, entry.effective_price(), stock_text]
		btn.disabled = entry.available() <= 0
		btn.pressed.connect(_buy.bind(i))
		_shop_grid.add_child(btn)
		_shop_buttons.append(btn)

	# Rebuild sell buttons
	for child in _inv_grid.get_children():
		child.queue_free()
	_inv_buttons.clear()
	for i in player.inventory.capacity():
		var item := player.inventory.get_slot(i)
		if item == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		var value := _shop.sell_value(item)
		btn.text = "%s x%d → %d ¤" % [item.definition.display_name, item.quantity, value * item.quantity]
		btn.pressed.connect(_sell.bind(i))
		_inv_grid.add_child(btn)
		_inv_buttons.append(btn)

func _buy(index: int) -> void:
	_shop.buy(index)

func _sell(index: int) -> void:
	_shop.sell(index)
