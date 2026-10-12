class_name StandardStoryDialoguePanel
extends PanelContainer

const StoryContinueButtonStyleClass = preload("res://scripts/story_continue_button_style.gd")

const PANEL_SIZE := Vector2(496, 255)
const DEFAULT_POSITION := Vector2(40, 725)
const PANEL_BACKGROUND := Color(0.97, 0.90, 0.75, 0.96)
const PANEL_BORDER := Color("#a86f36")
const TEXT_COLOR := Color("#4a2618")
const SPEAKER_COLOR := Color("#8b5528")

var portrait_slot: Control
var speaker_portrait: TextureRect
var speaker_label: Label
var dialogue_label: Label
var continue_button: Button


func _init() -> void:
	name = "StoryTextPanel"
	position = DEFAULT_POSITION
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", _panel_style())

	var dialogue_row := HBoxContainer.new()
	dialogue_row.name = "StoryDialogueRow"
	dialogue_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dialogue_row.add_theme_constant_override("separation", 12)
	dialogue_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_row)

	portrait_slot = Control.new()
	portrait_slot.name = "StoryPortraitSlot"
	portrait_slot.custom_minimum_size = Vector2(132, 205)
	portrait_slot.clip_contents = true
	portrait_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_row.add_child(portrait_slot)

	speaker_portrait = TextureRect.new()
	speaker_portrait.name = "SpeakerPortrait"
	speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speaker_portrait.offset_top = 32.0
	speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_slot.add_child(speaker_portrait)

	speaker_label = Label.new()
	speaker_label.name = "StorySpeaker"
	speaker_label.position = Vector2.ZERO
	speaker_label.size = Vector2(132, 30)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", SPEAKER_COLOR)
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.z_index = 2
	portrait_slot.add_child(speaker_label)

	var content := VBoxContainer.new()
	content.name = "StoryDialogueContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_row.add_child(content)

	dialogue_label = Label.new()
	dialogue_label.name = "StoryText"
	dialogue_label.custom_minimum_size = Vector2(300, 90)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 20)
	dialogue_label.add_theme_color_override("font_color", TEXT_COLOR)
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(dialogue_label)

	continue_button = Button.new()
	continue_button.name = "StoryContinueButton"
	StoryContinueButtonStyleClass.apply(continue_button)
	content.add_child(continue_button)


func set_speaker(display_name: String, portrait: Texture2D) -> void:
	var has_speaker := not display_name.is_empty() or portrait != null
	portrait_slot.visible = has_speaker
	speaker_label.text = display_name
	speaker_label.visible = not display_name.is_empty()
	speaker_portrait.texture = portrait
	speaker_portrait.visible = portrait != null


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.18, 0.08, 0.02, 0.34)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
