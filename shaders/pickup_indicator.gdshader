shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform bool enabled = true;
uniform float height : hint_range(0.1, 3.0) = 1.25;
uniform float thickness : hint_range(0.01, 0.15) = 0.045;
uniform float opacity : hint_range(0.0, 1.0) = 0.55;
uniform vec4 color : source_color = vec4(0.7, 0.85, 0.8, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
void vertex() {
	VERTEX.x *= thickness;
	VERTEX.y = (VERTEX.y + 0.5) * height;
}
void fragment() {
	float ends = smoothstep(0.0, 0.24, UV.y) * smoothstep(0.0, 0.24, 1.0 - UV.y);
	float sides = smoothstep(0.0, 0.3, UV.x) * smoothstep(0.0, 0.3, 1.0 - UV.x);
	ALBEDO = color.rgb * intensity;
	ALPHA = enabled ? ends * sides * opacity * color.a : 0.0;
}
