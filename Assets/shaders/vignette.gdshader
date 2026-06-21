shader_type canvas_item;

// Vignettatura cinematografica riusabile su ColorRect full-rect: scurimento radiale
// dai bordi verso un centro pulito, per isolare il soggetto e sfumare bordi/letterbox
// nel buio. `tint` ne controlla colore+alpha massima (nero di default; viola tenue per
// il mystery, animabile via tween della uniform). Sostituisce le GradientTexture2D 512^2.
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.36;
uniform float radius : hint_range(0.0, 1.2) = 0.58;     // distanza in cui inizia lo scurimento
uniform float softness : hint_range(0.02, 1.2) = 0.62;  // ampiezza della sfumatura
uniform float aspect : hint_range(0.3, 3.0) = 1.6;      // ellisse gradevole su 16:9

void fragment() {
	vec2 d = UV - vec2(0.5);
	d.x *= aspect;
	float dist = length(d);
	float v = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(tint.rgb, tint.a * v * intensity);
}
