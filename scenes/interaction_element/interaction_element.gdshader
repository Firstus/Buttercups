shader_type canvas_item;

// Soft, round glow with a cool gradient. Used by the interaction element sprite.

// Bright inner core of the glow.
uniform vec3 core_color : source_color = vec3(0.85, 1.0, 1.0);
// Middle of the gradient.
uniform vec3 mid_color : source_color = vec3(0.25, 0.8, 1.0);
// Outer edge of the glow.
uniform vec3 edge_color : source_color = vec3(0.55, 0.35, 1.0);
// Radius of the solid core, as a fraction of the glow radius.
uniform float core_size : hint_range(0.0, 1.0) = 0.35;
// How soft the round edge fades out (0.01 = hard edge, 1.0 = very soft).
uniform float edge_softness : hint_range(0.01, 1.0) = 0.4;
// Strength of the bright ring just inside the edge.
uniform float rim_strength : hint_range(0.0, 2.0) = 0.5;
// Overall brightness of the element.
uniform float glow_strength : hint_range(0.0, 4.0) = 1.15;
// Rotation speed of the subtle sheen (0 turns it off).
uniform float sheen_speed : hint_range(0.0, 2.0) = 0.4;
// Opacity of the sheen highlight.
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.12;

varying vec4 tint;

void vertex() {
	// Keep the sprite's modulate so alpha breathing still works.
	tint = COLOR;
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 2.0; // 0 at the center, 1 at the edge

	// Round mask with soft edges.
	float mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, radius);

	// Cool radial gradient: bright core -> cyan -> violet edge.
	vec3 color = mix(core_color, mid_color, smoothstep(core_size, 0.5, radius));
	color = mix(color, edge_color, smoothstep(0.45, 0.9, radius));

	// Subtle rotating sheen so the element feels alive.
	float angle = atan(centered.y, centered.x);
	float sheen = 0.5 + 0.5 * cos(angle - TIME * sheen_speed);
	color += sheen * sheen_strength * mask;

	// Bright rim just inside the soft edge.
	float rim = smoothstep(0.5, 0.85, radius) * (1.0 - smoothstep(0.85, 1.0, radius));
	color += edge_color * rim * rim_strength;

	COLOR = vec4(color * glow_strength * tint.rgb, mask * tint.a);
}
