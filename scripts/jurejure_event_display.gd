class_name JureJureEventDisplay
extends Control

signal pressed

# Replace ESCAPE_ASSET_PATH later when a dedicated running pose is authored.
const NORMAL_ASSET_PATH := "res://assets/jurejure/jurejure-reference.jpg"
const ESCAPE_ASSET_PATH := "res://assets/jurejure/jurejure-reference.jpg"

var card: PanelContainer
var group_image: TextureRect
var status_label: Label
var hit_button: Button
var escaping := false


func _ready() -> void:
	name = "JureJureEventDisplay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 720
	_build_ui()
	visible = false


func _build_ui() -> void:
	card = PanelContainer.new()
	card.size = Vector2(214, 184)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.95, 0.86, 0.96)
	style.border_color = Color("#6f4a31")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.05, 0.025, 0.015, 0.38)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)
	group_image = TextureRect.new()
	group_image.texture = load(NORMAL_ASSET_PATH) as Texture2D
	group_image.custom_minimum_size = Vector2(204, 142)
	group_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	group_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	group_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(group_image)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(204, 34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("#5a2f21"))
	status_label.add_theme_color_override("font_outline_color", Color("#fff6d5"))
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(status_label)

	hit_button = Button.new()
	hit_button.flat = true
	hit_button.focus_mode = Control.FOCUS_NONE
	hit_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit_button.pressed.connect(func(): pressed.emit())
	card.add_child(hit_button)


func show_at(screen_position: Vector2, status_text: String, intro := false) -> void:
	escaping = false
	group_image.texture = load(NORMAL_ASSET_PATH) as Texture2D
	status_label.text = status_text
	status_label.visible = not status_text.is_empty()
	card.size = Vector2(250, 205) if intro else Vector2(214, 184)
	visible = true
	modulate = Color.WHITE
	card.scale = Vector2.ONE
	card.rotation = 0.0
	move_to_front()
	set_target_screen_position(screen_position)


func set_target_screen_position(screen_position: Vector2) -> void:
	if not visible or escaping:
		return
	var viewport_size := get_viewport_rect().size
	card.position = Vector2(
		clampf(screen_position.x - card.size.x * 0.5, 8.0, viewport_size.x - card.size.x - 8.0),
		clampf(screen_position.y - card.size.y - 26.0, 92.0, viewport_size.y - card.size.y - 18.0)
	)


func contains_screen_point(screen_position: Vector2) -> bool:
	return visible and Rect2(card.position, card.size).has_point(screen_position)


func play_escape(finished := Callable()) -> void:
	if not visible or escaping:
		if finished.is_valid():
			finished.call()
		return
	escaping = true
	group_image.texture = load(ESCAPE_ASSET_PATH) as Texture2D
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position:x", get_viewport_rect().size.x + 32.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "rotation", 0.08, 0.18)
	tween.tween_property(card, "scale", Vector2(0.88, 0.88), 0.48)
	tween.tween_property(card, "position:y", card.position.y - 16.0, 0.16).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func():
		visible = false
		escaping = false
		card.scale = Vector2.ONE
		card.rotation = 0.0
		if finished.is_valid():
			finished.call()
	)


func hide_immediately() -> void:
	visible = false
	escaping = false
	card.scale = Vector2.ONE
	card.rotation = 0.0
