shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 sand : source_color = vec3(1.0, 0.635, 0.298);
uniform vec3 strata_a : source_color = vec3(0.914, 0.51, 0.227);
uniform vec3 strata_b : source_color = vec3(0.965, 0.6, 0.33);
uniform vec3 haze : source_color = vec3(0.88, 0.96, 1.0);
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 col = wp.y > -0.4 ? sand : mix(strata_a, strata_b, step(0.5, fract(wp.y * 0.22)));
	float light = 0.62 + 0.38 * max(dot(normalize(wn), normalize(vec3(-0.4, 0.8, 0.35))), 0.0);
	col *= light;
	// Ascending edges avoid undefined reversed smoothstep behavior on mobile GPUs.
	col = mix(col, haze, smoothstep(3.0, 42.0, -wp.y) * 0.9);
	ALBEDO = col;
}
