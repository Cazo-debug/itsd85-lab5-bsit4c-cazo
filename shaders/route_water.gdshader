shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 holes[8];
uniform int hole_count = 0;
void fragment() {
	for (int i = 0; i < 8; i++) {
		if (i < hole_count && distance(UV, holes[i].xy) < holes[i].z) { discard; }
	}
	float waves = sin(UV.x * 1.6 - TIME * 2.4 + sin(UV.y * 1.5)) * 0.5 + 0.5;
	float fleck = smoothstep(0.96, 1.0, sin(UV.x * 2.8 - TIME * 3.2) * sin(UV.y * 3.0));
	ALBEDO = mix(vec3(0.10, 0.60, 0.83), vec3(0.22, 0.76, 0.91), waves * 0.30) + vec3(fleck * 0.20);
}
