class_name BestRecordShowcase
extends Control

signal close_requested
signal share_requested(record: Dictionary)

const Localizer = preload("res://scripts/game_localizer.gd")
const UI_FONT = preload("res://assets/fonts/ZenMaruGothic-Bold.ttf")

const PREVIEW_SIZE := Vector2(576.0, 1024.0)
const OUTPUT_SIZE := Vector2i(1080, 1920)
const HABITAT_BACKGROUND_PATH := "res://assets/highland-panorama.jpg"
const GIRL_TEXTURE_PATH := "res://assets/dialogue/girl-dialogue.png"
const PLANT_PIXELS_PER_CM := 1.75
const PLANT_ANCHOR := Vector2(260.0, 700.0)
const GIRL_RECT := Rect2(400.0, 622.0, 160.0, 214.0)

var current_record: Dictionary = {}
var current_entry: Dictionary = {}
var current_texture: Texture2D
var language_code := "ja"
var share_in_progress := false

var preview_root: Control
var preview_plant: Polygon2D
var title_label: Label
var species_label: Label
var size_label: Label
var close_button: Button
var share_button: Button
var share_status_label: Label

var last_preview_debug: Dictionary = {}
var last_share_debug: Dictionary = {}
var _texture_anchor_cache: Dictionary = {}
var _fade_tween: Tween


func _ready() -> void:
	name = "BestRecordShowcase"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 900
	visible = false
	preview_root = Control.new()
	preview_root.name = "RecordComposition"
	preview_root.position = Vector2.ZERO
	preview_root.size = PREVIEW_SIZE
	preview_root.clip_contents = true
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview_root)
	_build_controls()


func open_record(entry: Dictionary, size_cm: float, texture: Texture2D, language: String) -> void:
	if entry.is_empty() or size_cm <= 0.0:
		return
	current_entry = entry.duplicate(true)
	current_record = {
		"species_id": str(entry.get("species_id", "")),
		"size": size_cm,
	}
	current_texture = texture
	language_code = Localizer.normalize_language(language)
	close_button.text = Localizer.text(language_code, "close")
	share_button.text = Localizer.text(language_code, "share_action")
	share_in_progress = false
	share_status_label.text = ""
	share_status_label.visible = false
	close_button.disabled = false
	share_button.disabled = texture == null
	_rebuild_preview()
	visible = true
	modulate.a = 0.0
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func close_view() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = false
	modulate.a = 1.0
	share_in_progress = false
	current_record.clear()
	current_entry.clear()
	current_texture = null
	share_status_label.text = ""
	share_status_label.visible = false


func set_language(language: String) -> void:
	language_code = Localizer.normalize_language(language)
	close_button.text = Localizer.text(language_code, "close")
	share_button.text = Localizer.text(language_code, "share_action")
	if visible and not current_record.is_empty():
		_rebuild_preview()


func set_plant_texture(texture: Texture2D) -> void:
	if texture == null or current_record.is_empty():
		return
	current_texture = texture
	share_button.disabled = share_in_progress
	_rebuild_preview()


func set_share_state(message: String, in_progress: bool) -> void:
	share_in_progress = in_progress
	share_status_label.text = message
	share_status_label.visible = not message.is_empty()
	share_button.disabled = in_progress or current_texture == null
	close_button.disabled = in_progress


func create_share_image(output_path_override: String = "") -> String:
	if current_record.is_empty() or current_entry.is_empty() or current_texture == null:
		return ""
	var viewport := SubViewport.new()
	viewport.name = "BestRecordShareViewport"
	viewport.size = OUTPUT_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	add_child(viewport)
	var root := Control.new()
	root.name = "BestRecordShareComposition"
	root.size = Vector2(OUTPUT_SIZE)
	root.clip_contents = true
	viewport.add_child(root)
	last_share_debug = _build_composition(root, Vector2(OUTPUT_SIZE), current_entry, float(current_record.get("size", 0.0)), current_texture, language_code)
	last_share_debug["output_size"] = OUTPUT_SIZE
	last_share_debug["root_children"] = _child_names(root)
	await get_tree().process_frame
	await get_tree().process_frame
	var rendered := viewport.get_texture().get_image()
	var output_path := output_path_override
	if output_path.is_empty():
		output_path = "user://puku-best-record-%d-%03d.png" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec() % 1000]
	var error := ERR_CANT_CREATE
	if rendered != null and not rendered.is_empty():
		error = rendered.save_png(output_path)
	viewport.queue_free()
	return output_path if error == OK else ""


static func plant_diameter_pixels(size_cm: float, canvas_width: float = PREVIEW_SIZE.x) -> float:
	return maxf(0.0, size_cm) * PLANT_PIXELS_PER_CM * canvas_width / PREVIEW_SIZE.x


