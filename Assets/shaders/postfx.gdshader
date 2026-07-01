shader_type canvas_item;

// Post-processing GLOBALE del gioco (Docs/20): sobrio e caldo ("tomo illuminato" / mito oscuro).
// Vignette morbida + color-grade (calore/contrasto/saturazione) + aberrazione cromatica ai bordi
// + grana film animata. Applicato da un ColorRect a tutto schermo (autoload PostFX).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.30;
uniform float vignette_soft   : hint_range(0.2, 1.0) = 0.58;
uniform float grain_amount    : hint_range(0.0, 0.15) = 0.038;
uniform float aberration      : hint_range(0.0, 3.0) = 0.55;
uniform float warmth          : hint_range(-0.1, 0.1) = 0.026;
uniform float contrast        : hint_range(0.9, 1.2) = 1.05;
uniform float saturation      : hint_range(0.7, 1.3) = 1.06;

float rand(vec2 c) {
	return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dc = uv - vec2(0.5);
	float d = length(dc) * 1.41421;                 // 0 al centro, ~1 agli angoli

	// Aberrazione cromatica: cresce verso i bordi (sottile).
	vec2 off = dc * aberration * 0.0016 * d;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	// Color grade: calore + contrasto + saturazione.
	col.r += warmth;
	col.b -= warmth;
	col = (col - 0.5) * contrast + 0.5;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturation);

	// Vignette morbida.
	float vig = smoothstep(1.0, vignette_soft, d);
	col *= mix(1.0, vig, vignette_amount);

	// Grana film animata.
	float g = (rand(uv * vec2(1920.0, 1080.0) + fract(TIME)) - 0.5) * grain_amount;
	col += g;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
