shader_type spatial;
// Stylized route water. Unshaded on purpose: the lit version cost ~21 ms per frame on
// the Mali-G57 MP1 test phone. Light, fresnel and glints are faked here instead.
// UV = (distance along route, lateral metres); UV2 = (|lateral| / half width, half width);
// COLOR = route tangent. The waves match WaterStyle.displacement (physics support).
render_mode unshaded, cull_disabled;

uniform vec3 deep_color : source_color = vec3(0.03, 0.49, 0.67);
uniform vec3 shallow_color : source_color = vec3(0.24, 0.85, 0.83);
uniform vec3 foam_color : source_color = vec3(0.93, 1.0, 1.0);
// R caustic web, G flow streaks, B foam noise, A sparkle dots (RaceEffects.water_pattern).
uniform sampler2D pattern : filter_linear_mipmap, repeat_enable;
// 1 = High quality (second caustic layer, streaks, sparkles); 0 = Low.
uniform float detail = 1.0;
uniform vec3 holes[8];
uniform int hole_count = 0;
// Nearby obstacle bases in route space (s, lateral, radius), refreshed from Level.race_time.
uniform vec3 obstacles[4];
uniform int obstacle_count = 0;
uniform float water_time = 0.0;
uniform float wave_amplitude = 0.10;
uniform vec4 wave_a = vec4(0.70, 0.18, 1.8, 1.0);
uniform vec4 wave_b = vec4(1.10, -0.35, -1.2, 0.45);
uniform vec2 ring_uv = vec2(-100.0);
uniform vec2 wake_velocity = vec2(0.0);
uniform bool ring_supported = false;
uniform vec3 sun_direction = vec3(-0.35, 0.75, 0.55);

varying float v_shade;
varying float v_crest;
varying float v_glint;

void vertex() {
	float a = dot(UV, wave_a.xy) - water_time * wave_a.z;
	float b = dot(UV, wave_b.xy) - water_time * wave_b.z;
	float h = wave_amplitude * (sin(a) * wave_a.w + sin(b) * wave_b.w);
	vec2 slope = wave_amplitude * (cos(a) * wave_a.w * wave_a.xy + cos(b) * wave_b.w * wave_b.xy);
	vec3 forward = normalize(COLOR.rgb * 2.0 - 1.0);
	vec3 side = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	VERTEX.y += h;
	// Exaggerate the slope for shading only, so small waves still read on a phone.
	vec3 n = normalize(cross(side + vec3(0.0, slope.y * 3.0, 0.0), forward + vec3(0.0, slope.x * 3.0, 0.0)));
	NORMAL = n;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 view = normalize(INV_VIEW_MATRIX[3].xyz - world);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(world_normal, view), 0.0, 1.0), 4.0);
	float edge = smoothstep(0.40, 1.0, UV2.x);
	v_shade = clamp(edge * 0.80 + fresnel * 0.60, 0.0, 1.0);
	v_crest = h / max(wave_amplitude * 1.45, 0.001);
	v_glint = pow(max(dot(reflect(-view, world_normal), normalize(sun_direction)), 0.0), 24.0);
}

void fragment() {
	// Route coordinates stay highp (s reaches hundreds of metres); colour maths runs at
	// mediump (fp16 on Mali). Foam terms only run near banks, obstacles and the float.
	mediump float foam = 0.0;
	for (int i = 0; i < hole_count; i++) {
		float edge = distance(UV, holes[i].xy) - holes[i].z;
		if (edge < 0.0) { discard; }
		foam = max(foam, 1.0 - smoothstep(0.05, 0.55, edge));
	}
	float t = water_time;
	vec2 across_along = vec2(UV.y, UV.x);
	mediump vec4 near = texture(pattern, across_along * 0.085 + vec2(0.0, -t * 0.075));
	mediump float noise = near.b;
	mediump float caustic = near.r;
	mediump float streak = 0.0;
	mediump float sparkle = 0.0;
	if (detail > 0.5) {
		mediump vec4 far = texture(pattern, across_along * vec2(0.115, 0.032) + vec2(0.31 + sin(UV.x * 0.05) * 0.06, -t * 0.09));
		caustic = min(caustic, far.r + 0.04);
		streak = smoothstep(0.45, 0.8, far.g);
		sparkle = smoothstep(0.35, 0.8, near.a) * (0.25 + v_glint * 2.5);
	}
	caustic = smoothstep(0.90, 0.985, caustic);

	mediump vec3 color = mix(deep_color, shallow_color, v_shade);
	color = mix(color, shallow_color * 1.1 + vec3(0.05), clamp(v_crest, 0.0, 1.0) * 0.35);
	color *= 1.0 - clamp(-v_crest, 0.0, 1.0) * 0.10;
	color += vec3(0.09, 0.16, 0.15) * caustic * (1.0 - v_shade * 0.4);

	mediump float shore_distance = (1.0 - UV2.x) * UV2.y;
	if (shore_distance < 1.8) {
		mediump float shore = 1.0 - smoothstep(0.18 + noise * 0.30, 0.34 + noise * 0.30, shore_distance);
		mediump float line = (1.0 - smoothstep(0.05, 0.14, abs(shore_distance - (0.95 + noise * 0.55 + sin(UV.x * 0.55 - t * 1.4) * 0.12)))) * step(0.42, noise);
		foam = max(foam, max(shore, line * 0.7));
	}

	for (int i = 0; i < obstacle_count; i++) {
		vec2 offset = UV - obstacles[i].xy;
		float reach = obstacles[i].z + 2.2;
		if (dot(offset, offset) < reach * reach) {
			mediump float edge = length(offset) - obstacles[i].z;
			mediump float pulse = fract(t * 0.55 + float(i) * 0.37);
			mediump float hug = 1.0 - smoothstep(0.05, 0.30 + noise * 0.35, edge);
			mediump float ring = (1.0 - smoothstep(0.06, 0.18, abs(edge - pulse * 1.8))) * (1.0 - pulse) * step(0.35, noise);
			foam = max(foam, max(hug, ring * 0.8));
		}
	}

	if (ring_supported) {
		vec2 relative = UV - ring_uv;
		if (dot(relative, relative) < 256.0) {
			mediump float speed = length(wake_velocity);
			mediump vec2 heading = wake_velocity / max(speed, 0.001);
			mediump float behind = -dot(relative, heading);
			mediump float across = dot(relative, vec2(-heading.y, heading.x));
			// V-shaped wake: two crisp foam arms opening behind the float, broken up by noise.
			mediump float arm = abs(abs(across) - (1.8 + behind * 0.32));
			mediump float wake = (1.0 - smoothstep(0.08, 0.20 + noise * 0.22, arm)) * smoothstep(0.0, 1.2, behind) * (1.0 - smoothstep(4.0, 14.0, behind));
			mediump float churn = (1.0 - smoothstep(0.5, 1.8, abs(across))) * smoothstep(1.6, 2.6, behind) * (1.0 - smoothstep(3.0, 9.0, behind)) * step(0.56, noise);
			mediump float contact = (1.0 - smoothstep(0.06, 0.26 + noise * 0.22, abs(length(relative) - 2.55))) * 0.85;
			foam = max(foam, max(contact, (wake + churn * 0.7) * min(speed / 5.0, 0.85)));
		}
	}
	color = mix(color, foam_color, streak * 0.5 * (1.0 - v_shade * 0.5));
	color += vec3(sparkle);
	ALBEDO = mix(color, foam_color, clamp(foam, 0.0, 0.95));
}
