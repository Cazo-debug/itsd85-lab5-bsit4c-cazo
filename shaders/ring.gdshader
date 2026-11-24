shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool filled = false;
// 0 = clean disc/ring (shadows, highlights); 1 = lumpy, broken cartoon foam ring.
uniform float wobble = 0.0;
varying float v_seed;

void vertex() {
	v_seed = float(INSTANCE_ID) * 1.618;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	// Lumps and gaps from cheap planar waves (no per-pixel atan: these quads cover a lot of screen).
	float lumps = sin(p.x * 23.0 + v_seed * 3.0) * sin(p.y * 19.0 - v_seed * 2.0);
	float radius = length(p) * 2.0 + wobble * 0.05 * lumps;
	float edge = 1.0 - smoothstep(0.82, 0.94, radius);
	float hole = filled ? 1.0 : smoothstep(0.60, 0.74, radius);
	float gaps = filled ? 1.0 : mix(1.0, smoothstep(-0.35, 0.35, sin((p.x - p.y) * 17.0 + v_seed * 7.0)), wobble * 0.55);
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = edge * hole * gaps * tint.a * COLOR.a;
}
