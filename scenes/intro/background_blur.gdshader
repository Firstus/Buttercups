shader_type canvas_item;

// Blurs the intro background so the story text stays readable while the
// factory image remains visible behind it. Works on the texture's mipmaps:
// their levels are prefiltered, so no aliasing patterns show up.

// How blurred the image is. Tweened from 0.0 (sharp) to 1.0 (fully blurred).
uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
// Mip level (texture is halved that many times) at blur_amount 1.0.
uniform float max_mip_level : hint_range(0.0, 8.0) = 5.0;

// Small Gaussian that smooths the box-filtered mip levels.
const float WEIGHTS[3] = { 0.25, 0.5, 0.25 };

varying vec4 tint;

void vertex() {
	// Keep the sprite's modulate so fading still works.
	tint = COLOR;
}

void fragment() {
	float lod = blur_amount * max_mip_level;
	// One tap per texel of the sampled mip level; at lod 0 the taps collapse
	// onto each other, so the sharp image stays untouched.
	vec2 tap_size = TEXTURE_PIXEL_SIZE * (exp2(lod) - 1.0);

	vec4 blurred = vec4(0.0);
	for (int x = 0; x < 3; x++) {
		for (int y = 0; y < 3; y++) {
			vec2 tap_offset = vec2(float(x) - 1.0, float(y) - 1.0) * tap_size;
			blurred += textureLod(TEXTURE, UV + tap_offset, lod) * WEIGHTS[x] * WEIGHTS[y];
		}
	}

	COLOR = vec4(blurred.rgb * tint.rgb, blurred.a * tint.a);
}
