extends Node

const CARD_SIZE := Vector2(252, 274)
const CONTENT_SIZE := Vector2(232, 266)
const IMAGE_FRAME_SIZE := Vector2(232, 137)
const CENTER_TOLERANCE := 0.01

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	game.encyclopedia_overlay.visible = true
	game.encyclopedia_series_page.visible = true
	game.current_encyclopedia_series_id = "jurejure"
	var entries: Array[Dictionary] = game._catalog_display_entries_for_series("jurejure")
	assert(entries.size() >= 16)
	for entry in entries:
		var species_id := str(entry.get("species_id", ""))
		game.discovered[species_id] = true
		game.species_get_counts[species_id] = 1
		game.bests[species_id] = 12.3

	var long_index := -1
	var long_hiragana := ""
	var long_english := ""
	for locale in ["ja", "hiragana", "en"]:
		game.language_code = locale
		game._refresh_encyclopedia_cards()
		await get_tree().process_frame
		await get_tree().process_frame
		assert(game.encyclopedia_grid.columns == 2)
		assert(game.encyclopedia_grid.size.x == 536.0)
		assert(game.encyclopedia_grid.get_child_count() == entries.size())
		for index in range(entries.size()):
			var expected_name: String = game.Localizer.species_name(locale, entries[index])
			_assert_card_layout(game, index, expected_name)
			if str(entries[index].get("species_id", "")) == "hyb_jure_sea":
				long_index = index
				var long_label: Label = game.encyclopedia_grid.get_child(index).find_child("SpeciesCardName", true, false)
				if locale == "hiragana":
					long_hiragana = long_label.text
					assert(long_label.get_line_count() == 2)
				elif locale == "en":
					long_english = long_label.text
					assert(long_label.get_line_count() == 2)
		assert(game.encyclopedia_grid.get_child(0).position.x == 0.0)
		assert(game.encyclopedia_grid.get_child(1).position.x == 264.0)
		assert(game.encyclopedia_grid.get_child(2).position.y == 288.0)

	assert(long_index >= 0)
	assert(long_hiragana == "ごうかきゃくせんのりたいなろぜっと")
	assert(long_english == "Luxury Cruise Dream Rosette")

	# The longest Japanese catalog name lives on the original-species page.
	game.current_encyclopedia_series_id = "base"
	game.language_code = "ja"
	var base_entries: Array[Dictionary] = game._catalog_display_entries_for_series("base")
	var longest_japanese_index := -1
	for index in range(base_entries.size()):
		var base_id := str(base_entries[index].get("species_id", ""))
		game.discovered[base_id] = true
		game.species_get_counts[base_id] = 1
		if base_id == "hyalina_san_luis_de_la_paz":
			longest_japanese_index = index
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(longest_japanese_index >= 0)
	for index in range(base_entries.size()):
		_assert_card_layout(game, index, game.Localizer.species_name("ja", base_entries[index]))
	var longest_japanese_label: Label = game.encyclopedia_grid.get_child(longest_japanese_index).find_child("SpeciesCardName", true, false)
	assert(longest_japanese_label.text == "ヒアリナ・サン・ルイス・デ・ラパス")
	assert(longest_japanese_label.get_line_count() == 2)

	game.current_encyclopedia_series_id = "jurejure"
	game.language_code = "hiragana"
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	await get_tree().process_frame

	# Unknown entries use the same fixed image slot and must not shift the column.
	var unknown_id := str(entries[0].get("species_id", ""))
	game.discovered.erase(unknown_id)
	game.species_get_counts.erase(unknown_id)
	game.bests.erase(unknown_id)
	game.language_code = "hiragana"
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_card_layout(game, 0, "？？？")
	assert(game.encyclopedia_grid.get_child(0).disabled)

	# Scrolling and a delayed texture replacement must not affect the center.
	game.discovered[unknown_id] = true
	game.species_get_counts[unknown_id] = 1
	game._refresh_encyclopedia_cards()
	await get_tree().process_frame
	await get_tree().process_frame
	game.encyclopedia_scroll.scroll_vertical = 1800
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.encyclopedia_scroll.scroll_vertical > 0)
	_assert_card_layout(game, long_index, game.Localizer.species_name("hiragana", entries[long_index]))
	var delayed_image: TextureRect = game.encyclopedia_card_images[long_index]
	var delayed_path: String = game._species_image_path(entries[long_index])
	var delayed_texture: Texture2D = load(delayed_path)
	assert(delayed_texture != null)
	delayed_image.texture = null
	delayed_image.set_meta("catalog_request_path", delayed_path)
	game._apply_requested_species_texture(delayed_texture, delayed_image, delayed_path)
	await get_tree().process_frame
	assert(delayed_image.texture == delayed_texture)
	_assert_card_layout(game, long_index, game.Localizer.species_name("hiragana", entries[long_index]))

	# The project renders a fixed 576x1024 canvas on different iPhone sizes.
	# Verify that device-scale transforms preserve the same horizontal center.
	for ui_scale in [0.75, 1.0, 1.25]:
		game.encyclopedia_overlay.scale = Vector2.ONE * ui_scale
		await get_tree().process_frame
		_assert_card_layout(game, long_index, game.Localizer.species_name("hiragana", entries[long_index]))
	game.encyclopedia_overlay.scale = Vector2.ONE

	print("ENCYCLOPEDIA_CARD_LAYOUT_SMOKE_OK cards=", entries.size(), " long_index=", long_index)
	get_tree().quit()

