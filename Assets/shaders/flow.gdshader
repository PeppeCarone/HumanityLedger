shader_type canvas_item;

// Flusso luminoso lungo una rotta: una banda chiara scorre nel verso del tragitto
// (UV.x = lunghezza). Tinta oro (commercio) o rossa (guerra) via uniform.
uniform float speed : hint_range(0.05, 2.0) = 0.45;
uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform vec3 glow : source_color = vec3(1.0, 0.86, 0.5);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float band = sin((UV.x - TIME * speed) * 6.2831 * 2.0) * 0.5 + 0.5;
	c.rgb += glow * band * intensity * c.a;
	COLOR = c;
}
