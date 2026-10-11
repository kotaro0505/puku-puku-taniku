class_name StoryContinueButtonStyle
extends RefCounted

const BUTTON_SIZE := Vector2(250, 48)
const BACKGROUND_COLOR := Color("#d8b56b")
const FONT_COLOR := Color("#4a2618")
const FONT_SIZE := 19
const CORNER_RADIUS := 20
const BORDER_WIDTH := 3
const PANEL_BOTTOM_MARGIN := 24.0
const TEXT_BUTTON_GAP := 12.0
const PANEL_TEXT_TOP_MARGIN := 12.0


static func apply(button: Button) -> void:
	button.custom_minimum_size = BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_color", FONT_COLOR)
	button.add_theme_color_override("font_hover_color", FONT_COLOR)
	button.add_theme_stylebox_override("normal", _style(BACKGROUND_COLOR, BACKGROUND_COLOR.lightened(0.22)))
	button.add_theme_stylebox_override("hover", _style(BACKGROUND_COLOR.lightened(0.08), Color.WHITE))
	button.add_theme_stylebox_override("pressed", _style(BACKGROUND_COLOR.darkened(0.08), BACKGROUND_COLOR.lightened(0.20)))


static func place_at_panel_bottom(button: Button, panel: Control, bottom_margin := PANEL_BOTTOM_MARGIN) -> void:
	button.position = Vector2(
		panel.position.x + (panel.size.x - BUTTON_SIZE.x) * 0.5,
		panel.position.y + panel.size.y - BUTTON_SIZE.y - bottom_margin
	)
	button.size = BUTTON_SIZE


static func balance_text_above_button(text: Control, button: Button, panel: Control, gap := TEXT_BUTTON_GAP) -> void:
	var overflow := text.position.y + text.size.y - (button.position.y - gap)
	if overflow <= 0.0:
		return
	var minimum_text_y := panel.position.y + PANEL_TEXT_TOP_MARGIN
	var upward_room := maxf(0.0, text.position.y - minimum_text_y)
	var upward_shift := minf(overflow, upward_room)
	text.position.y -= upward_shift
	overflow -= upward_shift
	if overflow > 0.0:
		text.size.y = maxf(0.0, text.size.y - overflow)


static func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(0.18, 0.08, 0.02, 0.34)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
