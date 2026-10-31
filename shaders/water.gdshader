shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 deep : source_color = vec3(0.133, 0.655, 0.839);
uniform vec3 shallow : source_color = vec3(0.310, 0.816, 0.933);
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 0.35 + TIME * 1.3) * 0.06 + sin(wp.z * 0.27 + TIME * 1.1) * 0.06;
}
void fragment() {
	float band = sin(wp.x * 0.18 + wp.z * 0.12 + TIME * 0.6) * 0.5 + 0.5;
	vec3 col = mix(deep, shallow, band);
	float caustic = sin(wp.x * 1.3 + TIME) * sin(wp.z * 1.1 - TIME * 0.8) + sin((wp.x + wp.z) * 0.7 + TIME * 0.6);
	ALBEDO = mix(col, vec3(1.0), smoothstep(1.15, 1.45, caustic) * 0.35);
}
