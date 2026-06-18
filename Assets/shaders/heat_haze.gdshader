shader_type canvas_item;

// Aria calda che vibra sul campo di battaglia: distorsione UV orizzontale crescente
// verso il basso (il suolo "ribolle"). Sottile, isolata allo sfondo dell'Assedio.
uniform float speed : hint_range(0.2, 4.0) = 1.4;
uniform float amount : hint_range(0.0, 0.01) = 0.0026;
uniform float freq : hint_range(4.0, 60.0) = 26.0;

void fragment() {
	float m = smoothstep(0.35, 1.0, UV.y);
	vec2 uv = UV;
	uv.x += sin(UV.y * freq + TIME * speed) * amount * m;
	uv.y += cos(UV.x * freq * 0.6 + TIME * speed * 0.8) * amount * 0.4 * m;
	COLOR = texture(TEXTURE, uv);
}
