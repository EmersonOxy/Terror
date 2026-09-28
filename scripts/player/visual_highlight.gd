class_name VisualHighlight
extends RefCounted

const SHADER := preload("res://resources/camera/obstruction_highlight.gdshader")
var entries: Array[Dictionary] = []
var strength: float = 0.0

func setup(root: Node3D) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.render_priority = 10
		material.next_pass = mesh.material_overlay
		entries.append({"mesh": weakref(mesh), "original": mesh.material_overlay, "effect": material})

func apply(value: float) -> void:
	if is_equal_approx(strength, value):
		return
	strength = value
	for entry in entries:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			continue
		entry.effect.set_shader_parameter("strength", value)
		mesh.material_overlay = entry.effect if value > 0.001 else entry.original
