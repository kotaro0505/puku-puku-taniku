class_name ArrangementShareRenderer
extends RefCounted

const OUTPUT_SIZE := Vector2i(1080, 1920)
const VIEWER_CANVAS_SIZE := Vector2(536.0, 552.0)
# The live viewer intentionally lets the pot extend below its 552 px gesture
# canvas.  Keeping that overflow in the virtual source area prevents the pot
# from being clipped in the 9:16 composition.
const ARTWORK_VIRTUAL_SIZE := Vector2(536.0, 680.0)
const DEFAULT_ARTWORK_RECT := Rect2(0.05, 0.38, 0.90, 0.60)

static func background_layout(texture_size: Vector2, focus_value: Variant) -> Dictionary:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return {}
	var output_size := Vector2(OUTPUT_SIZE)
	var scale_value := maxf(output_size.x / texture_size.x, output_size.y / texture_size.y)
	var scaled_size := texture_size * scale_value
	var focus := focus_value as Vector2 if focus_value is Vector2 else Vector2(0.5, 0.5)
	focus = Vector2(clampf(focus.x, 0.0, 1.0), clampf(focus.y, 0.0, 1.0))
	var maximum_crop := Vector2(maxf(0.0, scaled_size.x - output_size.x), maxf(0.0, scaled_size.y - output_size.y))
	var desired_crop := focus * scaled_size - output_size * 0.5
	var crop_origin := Vector2(clampf(desired_crop.x, 0.0, maximum_crop.x), clampf(desired_crop.y, 0.0, maximum_crop.y))
	return {
		"scale": scale_value,
		"position": -crop_origin,
		"crop_origin": crop_origin,
		"scaled_size": scaled_size,
	}

static func normalized_artwork_rect(entry: Dictionary) -> Rect2:
	var value: Variant = entry.get("artwork_rect", DEFAULT_ARTWORK_RECT)
	var normalized := value as Rect2 if value is Rect2 else DEFAULT_ARTWORK_RECT
	var left := clampf(normalized.position.x, 0.0, 0.95)
	var top := clampf(normalized.position.y, 0.0, 0.95)
	var width := clampf(normalized.size.x, 0.05, 1.0 - left)
	var height := clampf(normalized.size.y, 0.05, 1.0 - top)
	return Rect2(Vector2(left, top), Vector2(width, height))

static func artwork_layout(entry: Dictionary) -> Dictionary:
	var normalized_rect := normalized_artwork_rect(entry)
	var output_size := Vector2(OUTPUT_SIZE)
	var target_rect := Rect2(normalized_rect.position * output_size, normalized_rect.size * output_size)
	var scale_value := minf(target_rect.size.x / ARTWORK_VIRTUAL_SIZE.x, target_rect.size.y / ARTWORK_VIRTUAL_SIZE.y)
	var rendered_size := ARTWORK_VIRTUAL_SIZE * scale_value
	var position := target_rect.position + (target_rect.size - rendered_size) * 0.5
	return {
		"target_rect": target_rect,
		"position": position,
		"scale": scale_value,
		"rendered_size": rendered_size,
	}

static func mapped_viewer_transform(viewer_transform: Dictionary, entry: Dictionary) -> Dictionary:
	var layout := artwork_layout(entry)
	var composition_scale := float(layout.get("scale", 1.0))
	var viewer_position := Vector2(float(viewer_transform.get("x", 0.0)), float(viewer_transform.get("y", 0.0)))
	var viewer_scale := float(viewer_transform.get("scale", 1.0))
	return {
		"position": layout.get("position", Vector2.ZERO) + viewer_position * composition_scale,
		"scale": composition_scale * viewer_scale,
	}
