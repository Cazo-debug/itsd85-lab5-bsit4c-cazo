shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.03, 0.49, 0.67);
uniform vec3 shallow_color : source_color = vec3(0.24, 0.85, 0.83);
uniform vec3 foam_color : source_color = vec3(0.93, 1.0, 1.0);
uniform vec3 holes[8];
uniform int hole_count = 0;
uniform float water_time = 0.0;
uniform float wave_amplitude = 0.10;
uniform vec4 wave_a = vec4(0.70, 0.18, 1.8, 1.0);
uniform vec4 wave_b = vec4(1.10, -0.35, -1.2, 0.45);
uniform vec2 ring_uv = vec2(-100.0);
uniform vec2 wake_velocity = vec2(0.0);
uniform bool ring_supported = false;
varying vec3 flow_view;
varying vec3 lateral_view;

void vertex() {
	float a = dot(UV, wave_a.xy) - water_time * wave_a.z;
	float b = dot(UV, wave_b.xy) - water_time * wave_b.z;
	float h = wave_amplitude * (sin(a) * wave_a.w + sin(b) * wave_b.w);
	vec2 slope = wave_amplitude * (cos(a) * wave_a.w * wave_a.xy + cos(b) * wave_b.w * wave_b.xy);
	vec3 forward = normalize(COLOR.rgb * 2.0 - 1.0);
	vec3 side = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	VERTEX.y += h;
	NORMAL = normalize(cross(side + vec3(0.0, slope.y, 0.0), forward + vec3(0.0, slope.x, 0.0)));
	flow_view = (MODELVIEW_MATRIX * vec4(forward, 0.0)).xyz;
	lateral_view = (MODELVIEW_MATRIX * vec4(side, 0.0)).xyz;
}

void fragment() {
	float hole_foam = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i < hole_count) {
			float edge = distance(UV, holes[i].xy) - holes[i].z;
			if (edge < 0.0) { discard; }
			hole_foam = max(hole_foam, 1.0 - smoothstep(0.04, 0.28, edge));
		}
	}
	vec2 p = vec2(UV.x - water_time * 1.5, UV.y);
	float small_a = sin(p.x * 4.2 + sin(p.y * 2.5));
	float small_b = sin(p.x * 2.8 - p.y * 3.1 + water_time * 0.6);
	NORMAL = normalize(NORMAL - normalize(flow_view) * small_a * 0.095 - normalize(lateral_view) * small_b * 0.075);
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	float band = sin(p.x * 0.8 + sin(p.y * 0.65)) * 0.5 + 0.5;
	float caustic = pow(max(0.0, 1.0 - abs(sin(p.x * 1.7 + cos(p.y * 1.6)) * cos(p.y * 1.9 + sin(p.x * 1.2)))), 20.0);
	float shore_distance = (1.0 - UV2.x) * UV2.y;
	float shore = (1.0 - smoothstep(0.10, 0.50, shore_distance)) * (0.55 + 0.20 * small_b);
	float speed = length(wake_velocity);
	vec2 heading = wake_velocity / max(speed, 0.001);
	vec2 relative = UV - ring_uv;
	float along = dot(relative, heading);
	float across = dot(relative, vec2(-heading.y, heading.x));
	float wake_line = abs(abs(across) - (1.5 - along * 0.23));
	float wake = (1.0 - smoothstep(0.08, 0.45, wake_line)) * smoothstep(0.0, 1.5, -along) * (1.0 - smoothstep(3.0, 11.0, -along));
	float rim = (1.0 - smoothstep(0.08, 0.32, abs(length(relative) - 2.5))) * 0.4;
	float active = ring_supported ? 1.0 : 0.0;
	float foam = clamp(max(shore, hole_foam) + active * (wake * min(speed / 5.0, 0.65) + rim), 0.0, 0.85);
	vec3 base = mix(deep_color, shallow_color, 0.25 + band * 0.20 + fresnel * 0.35);
	base += vec3(0.08, 0.16, 0.12) * caustic;
	ALBEDO = mix(base, foam_color, foam);
	ROUGHNESS = mix(0.20, 0.60, foam);
	SPECULAR = 0.65;
	METALLIC = 0.03;
}
