extends Node

const StoryContinueButtonStyleClass = preload("res://scripts/story_continue_button_style.gd")

var press_count := 0
var down_count := 0
var up_count := 0
var button: Button


func _ready() -> void:
	var surface := Control.new()
	surface.size = Vector2(576, 1024)
	add_child(surface)
	button = Button.new()
	button.text = "つづける"
	button.position = Vector2(160, 420)
	button.size = StoryContinueButtonStyleClass.BUTTON_SIZE
	StoryContinueButtonStyleClass.apply(button)
	button.pressed.connect(func() -> void: press_count += 1)
	button.button_down.connect(func() -> void: down_count += 1)
	button.button_up.connect(func() -> void: up_count += 1)
	surface.add_child(button)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_style_contract()
	await _test_mouse_tap_and_hold()
	await _test_touch_tap_and_hold()
	print("STORY_CONTINUE_BUTTON_STYLE_SMOKE_OK border=stable focus_outline=none keyboard_focus=preserved mouse=single_release touch=single_release hold=no_repeat")
	get_tree().quit()


func _assert_style_contract() -> void:
	var styles := {
		"normal": button.get_theme_stylebox("normal"),
		"hover": button.get_theme_stylebox("hover"),
		"pressed": button.get_theme_stylebox("pressed"),
		"hover_pressed": button.get_theme_stylebox("hover_pressed"),
		"disabled": button.get_theme_stylebox("disabled"),
	}
	for state_name in styles:
		var style := styles[state_name] as StyleBoxFlat
		assert(style != null)
		assert(style.border_color.is_equal_approx(StoryContinueButtonStyleClass.BORDER_COLOR), "%s border changed" % state_name)
		assert(style.border_width_left == StoryContinueButtonStyleClass.BORDER_WIDTH)
	assert((styles["normal"] as StyleBoxFlat).bg_color.is_equal_approx(StoryContinueButtonStyleClass.BACKGROUND_COLOR))
	assert((styles["hover"] as StyleBoxFlat).bg_color.is_equal_approx(StoryContinueButtonStyleClass.BACKGROUND_COLOR))
	assert((styles["pressed"] as StyleBoxFlat).bg_color.is_equal_approx(StoryContinueButtonStyleClass.PRESSED_BACKGROUND_COLOR))
	assert((styles["hover_pressed"] as StyleBoxFlat).bg_color.is_equal_approx(StoryContinueButtonStyleClass.PRESSED_BACKGROUND_COLOR))
	assert(button.get_theme_stylebox("focus") is StyleBoxEmpty)
	assert(button.focus_mode == Control.FOCUS_ALL)
	button.grab_focus()
	assert(button.has_focus())
	button.release_focus()
	assert(button.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE)
	assert(not button.toggle_mode and not button.keep_pressed_outside)


func _test_mouse_tap_and_hold() -> void:
	var center := button.get_global_rect().get_center()
	_push_mouse_motion(center)
	await get_tree().process_frame
	assert(button.get_draw_mode() == BaseButton.DRAW_HOVER)
	_push_mouse_button(center, true)
	await get_tree().process_frame
	assert(button.get_draw_mode() == BaseButton.DRAW_PRESSED)
	for frame in range(8):
		await get_tree().process_frame
	assert(press_count == 0 and down_count == 1 and up_count == 0)
	_push_mouse_button(center, false)
	await get_tree().process_frame
	assert(press_count == 1 and down_count == 1 and up_count == 1)
	assert(button.get_draw_mode() == BaseButton.DRAW_HOVER)
	for frame in range(4):
		await get_tree().process_frame
	assert(press_count == 1)
	_push_mouse_button(center, true)
	_push_mouse_button(center, false)
	await get_tree().process_frame
	assert(press_count == 2 and down_count == 2 and up_count == 2)


func _test_touch_tap_and_hold() -> void:
	var before_press := press_count
	var before_down := down_count
	var before_up := up_count
	var center := button.get_global_rect().get_center()
	_push_touch(center, true)
	await get_tree().process_frame
	for frame in range(8):
		await get_tree().process_frame
	assert(press_count == before_press)
	_push_touch(center, false)
	await get_tree().process_frame
	assert(press_count == before_press + 1)
	assert(down_count == before_down + 1 and up_count == before_up + 1)


func _push_mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)


func _push_mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)


func _push_touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = position
	get_viewport().push_input(event, true)
