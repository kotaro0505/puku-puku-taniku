extends Node

const FusionLabUIClass = preload("res://scripts/fusion_lab_ui.gd")
const ArrangementUIClass = preload("res://scripts/arrangement_ui.gd")
const SPECIES_COUNT := 320

var probe_texture: ImageTexture
var texture_request_count := 0
var requested_species_ids: Dictionary = {}
var selected_fusion_slot := -1
var selected_fusion_species_id := ""


func _ready() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color("#7fa78f"))
	probe_texture = ImageTexture.create_from_image(image)
	var entries := _probe_entries()
	await _test_fusion_picker(entries)
	await _test_arrangement_picker(entries)
	print("PICKER_PERFORMANCE_SMOKE_OK species=%d fusion_visible_requests<=8 arrangement_visible_requests<=16 cache=reused offscreen=released selection=pass" % SPECIES_COUNT)
	get_tree().quit()


func _probe_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for index in range(SPECIES_COUNT):
		entries.append({
			"species_id": "performance_species_%03d" % index,
			"name_ja": "計測品種%03d" % index,
			"name_hiragana": "けいそくひんしゅ%03d" % index,
			"name_en": "Performance Species %03d" % index,
			"series_id": "base",
			"image_path": "res://assets/catalog/hybrid/hyb_gummy_gummy.png",
		})
	return entries


func _test_fusion_picker(entries: Array[Dictionary]) -> void:
	texture_request_count = 0
	requested_species_ids.clear()
	var ui := FusionLabUIClass.new()
	add_child(ui)
	ui.candidate_image_requested.connect(_on_probe_texture_requested)
	ui.parent_selected.connect(_on_probe_parent_selected)
	var counts: Dictionary = {}
	for entry in entries:
		counts[str(entry.get("species_id", ""))] = 1
	ui.open_lab(entries, counts)
	var opened_usec := Time.get_ticks_usec()
	ui._open_picker(0)
	var first_open_msec := float(Time.get_ticks_usec() - opened_usec) / 1000.0
	assert(ui.candidate_cards_by_id.size() == SPECIES_COUNT)
	assert(texture_request_count == 0, "fusion picker requested every image before its first frame")
	await _wait_for_lazy_picker_update()
	var initial_requests := texture_request_count
	assert(initial_requests > 0 and initial_requests <= 8)
	assert(_requested_card_count(ui.candidate_cards_by_id) <= 8)
	var first_card := ui.candidate_cards_by_id[str(entries[0].get("species_id", ""))] as Button
	ui.picker_scroll.scroll_vertical = 100000
	await _wait_for_lazy_picker_update()
	assert(ui.picker_scroll.scroll_vertical > 0)
	assert(not bool(first_card.get_meta("image_requested", false)))
	assert(texture_request_count > initial_requests and texture_request_count <= 20)
	var last_species_id := str(entries[-1].get("species_id", ""))
	(ui.candidate_cards_by_id[last_species_id] as Button).pressed.emit()
	assert(selected_fusion_slot == 0 and selected_fusion_species_id == last_species_id)
	print("PICKER_PERFORMANCE_PROFILE fusion species=%d first_open_ms=%.3f initial_requests=%d total_after_bottom=%d" % [SPECIES_COUNT, first_open_msec, initial_requests, texture_request_count])
	ui.queue_free()
	await get_tree().process_frame


func _test_arrangement_picker(entries: Array[Dictionary]) -> void:
	texture_request_count = 0
	requested_species_ids.clear()
	var ui := ArrangementUIClass.new()
	add_child(ui)
	var discovered: Dictionary = {}
	for entry in entries:
		discovered[str(entry.get("species_id", ""))] = true
	ui.configure(entries, [], [{"pot_id": "performance_pot"}], discovered, {"performance_pot": 1}, [], 50, 0, _resolve_probe_texture, _on_probe_texture_requested)
	ui.current_arrangement = {"arrangement_id": "performance", "pot_id": "performance_pot", "plants": []}
	ui.visible = true
	var opened_usec := Time.get_ticks_usec()
	ui._open_species_picker()
	var first_open_msec := float(Time.get_ticks_usec() - opened_usec) / 1000.0
	assert(ui.picker_cards_by_id.size() == SPECIES_COUNT)
	assert(texture_request_count == 0, "arrangement picker requested every image before its first frame")
	var first_species_id := str(entries[0].get("species_id", ""))
	var first_card := ui.picker_cards_by_id[first_species_id] as Button
	var first_card_instance_id := first_card.get_instance_id()
	await _wait_for_lazy_picker_update()
	var initial_requests := texture_request_count
	assert(initial_requests > 0 and initial_requests <= 16)
	assert(_requested_card_count(ui.picker_cards_by_id) <= 16)
	ui.picker_scroll.scroll_vertical = 100000
	await _wait_for_lazy_picker_update()
	assert(ui.picker_scroll.scroll_vertical > 0)
	assert(not bool(first_card.get_meta("image_requested", false)))
	assert(texture_request_count > initial_requests and texture_request_count <= 32)
	ui._return_to_editor()
	opened_usec = Time.get_ticks_usec()
	ui._open_species_picker()
	var cached_open_msec := float(Time.get_ticks_usec() - opened_usec) / 1000.0
	assert((ui.picker_cards_by_id[first_species_id] as Button).get_instance_id() == first_card_instance_id)
	(ui.picker_cards_by_id[first_species_id] as Button).pressed.emit()
	assert(ui.editor_plants.size() == 1 and str(ui.editor_plants[0].get("species_id", "")) == first_species_id)
	print("PICKER_PERFORMANCE_PROFILE arrangement species=%d first_open_ms=%.3f cached_open_ms=%.3f initial_requests=%d total_after_bottom=%d" % [SPECIES_COUNT, first_open_msec, cached_open_msec, initial_requests, texture_request_count])
	ui.queue_free()
	await get_tree().process_frame


func _wait_for_lazy_picker_update() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _requested_card_count(cards_by_id: Dictionary) -> int:
	var count := 0
	for card_value in cards_by_id.values():
		if bool((card_value as Button).get_meta("image_requested", false)):
			count += 1
	return count


func _resolve_probe_texture(_entry: Dictionary) -> Texture2D:
	return probe_texture


func _on_probe_texture_requested(entry: Dictionary, target: TextureRect, _high_priority: bool) -> void:
	texture_request_count += 1
	requested_species_ids[str(entry.get("species_id", ""))] = true
	target.texture = probe_texture


func _on_probe_parent_selected(slot: int, species_id: String) -> void:
	selected_fusion_slot = slot
	selected_fusion_species_id = species_id
