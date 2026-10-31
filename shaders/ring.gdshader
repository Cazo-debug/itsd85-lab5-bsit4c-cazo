shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool filled = false;

void fragment() {
	float radius = length(UV - vec2(0.5)) * 2.0;
	float edge = 1.0 - smoothstep(0.83, 1.0, radius);
	float hole = filled ? 1.0 : smoothstep(0.62, 0.77, radius);
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = edge * hole * tint.a * COLOR.a;
}
