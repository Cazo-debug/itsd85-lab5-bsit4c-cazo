shader_type spatial;
render_mode unshaded, cull_disabled;

varying vec2 world_water;

void vertex() {
	world_water = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	VERTEX.y += sin(world_water.y * 0.9 + TIME * 1.2) * 0.045;
	VERTEX.y += cos(world_water.x * 1.3 + TIME * 0.8) * 0.025;
}

void fragment() {
	float wave = sin(world_water.y * 2.5 + sin(world_water.x * 1.2) * 1.3 - TIME * 0.9);
	float bands = smoothstep(0.75, 0.95, wave);
	float glint = smoothstep(0.97, 1.0, sin(world_water.x * 3.8 + world_water.y * 1.6 + TIME));
	ALBEDO = mix(vec3(0.10, 0.68, 0.82), vec3(0.30, 0.83, 0.89), bands * 0.65);
	ALBEDO = mix(ALBEDO, vec3(0.74, 0.97, 0.98), glint * bands * 0.45);
}
