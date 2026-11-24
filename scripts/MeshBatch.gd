class_name MeshBatch
extends RefCounted

# `skip` subtrees are left alone (baked separately so they can move).
# `ao` darkens low and downward-facing vertices as cheap baked ambient occlusion.
# `masks` also bakes the rider-shader masks: UV = (arm side, tail) and UV2 = (butt, belly),
# taken from a part's "mask" meta (Vector4) or, for UV2, from the source mesh itself.
# A source mesh's own vertex colours multiply the material colour (sculpted shading).
static func bake(root: Node3D, skip: Array[Node] = [], ao: bool = false, masks: bool = false) -> MeshInstance3D:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	append_children(root, root, builder, skip, ao, masks)
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = builder.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85
	result.material_override = material
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(result)
	return result

static func append_children(root: Node3D, node: Node3D, builder: SurfaceTool, skip: Array[Node] = [], ao: bool = false, masks: bool = false) -> void:
	if node != root and node in skip:
		return
	if node is MeshInstance3D and node.mesh != null:
		var transform: Transform3D = root.global_transform.affine_inverse() * node.global_transform
		var color: Color = Color.WHITE
		if node.material_override is StandardMaterial3D:
			color = node.material_override.albedo_color
		var mask: Vector4 = node.get_meta("mask", Vector4.ZERO)
		for surface: int in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var mask_uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
			for vertex: int in range(indices.size() if not indices.is_empty() else vertices.size()):
				var index: int = indices[vertex] if not indices.is_empty() else vertex
				var normal: Vector3 = (transform.basis.inverse().transposed() * normals[index]).normalized()
				var position: Vector3 = transform * vertices[index]
				var shade: Color = color * colors[index] if not colors.is_empty() else color
				if ao:
					var occlusion: float = lerpf(0.62, 1.0, 0.5 + 0.5 * normal.y) * clampf(0.74 + position.y * 0.2, 0.74, 1.0)
					shade = Color(shade.r * occlusion, shade.g * occlusion, shade.b * occlusion, color.a)
				builder.set_color(shade)
				if masks:
					builder.set_uv(Vector2(mask.x, mask.y))
					builder.set_uv2(mask_uv2[index] if not mask_uv2.is_empty() else Vector2(mask.z, mask.w))
				builder.set_normal(normal)
				builder.add_vertex(position)
		node.hide()
	for child: Node in node.get_children():
		if child is Node3D:
			append_children(root, child, builder, skip, ao, masks)