func _assert_card_layout(game: Node, index: int, expected_name: String) -> void:
	var card: Button = game.encyclopedia_grid.get_child(index)
	var content: Control = card.find_child("SpeciesCardContent", true, false)
	var frame: MarginContainer = card.find_child("SpeciesCardImageFrame", true, false)
	var image: TextureRect = card.find_child("SpeciesCardImage", true, false)
	var name_label: Label = card.find_child("SpeciesCardName", true, false)
	var best_label: Label = card.find_child("SpeciesCardBest", true, false)
	var get_label: Label = card.find_child("SpeciesCardGetCount", true, false)
	var star_label: Label = card.find_child("SpeciesCardStars", true, false)
	assert(card.size.is_equal_approx(CARD_SIZE), "card %d size=%s" % [index, card.size])
	assert(content.size.is_equal_approx(CONTENT_SIZE), "card %d content=%s" % [index, content.size])
	assert(frame.size.is_equal_approx(IMAGE_FRAME_SIZE), "card %d frame=%s" % [index, frame.size])
	assert(image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert(absf(_center_x(card) - _center_x(frame)) <= CENTER_TOLERANCE, "card %d frame delta=%s" % [index, _center_x(frame) - _center_x(card)])
	assert(absf(_center_x(card) - _center_x(image)) <= CENTER_TOLERANCE, "card %d image delta=%s" % [index, _center_x(image) - _center_x(card)])
	assert(frame.get_global_rect().get_center().distance_to(image.get_global_rect().get_center()) <= CENTER_TOLERANCE, "card %d texture rect is not centered in its frame" % index)
	assert(name_label.text == expected_name)
	assert(name_label.size.x == CONTENT_SIZE.x)
	assert(name_label.get_line_count() >= 1 and name_label.get_line_count() <= 2, "card %d name lines=%d text=%s" % [index, name_label.get_line_count(), name_label.text])
	assert(name_label.size.y + CENTER_TOLERANCE >= name_label.get_combined_minimum_size().y, "card %d name height=%s min=%s" % [index, name_label.size.y, name_label.get_combined_minimum_size().y])
	assert(name_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	assert(name_label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and not name_label.clip_text)
	assert(frame.position.y + frame.size.y <= name_label.position.y + CENTER_TOLERANCE)
	assert(name_label.position.y + name_label.size.y <= best_label.position.y + CENTER_TOLERANCE)
	assert(best_label.position.y + best_label.size.y <= get_label.position.y + CENTER_TOLERANCE)
	assert(get_label.position.y + get_label.size.y <= star_label.position.y + CENTER_TOLERANCE)
	assert(star_label.position.y + star_label.size.y <= content.size.y + CENTER_TOLERANCE)

func _center_x(control: Control) -> float:
	return control.get_global_rect().get_center().x
