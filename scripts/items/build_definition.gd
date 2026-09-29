class_name BuildDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var required_weight_class: ItemDefinition.WeightClass = ItemDefinition.WeightClass.NONE
@export_multiline var description: String
@export var modifiers: Array = []
