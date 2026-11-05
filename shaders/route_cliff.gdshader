shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 cliff_tint : source_color = vec4(1.0);
void fragment() {
	float strata = step(0.5, fract(UV.y * 0.27 + sin(UV.x * 0.12) * 0.16));
	vec3 color = mix(vec3(0.85, 0.34, 0.34), vec3(0.96, 0.46, 0.40), strata);
	color = mix(color, vec3(0.77, 0.91, 0.97), smoothstep(7.0, 30.0, UV.y));
	ALBEDO = color * cliff_tint.rgb;
}
