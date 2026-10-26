shader_type canvas_item;
// Full-screen pixelation: everything drawn BELOW this layer gets chunky pixels.
// The UI layer sits above it, so text and buttons stay sharp.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float pixel_size = 4.0;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = floor(SCREEN_UV * res / pixel_size) * pixel_size / res;
	COLOR = texture(screen_tex, uv + (pixel_size * 0.5) / res);
}
