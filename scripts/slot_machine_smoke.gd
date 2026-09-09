extends Node

const SlotMachineScene = preload("res://scenes/slot_machine.tscn")
const EXPECTED_SYMBOLS := ["succulent", "seed_bag", "pot", "panda", "mystery_pod", "puku_coin"]

func _ready() -> void:
	var slot = SlotMachineScene.instantiate()
	add_child(slot)
	await get_tree().process_frame
	await get_tree().process_frame

	assert(slot.background_layer.texture.resource_path == "res://assets/slot/slot-machine-background.jpg")
	assert(slot.background_layer.get_index() < slot.reel_layer.get_index())
	assert(slot.reel_layer.get_index() < slot.glass_layer.get_index())
	assert(slot.reels.size() == 3)
	assert(slot.stop_buttons.size() == 3)
	assert(slot.glass_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(slot.prize_layer.name == "FuturePrizeLayer")
	assert(slot.prize_layer.get_child_count() == 0)
	assert(not slot.preview_lamp.is_lit)
	assert(not slot.spin_button.disabled)
	for index in range(slot.reels.size()):
		assert(slot.reels[index].position == slot.REEL_RECTS[index].position)
		assert(slot.reels[index].size == slot.REEL_RECTS[index].size)
		assert(slot.stop_buttons[index].size.x >= 94.0 and slot.stop_buttons[index].size.y >= 94.0)

	var symbol_ids: Array[String] = []
	for symbol in slot.ReelClass.SYMBOLS:
		symbol_ids.append(str(symbol.id))
	assert(symbol_ids == EXPECTED_SYMBOLS)

	var viewport_size := get_viewport().get_visible_rect().size
	var expected_fit := minf(viewport_size.x / slot.DESIGN_SIZE.x, viewport_size.y / slot.DESIGN_SIZE.y)
	assert(is_equal_approx(slot.design_root.scale.x, expected_fit))
	assert(is_equal_approx(slot.design_root.scale.y, expected_fit))

	for reel in slot.reels:
		reel.stop_duration = 0.08
	slot.preview_hit_chance = 0.0
	slot.lamp_timing = "all_stopped"
	var forced_win: Array[String] = ["puku_coin", "puku_coin", "puku_coin"]
	slot.set_next_spin_result_for_test(forced_win)
	slot.spin()
	assert(slot.spin_button.disabled)
	assert(not slot.stop_buttons[0].disabled)
	assert(slot.stop_buttons[1].disabled and slot.stop_buttons[2].disabled)
	for reel in slot.reels:
		assert(reel.is_moving())

	slot.stop_reel(0)
	assert(not slot.stop_buttons[1].disabled)
	slot.stop_reel(1)
	assert(not slot.stop_buttons[2].disabled)
	slot.stop_reel(2)
	await get_tree().create_timer(0.16).timeout
	for reel in slot.reels:
		assert(not reel.is_moving())
		assert(reel.centered_symbol_id == "puku_coin")
		assert(reel.center_alignment_error() < 0.01)
	assert(slot.stopped_results == ["puku_coin", "puku_coin", "puku_coin"])
	assert(slot.preview_lamp.is_lit)
	assert(not slot.spin_button.disabled)

	slot.clear_hit_preview("smoke")
	assert(not slot.preview_lamp.is_lit)
	slot.trigger_hit_preview("smoke")
	assert(slot.preview_lamp.is_lit)
	print("SLOT_MACHINE_SMOKE_OK reels=3 symbols=", symbol_ids.size(), " scale=", expected_fit)
	get_tree().quit()
