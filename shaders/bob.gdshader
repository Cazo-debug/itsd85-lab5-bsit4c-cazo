shader_type spatial;
// Floating decor (hot-air and party balloons), one MultiMesh per part. INSTANCE_CUSTOM:
// x = phase (shared by the parts of one balloon), y = bob height, z = extra speed.
// Colour comes from the MultiMesh instance colour. Decor only: never touches gameplay.
render_mode diffuse_toon, specular_disabled, world_vertex_coords;

void vertex() {
	float phase = INSTANCE_CUSTOM.x;
	float amount = INSTANCE_CUSTOM.y;
	VERTEX.y += sin(TIME * (0.55 + INSTANCE_CUSTOM.z) + phase) * amount;
	VERTEX.x += sin(TIME * 0.37 + phase * 1.3) * amount * 0.35;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.8;
	EMISSION = COLOR.rgb * 0.10;
}
