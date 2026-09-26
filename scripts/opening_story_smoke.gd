extends Node

const OpeningStoryOverlayClass=preload("res://scripts/opening_story_overlay.gd")
const Localizer=preload("res://scripts/game_localizer.gd")

func _ready()->void:
	var story_font:Font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf")
	for locale in Localizer.SUPPORTED_LANGUAGES:
		for key in OpeningStoryOverlayClass.PAGE_TEXT_KEYS:
			var page_text:=Localizer.text(locale,key)
			assert(not page_text.is_empty())
			if locale=="ja":
				for character_index in range(page_text.length()):
					var codepoint:=page_text.unicode_at(character_index)
					if codepoint!=10:assert(story_font.has_char(codepoint))
	assert("別の場所" in Localizer.text("ja","opening_story_4"))
	assert("古い植物の本" in Localizer.text("ja","opening_story_2"))
	assert("原種図鑑" not in Localizer.text("ja","opening_story_2"))
	assert(not "売れ残った" in Localizer.text("ja","intro_old_seed"))
	assert("正体不明" not in Localizer.text("ja","intro_old_seed_get"))
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state();game.opening_story_complete=false;game.intro_story_complete=false;game.language_selected=false;game._show_opening()
	assert(game.opening_language_panel.visible and game.opening_tap_area.disabled)
	assert(not game.opening_prompt.visible and not game.opening_prompt_localized.visible)
	game._finish_opening();await get_tree().process_frame
	assert(game.opening_overlay.visible and not game.opening_story_overlay.visible)
	game._select_initial_language("ja")
	assert(game.language_selected and not game.opening_language_panel.visible and not game.opening_tap_area.disabled and game.opening_prompt.visible)
	game._finish_opening();await get_tree().process_frame;await get_tree().process_frame
	var story=game.opening_story_overlay
	assert(story.visible and story.current_page_index==0 and game.audio_manager.current_bgm_key.is_empty())
	assert(story.page_image.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and story.page_image.size==Vector2(576,768))
	assert(story.story_text.position.x==26.0 and story.story_text.size.x==524.0 and story.story_text.horizontal_alignment==HORIZONTAL_ALIGNMENT_LEFT)
	assert(story.story_text.get_theme_font_size("font_size")==18)
	for expected_page in range(4):
		assert(story.current_page_index==expected_page)
		assert(story.page_image.texture.resource_path=="res://assets/opening_story/page-%d.jpg"%[expected_page+1])
		assert(story.story_text.text==Localizer.text("ja",OpeningStoryOverlayClass.PAGE_TEXT_KEYS[expected_page]))
		assert(story.page_count_label.text=="%d / 4"%[expected_page+1])
		story.advance_page()
		if expected_page<3:await get_tree().create_timer(.3).timeout
	assert(story.visible and story.transitioning)
	await get_tree().create_timer(.35).timeout;await get_tree().process_frame;await get_tree().process_frame
	assert(not story.visible and game.opening_story_complete and game.intro_overlay.visible and not game.shop_overlay.visible)
	assert(game.current_mode=="greenhouse" and game.audio_manager.current_bgm_key=="greenhouse")
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(saved is Dictionary and bool(saved.get("opening_story_complete",false)) and bool(saved.get("language_selected",false)))
	game.intro_overlay.visible=false;game.shop_overlay.visible=false;game.language_code="en";game._replay_opening_story_for_development()
	assert(story.visible and story.replay_mode and story.current_page_index==0 and story.story_text.text==Localizer.text("en","opening_story_1"))
	assert(game.settings_overlay.find_child("OpeningStoryReplay",true,false)!=null)
	game.free();await get_tree().process_frame
	print("OPENING_STORY_SMOKE_OK language_first=true pages=4 layout=wide_left fade=true greenhouse=true locales=3 save=true")
	get_tree().quit()
