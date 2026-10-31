shader_type sky;
uniform vec3 top : source_color = vec3(0.431, 0.776, 0.941);
uniform vec3 mid : source_color = vec3(0.741, 0.922, 0.984);
uniform vec3 low : source_color = vec3(0.933, 0.976, 1.0);
void sky() {
	float y = EYEDIR.y;
	COLOR = y > 0.0 ? mix(mid, top, smoothstep(0.0, 0.6, y)) : mix(mid, low, smoothstep(0.0, 0.5, -y));
}