func _build_controls() -> void:
	var bottom_guard := ColorRect.new()
	bottom_guard.name = "ViewerControlGuard"
	bottom_guard.position = Vector2(0.0, 900.0)
	bottom_guard.size = Vector2(576.0, 124.0)
	bottom_guard.color = Color(0.07, 0.045, 0.025, 0.70)
	bottom_guard.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom_guard.z_index = 20
	add_child(bottom_guard)

	share_status_label = Label.new()
	share_status_label.name = "ShareStatus"
	share_status_label.position = Vector2(38.0, 866.0)
	share_status_label.size = Vector2(500.0, 42.0)
	share_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	share_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	share_status_label.add_theme_font_override("font", UI_FONT)
	share_status_label.add_theme_font_size_override("font_size", 15)
	share_status_label.add_theme_color_override("font_color", Color("#fff3cf"))
	share_status_label.add_theme_color_override("font_outline_color", Color("#3b2419"))
	share_status_label.add_theme_constant_override("outline_size", 4)
	share_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	share_status_label.z_index = 22
	share_status_label.visible = false
	add_child(share_status_label)

	close_button = Button.new()
	close_button.name = "BestRecordCloseButton"
	close_button.position = Vector2(48.0, 930.0)
	close_button.size = Vector2(218.0, 62.0)
	close_button.focus_mode = Control.FOCUS_NONE
	_apply_button_style(close_button, Color("#f0dfbd"))
	close_button.pressed.connect(_on_close_pressed)
	close_button.z_index = 21
	add_child(close_button)

	share_button = Button.new()
	share_button.name = "BestRecordShareButton"
	share_button.position = Vector2(310.0, 930.0)
	share_button.size = Vector2(218.0, 62.0)
	share_button.focus_mode = Control.FOCUS_NONE
	_apply_button_style(share_button, Color("#e7b957"))
	share_button.pressed.connect(_on_share_pressed)
	share_button.z_index = 21
	add_child(share_button)
	set_language(language_code)


func _rebuild_preview() -> void:
	for child in preview_root.get_children():
		preview_root.remove_child(child)
		child.queue_free()
	last_preview_debug = _build_composition(preview_root, PREVIEW_SIZE, current_entry, float(current_record.get("size", 0.0)), current_texture, language_code)


