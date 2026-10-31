shader_type spatial;
// Three band toon shading from NdotL with soft band edges for characters, props, and terrain.

uniform vec4 albedo_color : source_color = vec4(0.106, 0.141, 0.188, 1.0); // Base surface color from the palette.
uniform float band_mid : hint_range(0.0, 1.0) = 0.45; // Half lambert threshold between shadow and mid band.
uniform float band_high : hint_range(0.0, 1.0) = 0.8; // Half lambert threshold between mid and lit band.
uniform float shade_shadow : hint_range(0.0, 1.0) = 0.4; // Light level of the shadow band.
uniform float shade_mid : hint_range(0.0, 1.0) = 0.75; // Light level of the mid band.
uniform float shade_lit : hint_range(0.0, 1.5) = 1.0; // Light level of the lit band.
uniform float softness : hint_range(0.0, 0.2) = 0.03; // Half width of the blend at each band edge.

void fragment() {
	ALBEDO = albedo_color.rgb; // Godot multiplies diffuse light by ALBEDO after light().
}

void light() {
	float ndotl = dot(NORMAL, LIGHT) * 0.5 + 0.5; // Half lambert keeps the dark side readable.
	float to_mid = smoothstep(band_mid - softness, band_mid + softness, ndotl); // Soft step into the mid band.
	float to_lit = smoothstep(band_high - softness, band_high + softness, ndotl); // Soft step into the lit band.
	float shade = mix(mix(shade_shadow, shade_mid, to_mid), shade_lit, to_lit); // Pick one of three flat levels.
	DIFFUSE_LIGHT += shade * ATTENUATION * LIGHT_COLOR / PI; // LIGHT_COLOR includes a PI factor in Godot 4.
}
