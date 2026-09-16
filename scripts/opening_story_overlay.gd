class_name OpeningStoryOverlay
extends Control

signal story_finished(replay_mode: bool)

const PAGE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/opening_story/page-1.jpg"),
	preload("res://assets/opening_story/page-2.jpg"),
	preload("res://assets/opening_story/page-3.jpg"),
	preload("res://assets/opening_story/page-4.jpg")
]
const PAGE_TEXTS: Array[String] = [
	"ある日、女の子は\n古い倉庫のすみで、\nほこりをかぶった一冊の本を見つけました。\n\n「なんだろう、これ……」",
	"ほこりを払い、\nみんなで本を見てみると——\n\n表紙には、\n\n「原種図鑑」\n\nと書かれていました。",
	"ページを開くと、\nそこには見たことのない植物が\nたくさん描かれていました。\n\nぷっくりした葉。\n変わったかたち。\n不思議な色。\n\nそこには、\n「多肉植物」という言葉が。\n\n「こんな植物、本当にあったのかな……」",
	"そこへパンダが、\n古い倉庫で見つけた\nタネの袋を持ってきました。\n\n「これ、なんのタネだろう？」\n\n図鑑と見くらべて、\n3人は顔を見合わせました。\n\n「もしかして……\nこの植物のタネかもしれない」\n\nそこで3人は、\nタネを分けて蒔いてみることにしました。\n\n「どんな植物が育つんだろう——」"
]
const PAGE_FONT_SIZES := [20, 20, 17, 14]

var current_page_index := -1
var replay_mode := false
var transitioning := false
var page_image: TextureRect
var text_panel: Panel
var story_text: Label
var page_count_label: Label
var tap_area: Button
var page_tween: Tween

func _ready() -> void:
	name = "OpeningStoryOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 900
	_build_ui()
	visible = false

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#1b100c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	page_image = TextureRect.new()
	page_image.name = "StoryImage"
	page_image.position = Vector2.ZERO
	page_image.size = Vector2(576, 768)
	page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_image)

	text_panel = Panel.new()
	text_panel.name = "StoryTextPanel"
	text_panel.position = Vector2(0, 590)
	text_panel.size = Vector2(576, 434)
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.105, 0.055, 0.035, 0.92)
	panel_style.border_color = Color(0.89, 0.68, 0.39, 0.48)
	panel_style.border_width_top = 2
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.shadow_color = Color(0.04, 0.02, 0.01, 0.35)
	panel_style.shadow_size = 8
	text_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(text_panel)

	story_text = Label.new()
	story_text.name = "StoryText"
	story_text.position = Vector2(36, 604)
	story_text.size = Vector2(504, 358)
	story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_text.add_theme_color_override("font_color", Color("#fff6df"))
	story_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	story_text.add_theme_constant_override("shadow_offset_x", 1)
	story_text.add_theme_constant_override("shadow_offset_y", 2)
	story_text.add_theme_constant_override("line_spacing", 1)
	story_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_text)

	page_count_label = Label.new()
	page_count_label.name = "StoryPageCount"
	page_count_label.position = Vector2(454, 24)
	page_count_label.size = Vector2(90, 38)
	page_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page_count_label.add_theme_font_size_override("font_size", 15)
	page_count_label.add_theme_color_override("font_color", Color("#fff4da"))
	page_count_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03, 0.82))
	page_count_label.add_theme_constant_override("outline_size", 5)
	page_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_count_label)

	var hint := Label.new()
	hint.name = "StoryTapHint"
	hint.text = "タップしてつぎへ"
	hint.position = Vector2(148, 970)
	hint.size = Vector2(280, 36)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("#d9c8aa"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	tap_area = Button.new()
	tap_area.name = "StoryTapArea"
	tap_area.flat = true
	tap_area.focus_mode = Control.FOCUS_NONE
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap_area.pressed.connect(advance_page)
	add_child(tap_area)

func start(as_replay := false, start_page := 0) -> void:
	if page_tween and page_tween.is_valid():
		page_tween.kill()
	replay_mode = as_replay
	transitioning = false
	visible = true
	move_to_front()
	_show_page(clampi(start_page, 0, PAGE_TEXTURES.size() - 1))

func advance_page() -> void:
	if not visible or transitioning:
		return
	if current_page_index >= PAGE_TEXTURES.size() - 1:
		visible = false
		story_finished.emit(replay_mode)
		return
	transitioning = true
	page_tween = create_tween().set_parallel()
	page_tween.tween_property(page_image, "modulate:a", 0.0, 0.09)
	page_tween.tween_property(story_text, "modulate:a", 0.0, 0.09)
	page_tween.finished.connect(_swap_to_next_page, CONNECT_ONE_SHOT)

func _swap_to_next_page() -> void:
	_show_page(current_page_index + 1)
	page_image.modulate.a = 0.0
	story_text.modulate.a = 0.0
	page_tween = create_tween().set_parallel()
	page_tween.tween_property(page_image, "modulate:a", 1.0, 0.16)
	page_tween.tween_property(story_text, "modulate:a", 1.0, 0.16)
	page_tween.finished.connect(_finish_page_transition, CONNECT_ONE_SHOT)

func _finish_page_transition() -> void:
	transitioning = false

func _show_page(index: int) -> void:
	current_page_index = index
	page_image.texture = PAGE_TEXTURES[index]
	page_image.modulate = Color.WHITE
	if index==3:
		text_panel.position.y=526
		text_panel.size.y=498
		story_text.position.y=540
		story_text.size.y=414
	else:
		text_panel.position.y=590
		text_panel.size.y=434
		story_text.position.y=604
		story_text.size.y=358
	story_text.text = PAGE_TEXTS[index]
	story_text.add_theme_font_size_override("font_size", int(PAGE_FONT_SIZES[index]))
	story_text.modulate = Color.WHITE
	page_count_label.text = "%d / %d" % [index + 1, PAGE_TEXTURES.size()]
