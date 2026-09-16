shader_type canvas_item;

// The supplied JPEG contains a checkerboard inside the dial opening.
// Replace the entire disk with the dark interior of the machine. Keeping an
// opaque backing prevents the checkerboard from showing through transparent
// anti-aliased pixels and gaps in the independently rotating dial texture.
uniform vec2 source_size = vec2(720.0, 1280.0);
uniform vec2 dial_hole_center = vec2(487.0, 784.0);
uniform float dial_hole_radius = 54.0;
uniform vec3 dial_backing_color = vec3(0.075, 0.037, 0.015);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float distance_from_dial = length(UV * source_size - dial_hole_center);
	float hole_mask = 1.0 - smoothstep(dial_hole_radius - 1.5, dial_hole_radius + 1.5, distance_from_dial);
	color.rgb = mix(color.rgb, dial_backing_color, hole_mask);
	color.a = 1.0;
	COLOR = color;
}
