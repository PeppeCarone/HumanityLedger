shader_type canvas_item;

// Flicker organico per il bagliore del fuoco: modula la luminosità con due seni
// sfasati (niente texture extra). Si combina col tween di alpha già presente.
uniform float speed : hint_range(1.0, 16.0) = 7.0;
uniform float amount : hint_range(0.0, 0.6) = 0.22;

void fragment() {
	float f = 1.0 + amount * (0.55 * sin(TIME * speed) + 0.45 * sin(TIME * speed * 1.73 + 1.3));
	COLOR.rgb *= f;
}
