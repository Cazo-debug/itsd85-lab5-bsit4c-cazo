shader_type spatial;
// Pennant flags along the banks (decor only, one MultiMesh). UV.x = 0 at the pole -> 1 at
// the tip; the tip flutters more. Colour comes from the MultiMesh instance colour.
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform float flutter = 1.0;

void vertex() {
	float phase = MODEL_MATRIX[3].x * 0.31 + MODEL_MATRIX[3].z * 0.17;
	float along = UV.x;
	VERTEX.z += sin(TIME * 7.0 - along * 5.0 + phase) * 0.20 * along * flutter;
	VERTEX.y += sin(TIME * 4.6 - along * 3.5 + phase) * 0.05 * along * flutter;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	EMISSION = COLOR.rgb * 0.12;
}
