shader_type spatial;
// Stylized canyon walls under the route banks (unshaded, light faked from the face direction).
// UV.x = distance along the route, UV.y = metres below the bank top.
render_mode unshaded, cull_disabled;
uniform vec4 cliff_tint : source_color = vec4(1.0);
uniform vec3 sun_direction = vec3(-0.35, 0.75, 0.55);
uniform vec3 haze : source_color = vec3(0.80, 0.93, 0.99);
varying float v_light;

void vertex() {
	vec3 normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 sun = normalize(vec3(sun_direction.x, 0.0, sun_direction.z));
	float facing = dot(normal, sun);
	v_light = 0.84 + 0.24 * max(facing, 0.0) - 0.12 * max(-facing, 0.0);
}

void fragment() {
	float depth = UV.y;
	float bend = sin(UV.x * 0.12) * 0.16 + sin(UV.x * 0.031 + 1.7) * 0.35;
	float band = fract(depth * 0.27 + bend);
	vec3 color = mix(vec3(0.85, 0.34, 0.34), vec3(0.96, 0.46, 0.40), step(0.5, band));
	color *= 1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.05, abs(band - 0.5)));
	color = mix(color * 1.14, color, smoothstep(0.0, 0.8, depth));
	color *= v_light * mix(1.0, 0.80, smoothstep(0.8, 7.0, depth));
	color = mix(color, haze, smoothstep(7.0, 30.0, depth));
	ALBEDO = color * cliff_tint.rgb;
}