func _build_composition(parent: Control, canvas_size: Vector2, entry: Dictionary, size_cm: float, texture: Texture2D, language: String) -> Dictionary:
	var factor := canvas_size.x / PREVIEW_SIZE.x
	var background := TextureRect.new()
	background.name = "HabitatBackground"
	background.texture = load(HABITAT_BACKGROUND_PATH) as Texture2D
	background.position = Vector2.ZERO
	background.size = canvas_size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)

	var atmosphere := ColorRect.new()
	atmosphere.name = "HabitatAtmosphere"
	atmosphere.position = Vector2.ZERO
	atmosphere.size = canvas_size
	atmosphere.color = Color(0.20, 0.13, 0.06, 0.12)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(atmosphere)

	var diameter_pixels := plant_diameter_pixels(size_cm, canvas_size.x)
	var shadow := Polygon2D.new()
	shadow.name = "PlantGroundShadow"
	shadow.polygon = _ellipse_polygon(PLANT_ANCHOR * factor + Vector2(0.0, minf(diameter_pixels * 0.08, 50.0 * factor)), minf(diameter_pixels * 0.78, canvas_size.x * 1.30), clampf(diameter_pixels * 0.12, 8.0 * factor, 82.0 * factor))
	shadow.color = Color(0.08, 0.045, 0.025, 0.36)
	shadow.z_index = 1
	parent.add_child(shadow)

	var plant := Polygon2D.new()
	plant.name = "RecordPlant"
	plant.texture = texture
	plant.antialiased = true
	plant.z_index = 2
	parent.add_child(plant)
	var plant_layout := _layout_plant_polygon(plant, texture, size_cm, canvas_size)
	if parent == preview_root:
		preview_plant = plant

	var girl_texture := load(GIRL_TEXTURE_PATH) as Texture2D
	var girl := Sprite2D.new()
	girl.name = "GirlScaleReference"
	girl.texture = girl_texture
	girl.centered = false
	var desired_girl_rect := Rect2(GIRL_RECT.position * factor, GIRL_RECT.size * factor)
	var girl_texture_size := girl_texture.get_size() if girl_texture else Vector2.ONE
	var girl_scale := minf(desired_girl_rect.size.x / maxf(girl_texture_size.x, 1.0), desired_girl_rect.size.y / maxf(girl_texture_size.y, 1.0))
	var girl_size := girl_texture_size * girl_scale
	girl.position = desired_girl_rect.position + (desired_girl_rect.size - girl_size) * 0.5
	girl.scale = Vector2.ONE * girl_scale
	girl.z_index = 3
	parent.add_child(girl)

	var top_scrim := ColorRect.new()
	top_scrim.name = "TopReadabilityShade"
	top_scrim.position = Vector2.ZERO
	top_scrim.size = Vector2(canvas_size.x, 210.0 * factor)
	top_scrim.color = Color(0.08, 0.045, 0.025, 0.42)
	top_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_scrim.z_index = 4
	parent.add_child(top_scrim)
	var bottom_scrim := ColorRect.new()
	bottom_scrim.name = "BottomReadabilityShade"
	bottom_scrim.position = Vector2(0.0, 826.0 * factor)
	bottom_scrim.size = Vector2(canvas_size.x, canvas_size.y - bottom_scrim.position.y)
	bottom_scrim.color = Color(0.06, 0.035, 0.02, 0.46)
	bottom_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_scrim.z_index = 4
	parent.add_child(bottom_scrim)

	var header := PanelContainer.new()
	header.name = "RecordHeader"
	header.position = Vector2(38.0, 34.0) * factor
	header.size = Vector2(500.0, 158.0) * factor
	header.add_theme_stylebox_override("panel", _panel_style(factor))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.z_index = 5
	parent.add_child(header)
	var header_content := VBoxContainer.new()
	header_content.alignment = BoxContainer.ALIGNMENT_CENTER
	header_content.add_theme_constant_override("separation", roundi(1.0 * factor))
	header_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_content)

	var title := _composition_label(Localizer.text(language, "best_showcase_title"), roundi(25.0 * factor), Color("#ffe17b"), factor)
	title.name = "RecordTitle"
	header_content.add_child(title)
	var species_name := Localizer.species_name(language, entry)
	var species_name_label := _composition_label(species_name, roundi(25.0 * factor), Color.WHITE, factor)
	species_name_label.name = "RecordSpeciesName"
	header_content.add_child(species_name_label)
	var record_size_label := _composition_label(Localizer.text(language, "best_showcase_size", [size_cm]), roundi(31.0 * factor), Color("#fff3c2"), factor)
	record_size_label.name = "RecordSize"
	header_content.add_child(record_size_label)
	if parent == preview_root:
		title_label = title
		species_label = species_name_label
		size_label = record_size_label

	var footer := Label.new()
	footer.name = "RecordFooter"
	footer.text = Localizer.text(language, "game_title")
	footer.position = Vector2(38.0, 842.0) * factor
	footer.size = Vector2(500.0, 48.0) * factor
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_theme_font_override("font", UI_FONT)
	footer.add_theme_font_size_override("font_size", roundi(19.0 * factor))
	footer.add_theme_color_override("font_color", Color("#fff1cf"))
	footer.add_theme_color_override("font_outline_color", Color("#3b2419"))
	footer.add_theme_constant_override("outline_size", roundi(5.0 * factor))
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.z_index = 5
	parent.add_child(footer)

	return {
		"background_path": HABITAT_BACKGROUND_PATH,
		"species_id": str(entry.get("species_id", "")),
		"size_cm": size_cm,
		"plant_diameter_pixels": diameter_pixels,
		"plant_layout": plant_layout,
		"girl_rect": Rect2(girl.position, girl_size),
		"canvas_size": canvas_size,
	}


func _layout_plant_polygon(plant: Polygon2D, texture: Texture2D, size_cm: float, canvas_size: Vector2) -> Dictionary:
	if texture == null:
		plant.visible = false
		return {}
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		plant.visible = false
		return {}
	var used_rect := _texture_used_rect(texture)
	var diameter_pixels := plant_diameter_pixels(size_cm, canvas_size.x)
	var artwork_scale := diameter_pixels / maxf(used_rect.size.x, 1.0)
	var anchor_pixel := _texture_growth_anchor(texture, used_rect)
	var canvas_factor := canvas_size.x / PREVIEW_SIZE.x
	var anchor_screen := PLANT_ANCHOR * canvas_factor
	var top_left := anchor_screen - anchor_pixel * artwork_scale
	var full_quad := PackedVector2Array([
		top_left,
		top_left + Vector2(texture_size.x * artwork_scale, 0.0),
		top_left + texture_size * artwork_scale,
		top_left + Vector2(0.0, texture_size.y * artwork_scale),
	])
	var viewport_polygon := PackedVector2Array([Vector2.ZERO, Vector2(canvas_size.x, 0.0), canvas_size, Vector2(0.0, canvas_size.y)])
	var intersections := Geometry2D.intersect_polygons(full_quad, viewport_polygon)
	var clipped := PackedVector2Array()
	for candidate in intersections:
		if candidate.size() >= 3:
			clipped = candidate
			break
	if clipped.size() < 3:
		plant.visible = false
		return {"diameter_pixels": diameter_pixels, "artwork_scale": artwork_scale, "anchor_screen": anchor_screen, "full_quad": full_quad}
	var texture_uv := PackedVector2Array()
	for point in clipped:
		texture_uv.append((point - top_left) / artwork_scale)
	plant.polygon = clipped
	plant.uv = texture_uv
	plant.visible = true
	return {
		"diameter_pixels": diameter_pixels,
		"artwork_scale": artwork_scale,
		"anchor_pixel": anchor_pixel,
		"anchor_screen": anchor_screen,
		"full_quad": full_quad,
		"clipped_polygon": clipped,
	}


