shader_type spatial;
// Cel-shaded rider material: baked vertex colour (with fake AO) as albedo,
// two-band toon diffuse, a soft rim light and a small saturation boost.
// Secondary motion runs here so each rider stays one body draw: masks baked by
// MeshBatch come in UV (x: arm side -1/+1, y: tail) and UV2 (x: butt, y: belly).
// Shared materials leave every motion uniform at zero.
render_mode diffuse_toon, specular_disabled, cull_back;

uniform float saturation = 1.18;
uniform float rim_strength = 0.32;
uniform vec4 rim_color : source_color = vec4(1.0, 0.97, 0.88, 1.0);
// rgb = hot colour, a = glow amount (0 = the animal's own colour).
uniform vec4 butt_tint : source_color = vec4(1.0, 0.22, 0.30, 0.0);
uniform vec3 butt_jiggle = vec3(0.0);
uniform float butt_clench = 0.0;
uniform vec3 belly_jiggle = vec3(0.0);
uniform vec3 shoulder = vec3(0.5, 0.95, 0.3);
uniform vec2 arm_left = vec2(0.0);
uniform vec2 arm_right = vec2(0.0);
uniform vec3 tail_root = vec3(0.0, 0.5, -0.7);
uniform float tail_wag = 0.0;

varying float v_butt;

vec3 turn_x(vec3 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

vec3 turn_z(vec3 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

vec3 turn_y(vec3 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

void vertex() {
	v_butt = UV2.x;
	float side = UV.x;
	if (abs(side) > 0.01) {
		float sign_side = sign(side);
		vec2 arm = sign_side > 0.0 ? arm_right : arm_left;
		vec3 pivot = vec3(shoulder.x * sign_side, shoulder.y, shoulder.z);
		float weight = abs(side);
		vec3 offset = turn_z(turn_x(VERTEX - pivot, -arm.y * weight), arm.x * weight * sign_side);
		NORMAL = turn_z(turn_x(NORMAL, -arm.y * weight), arm.x * weight * sign_side);
		VERTEX = pivot + offset;
	}
	if (UV.y > 0.01) {
		VERTEX = tail_root + turn_y(VERTEX - tail_root, tail_wag * UV.y);
		NORMAL = turn_y(NORMAL, tail_wag * UV.y);
	}
	VERTEX += butt_jiggle * UV2.x + belly_jiggle * UV2.y;
	VERTEX.x *= 1.0 - butt_clench * UV2.x;
}

void fragment() {
	vec3 base = COLOR.rgb;
	float grey = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 albedo = clamp(mix(vec3(grey), base, saturation), 0.0, 1.0);
	float glow = butt_tint.a * smoothstep(0.05, 0.45, v_butt);
	ALBEDO = mix(albedo, butt_tint.rgb, glow * 0.85);
	ROUGHNESS = 1.0;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_color.rgb * fresnel * rim_strength + ALBEDO * 0.08 + butt_tint.rgb * glow * 0.35;
}
