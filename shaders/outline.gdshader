shader_type spatial;
// Inverted hull outline used as next_pass on characters and props only.
render_mode cull_front, unshaded, shadows_disabled; // Draw only back faces of the grown hull, no lighting.

uniform vec4 outline_color : source_color = vec4(0.106, 0.141, 0.188, 1.0); // Palette outline #1B2430.
uniform float thickness : hint_range(0.0, 0.1) = 0.016; // Hull growth along normals in model units.

void vertex() {
	VERTEX += normalize(NORMAL) * thickness; // Push the hull outward so its back faces show as a rim.
}

void fragment() {
	ALBEDO = outline_color.rgb; // Flat dark color.
}
