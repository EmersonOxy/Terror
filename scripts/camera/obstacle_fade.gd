class_name ObstacleFade
extends RefCounted

# One cached set per collider. Never mutate shared materials or mesh surfaces.
var amount: float = 0.0
var last_seen: float = -INF
var entries: Array[Dictionary] = []

func _init(body: Node3D) -> void:
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.is_visible_in_tree() or mesh.mesh == null:
			continue
		var originals: Array[Material] = []
		var copies: Array[BaseMaterial3D] = []
		var supported := true
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface)
			if source != null and not source is BaseMaterial3D:
				supported = false
				break
			if source is BaseMaterial3D and source.albedo_color.a < 0.5:
				supported = false
				break
			originals.append(mesh.get_surface_override_material(surface))
			var copy: BaseMaterial3D = source.duplicate() if source else StandardMaterial3D.new()
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			copies.append(copy)
		if supported and not copies.is_empty():
			var entry := {"mesh": weakref(mesh), "override": mesh.material_override, "originals": originals, "copies": copies, "alpha": copies.map(func(m): return m.albedo_color.a)}
			entries.append(entry)
			mesh.tree_exiting.connect(restore_mesh.bind(mesh, entry))

func apply(value: float) -> void:
	if is_equal_approx(amount, value):
		return
	amount = value
	for entry in entries:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			continue
		if value >= 0.9999:
			restore_mesh(mesh, entry)
		else:
			mesh.material_override = null
			for i in entry.copies.size():
				var material: BaseMaterial3D = entry.copies[i]
				var color := material.albedo_color
				color.a = entry.alpha[i] * value
				material.albedo_color = color
				mesh.set_surface_override_material(i, material)

func restore() -> void:
	apply(1.0)

func restore_mesh(mesh: MeshInstance3D, entry: Dictionary) -> void:
	mesh.material_override = entry.override
	for i in entry.originals.size():
		mesh.set_surface_override_material(i, entry.originals[i])

func has_visible_meshes(camera_mask: int) -> bool:
	for entry in entries:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and mesh.is_visible_in_tree() and mesh.layers & camera_mask:
			return true
	return false
