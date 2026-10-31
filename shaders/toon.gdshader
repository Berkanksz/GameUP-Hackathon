shader_type spatial;
// Three band toon shader with soft step transitions for 2.5D characters and props.

uniform vec4 albedo_color : source_color = vec4(0.11, 0.14, 0.19, 1.0);
uniform float band_mid : hint_range(0.0, 1.0) = 0.45;
uniform float band_high : hint_range(0.0, 1.0) = 0.82;
uniform float smoothness : hint_range(0.005, 0.2) = 0.04;

void fragment() {
	ALBEDO = albedo_color.rgb;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float mid = smoothstep(band_mid - smoothness, band_mid + smoothness, ndotl);
	float high = smoothstep(band_high - smoothness, band_high + smoothness, ndotl);
	float shade = mix(0.45, 0.85, mid) + high * 0.2;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * shade;
}
