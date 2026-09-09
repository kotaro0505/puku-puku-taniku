shader_type canvas_item;

// The supplied JPEG contains a checkerboard inside the dial opening.
// Mask that disk to real runtime transparency so the replaceable dial node
// underneath/above it is the only thing visible in the opening.
uniform vec2 source_size = vec2(720.0, 1280.0);
uniform vec2 dial_hole_center = vec2(487.0, 784.0);
uniform float dial_hole_radius = 54.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float distance_from_dial = length(UV * source_size - dial_hole_center);
	float opaque_mask = smoothstep(dial_hole_radius - 1.5, dial_hole_radius + 1.5, distance_from_dial);
	color.a *= opaque_mask;
	COLOR = color;
}
