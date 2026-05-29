shader_type canvas_item;

// CRT glitch-static overlay for locked Glitch Catalog slots.
// Drives a scanline + RGB-channel-shift noise that pulses over time.

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float scroll_speed : hint_range(0.0, 10.0) = 2.5;
uniform float scanline_density : hint_range(1.0, 200.0) = 80.0;
uniform float rgb_shift : hint_range(0.0, 0.05) = 0.012;

float rand(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Animated scanline bands
	float scan = step(0.5, fract(uv.y * scanline_density + TIME * scroll_speed));
	float noise = rand(vec2(uv.y * 120.0 + TIME * 3.0, TIME * 0.7));
	float glitch_band = step(0.92, noise) * scan;

	// Horizontal RGB channel shift on glitch bands
	float shift = glitch_band * rgb_shift;
	vec4 col;
	col.r = texture(TEXTURE, vec2(uv.x + shift, uv.y)).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, vec2(uv.x - shift, uv.y)).b;
	col.a = texture(TEXTURE, uv).a;

	// Static grain
	float grain = rand(uv + vec2(TIME * 0.1, TIME * 0.07)) * 0.15;

	// Scanline darkening
	float scanline_dark = 1.0 - 0.25 * step(0.5, fract(uv.y * scanline_density));

	COLOR = col * scanline_dark;
	COLOR.rgb += grain * intensity;
	COLOR.rgb = mix(COLOR.rgb, vec3(0.0, 0.8, 0.6), glitch_band * intensity * 0.4);
	COLOR.a = col.a;
}
