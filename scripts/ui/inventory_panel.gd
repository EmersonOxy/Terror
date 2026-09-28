class_name InventoryPanel
extends PanelContainer

var actions: ItemActions
var selected_index: int = -1
var selected_equipment: ItemDefinition.EquipSlot = ItemDefinition.EquipSlot.NONE
var slot_buttons: Array[Button] = []
var equip_buttons: Dictionary = {}
var grid: GridContainer
var capacity_label: Label
var details: Label
var message: Label
var use_button: Button
var equip_button: Button
var unequip_button: Button
var drop_button: Button

func setup(controller: ItemActions) -> void:
	actions = controller
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.075, 0.085, 0.095, 1.0)
	background.set_border_width_all(1)
	background.border_color = Color(0.28, 0.31, 0.34)
	add_theme_stylebox_override("panel", background)
	var button_theme := Theme.new()
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.13, 0.15, 0.17, 1.0)
	button_style.set_border_width_all(1)
	button_style.border_color = Color(0.24, 0.27, 0.29)
	button_theme.set_stylebox("normal", "Button", button_style)
	theme = button_theme
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "INVENTÁRIO / DEBUG                            I ou Esc para fechar"
	title.add_theme_font_size_override("font_size", 21)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	var backpack := VBoxContainer.new()
	backpack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(backpack)
	capacity_label = Label.new()
	backpack.add_child(capacity_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 195)
	backpack.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	scroll.add_child(grid)
	var equipment := VBoxContainer.new()
	equipment.custom_minimum_size.x = 275
	row.add_child(equipment)
	var equip_title := Label.new()
	equip_title.text = "EQUIPAMENTOS (fora da mochila)"
	equipment.add_child(equip_title)
	for slot in EquipmentComponent.SLOTS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(275, 48)
		button.pressed.connect(select_equipment.bind(slot))
		equipment.add_child(button)
		equip_buttons[slot] = button
	details = Label.new()
	details.custom_minimum_size = Vector2(770, 105)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	use_button = action_button(buttons, "Usar", _use)
	equip_button = action_button(buttons, "Equipar", _equip)
	unequip_button = action_button(buttons, "Desequipar", _unequip)
	drop_button = action_button(buttons, "Largar stack", _drop)
	message = Label.new()
	message.custom_minimum_size.y = 25
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	actions.inventory.inventory_changed.connect(refresh)
	actions.equipment.equipment_changed.connect(refresh)
	actions.feedback.connect(func(text: String): message.text = text)
	actions.status.health_changed.connect(func(_value: float, _max: float): refresh())
	actions.status.died.connect(refresh)
	refresh()

func action_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 38)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func refresh() -> void:
	if slot_buttons.size() != actions.inventory.capacity():
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		slot_buttons.clear()
		for i in actions.inventory.capacity():
			var button := Button.new()
			button.custom_minimum_size = Vector2(225, 48)
			button.pressed.connect(select_inventory.bind(i))
			grid.add_child(button)
			slot_buttons.append(button)
	capacity_label.text = "MOCHILA %d / %d slots" % [actions.inventory.occupied_slots(), actions.inventory.capacity()]
	for i in slot_buttons.size():
		var item := actions.inventory.get_slot(i)
		slot_buttons[i].text = "%d · %s" % [i + 1, item_text(item)]
		slot_buttons[i].modulate = Color(0.7, 0.85, 0.8) if selected_index == i else Color.WHITE
	for slot in EquipmentComponent.SLOTS:
		equip_buttons[slot].text = ItemDefinition.EquipSlot.keys()[slot] + ": " + item_text(actions.equipment.get_equipped(slot))
		equip_buttons[slot].modulate = Color(0.7, 0.85, 0.8) if selected_equipment == slot else Color.WHITE
	var item := actions.equipment.get_equipped(selected_equipment) if selected_equipment != ItemDefinition.EquipSlot.NONE else actions.inventory.get_slot(selected_index)
	use_button.visible = false
	equip_button.visible = false
	unequip_button.visible = false
	drop_button.visible = false
	if item == null:
		details.text = "Selecione um item na mochila ou nos equipamentos.
Equipamentos não fornecem atributos neste milestone."
		return
	details.text = "%s x%d\n%s\nCategoria: %s | Peso: %s | Slot: %s" % [item.definition.display_name, item.quantity, item.definition.description, ItemDefinition.Category.keys()[item.definition.category], ItemDefinition.WeightClass.keys()[item.definition.weight_class], ItemDefinition.EquipSlot.keys()[item.definition.equip_slot]]
	var equipped := selected_equipment != ItemDefinition.EquipSlot.NONE
	use_button.visible = not equipped and item.definition.use_effect != null
	use_button.disabled = not actions.can_use(selected_index)
	equip_button.visible = not equipped and item.definition.equip_slot != ItemDefinition.EquipSlot.NONE
	unequip_button.visible = equipped
	drop_button.visible = not equipped
	for button in [equip_button, unequip_button, drop_button]:
		button.disabled = actions.status.dead

func item_text(item: ItemInstance) -> String:
	return "%s x%d" % [item.definition.display_name, item.quantity] if item != null else "vazio"

func select_inventory(index: int) -> void:
	selected_index = index
	selected_equipment = ItemDefinition.EquipSlot.NONE
	refresh()

func select_equipment(slot: ItemDefinition.EquipSlot) -> void:
	selected_index = -1
	selected_equipment = slot
	refresh()

func _use() -> void:
	actions.use(selected_index)

func _equip() -> void:
	var item := actions.inventory.get_slot(selected_index)
	if item != null:
		actions.equip(selected_index, item.definition.equip_slot)

func _unequip() -> void:
	actions.unequip(selected_equipment)

func _drop() -> void:
	actions.drop(selected_index)
