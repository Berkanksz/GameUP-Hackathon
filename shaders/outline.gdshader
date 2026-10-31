shader_type spatial;
// Inverted hull outline shader pushing vertices along normals.
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.106, 0.141, 0.188, 1.0);
uniform float thickness : hint_range(0.0, 0.08) = 0.018;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
