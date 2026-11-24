shader_type sky;
// Soft stylized sky: deep blue overhead, bright haze band at the horizon (it matches the
// distance fog), a warm glow around the sun. No TIME, so radiance is computed once.
uniform vec3 top : source_color = vec3(0.33, 0.64, 0.95);
uniform vec3 mid : source_color = vec3(0.64, 0.87, 0.99);
uniform vec3 low : source_color = vec3(0.86, 0.95, 1.0);
uniform vec3 sun_tint : source_color = vec3(1.0, 0.95, 0.80);

void sky() {
	float y = EYEDIR.y;
	vec3 color = y > 0.0 ? mix(mid, top, smoothstep(0.0, 0.55, y)) : mix(mid, low, smoothstep(0.0, 0.45, -y));
	color = mix(color, low, (1.0 - smoothstep(0.0, 0.14, abs(y))) * 0.55);
	if (LIGHT0_ENABLED) {
		float glow = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		color += sun_tint * (pow(glow, 24.0) * 0.30 + pow(glow, 900.0) * 0.9);
	}
	COLOR = color;
}
