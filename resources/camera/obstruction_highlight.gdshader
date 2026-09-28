shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, fog_disabled;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	ALBEDO = vec3(0.58, 0.64, 0.62);
	ALPHA = strength * (0.25 + 0.75 * rim);
}
