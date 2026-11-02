class_name MeshBatch
extends RefCounted

static func bake(root: Node3D) -> MeshInstance3D:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	append_children(root, root, builder)
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = builder.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85
	result.material_override = material
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(result)
	return result

static func append_children(root: Node3D, node: Node3D, builder: SurfaceTool) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var transform: Transform3D = root.global_transform.affine_inverse() * node.global_transform
		var color: Color = Color.WHITE
		if node.material_override is StandardMaterial3D:
			color = node.material_override.albedo_color
		for surface: int in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for vertex: int in range(indices.size() if not indices.is_empty() else vertices.size()):
				var index: int = indices[vertex] if not indices.is_empty() else vertex
				builder.set_color(color)
				builder.set_normal((transform.basis.inverse().transposed() * normals[index]).normalized())
				builder.add_vertex(transform * vertices[index])
		node.hide()
	for child: Node in node.get_children():
		if child is Node3D:
			append_children(root, child, builder)
