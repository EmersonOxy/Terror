class_name InventoryPanel
extends PanelContainer

var actions: ItemActions
var selected_index: int = -1
var selected_equipment: ItemDefinition.EquipSlot = ItemDefinition.EquipSlot.NONE
var slot_buttons: Array[Button] = []
var equip_buttons: Dictionary = {}
var grid: GridContainer
var capacity_label: Label
var synergy_label: Label
var details: Label
var message: Label
var use_button: Button
var equip_button: Button
var unequip_button: Button
var drop_button: Button

func setup(controller: ItemActions) -> void:
	actions = controller
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.075, 0.085, 0.095, 0.96)
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
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title := Label.new()
	title.text = "INVENTÁRIO    TAB segurar · I fixar"
	title.add_theme_font_size_override("font_size", 17)
	column.add_child(title)
	synergy_label = Label.new()
	synergy_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	column.add_child(synergy_label)
	var equipment := HBoxContainer.new()
	equipment.add_theme_constant_override("separation", 8)
	column.add_child(equipment)
	for slot in EquipmentComponent.SLOTS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 66)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(select_equipment.bind(slot))
		equipment.add_child(button)
		equip_buttons[slot] = button
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	column.add_child(spacer)
	capacity_label = Label.new()
	column.add_child(capacity_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 238)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	details = Label.new()
	details.custom_minimum_size = Vector2(0, 116)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	use_button = action_button(buttons, "Usar", _use)
	equip_button = action_button(buttons, "Equipar", _equip)
	unequip_button = action_button(buttons, "Desequipar", _unequip)
	drop_button = action_button(buttons, "Largar stack", _drop)
	message = Label.new()
	message.custom_minimum_size.y = 42
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
	button.custom_minimum_size = Vector2(160, 34)
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
			button.custom_minimum_size = Vector2(0, 34)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.pressed.connect(select_inventory.bind(i))
			grid.add_child(button)
			slot_buttons.append(button)
	capacity_label.text = "MOCHILA %d / %d slots" % [actions.inventory.occupied_slots(), actions.inventory.capacity()]
	for i in slot_buttons.size():
		var item := actions.inventory.get_slot(i)
		slot_buttons[i].text = "%d · %s" % [i + 1, item_text(item)]
		slot_buttons[i].modulate = Color(0.7, 0.85, 0.8) if selected_index == i else Color.WHITE
	var b_resolver = actions.actor.build_resolver if actions.actor and "build_resolver" in actions.actor else null
	var synergy_name: String = String(b_resolver.active_build.display_name) if (b_resolver and b_resolver.active_build) else "INATIVA"
	synergy_label.text = "SINERGIA: " + synergy_name
	
	for slot in EquipmentComponent.SLOTS:
		var item := actions.equipment.get_equipped(slot)
		var equipped_text := item_text(item)
		var weight := ("[%s] " % ItemDefinition.WeightClass.keys()[item.definition.weight_class]) if item else ""
		equip_buttons[slot].text = ItemDefinition.EquipSlot.keys()[slot] + "\n" + weight + (equipped_text.left(12) + "…" if equipped_text.length() > 13 else equipped_text)
		equip_buttons[slot].tooltip_text = equipped_text
		equip_buttons[slot].modulate = Color(0.7, 0.85, 0.8) if selected_equipment == slot else Color.WHITE
	var item := actions.equipment.get_equipped(selected_equipment) if selected_equipment != ItemDefinition.EquipSlot.NONE else actions.inventory.get_slot(selected_index)
	use_button.visible = false
	equip_button.visible = false
	unequip_button.visible = false
	drop_button.visible = false
	if item == null:
		details.text = "Selecione um item na mochila ou nos equipamentos.
Armaduras ainda não fornecem atributos."
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