func _texture_used_rect(texture: Texture2D) -> Rect2:
	var texture_size := texture.get_size()
	var fallback := Rect2(Vector2.ZERO, texture_size)
	var image := texture.get_image()
	if image == null or image.is_empty():
		return fallback
	var used := image.get_used_rect()
	return Rect2(used) if used.size.x > 0 and used.size.y > 0 else fallback


func _texture_growth_anchor(texture: Texture2D, used_rect: Rect2) -> Vector2:
	var cache_key := "%s:%s" % [texture.get_rid(), texture.get_size()]
	if _texture_anchor_cache.has(cache_key):
		return _texture_anchor_cache[cache_key]
	var fallback := used_rect.position + used_rect.size * 0.5
	var image := texture.get_image()
	if image == null or image.is_empty():
		return fallback
	var longest_side := maxf(used_rect.size.x, used_rect.size.y)
	var sample_step := maxi(1, ceili(float(longest_side) / 128.0))
	var weighted_position := Vector2.ZERO
	var total_weight := 0.0
	for y in range(maxi(floori(used_rect.position.y), 0), mini(ceili(used_rect.end.y), image.get_height()), sample_step):
		for x in range(maxi(floori(used_rect.position.x), 0), mini(ceili(used_rect.end.x), image.get_width()), sample_step):
			var alpha := image.get_pixel(x, y).a
			if alpha <= 0.08:
				continue
			weighted_position += Vector2(float(x) + 0.5, float(y) + 0.5) * alpha
			total_weight += alpha
	var anchor := weighted_position / total_weight if total_weight > 0.0 else fallback
	_texture_anchor_cache[cache_key] = anchor
	return anchor


func _composition_label(text_value: String, font_size: int, color: Color, factor: float) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(450.0 * factor, 38.0 * factor)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#3b2419"))
	label.add_theme_constant_override("outline_size", roundi(4.0 * factor))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(factor: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.085, 0.045, 0.88)
	style.border_color = Color("#f4cf78")
	style.set_border_width_all(maxi(2, roundi(3.0 * factor)))
	style.set_corner_radius_all(maxi(16, roundi(22.0 * factor)))
	style.content_margin_left = 20.0 * factor
	style.content_margin_right = 20.0 * factor
	style.content_margin_top = 10.0 * factor
	style.content_margin_bottom = 10.0 * factor
	style.shadow_color = Color(0.08, 0.035, 0.015, 0.48)
	style.shadow_size = maxi(4, roundi(8.0 * factor))
	style.shadow_offset = Vector2(0.0, 4.0 * factor)
	return style


func _apply_button_style(button: Button, background: Color) -> void:
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#4a2618"))
	button.add_theme_color_override("font_hover_color", Color("#4a2618"))
	button.add_theme_color_override("font_pressed_color", Color("#4a2618"))
	button.add_theme_stylebox_override("normal", _button_box(background, background.lightened(0.16)))
	button.add_theme_stylebox_override("hover", _button_box(background.lightened(0.07), Color.WHITE))
	button.add_theme_stylebox_override("pressed", _button_box(background.darkened(0.08), background.lightened(0.12)))
	button.add_theme_stylebox_override("disabled", _button_box(background.darkened(0.20), background.darkened(0.05)))


func _button_box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.12, 0.055, 0.02, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 3.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _ellipse_polygon(center: Vector2, width: float, height: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(40):
		var angle := TAU * float(index) / 40.0
		points.append(center + Vector2(cos(angle) * width * 0.5, sin(angle) * height * 0.5))
	return points


func _child_names(parent: Node) -> Array[String]:
	var result: Array[String] = []
	for child in parent.get_children():
		result.append(str(child.name))
	return result


func _on_close_pressed() -> void:
	if not share_in_progress:
		close_requested.emit()


func _on_share_pressed() -> void:
	if share_in_progress or current_record.is_empty() or current_texture == null:
		return
	set_share_state(Localizer.text(language_code, "share_creating"), true)
	share_requested.emit(current_record.duplicate(true))
