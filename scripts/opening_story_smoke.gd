extends Node

const OpeningStoryOverlayClass=preload("res://scripts/opening_story_overlay.gd")

func _ready()->void:
	var story_font:Font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf")
	for page_text in OpeningStoryOverlayClass.PAGE_TEXTS:
		for character_index in range(page_text.length()):
			var codepoint:=page_text.unicode_at(character_index)
			if codepoint!=10:assert(story_font.has_char(codepoint))
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.opening_story_complete=false;game.intro_story_complete=false
	game._finish_opening();await get_tree().process_frame;await get_tree().process_frame
	var story:OpeningStoryOverlay=game.opening_story_overlay
	assert(story.visible and story.current_page_index==0 and game.audio_manager.current_bgm_key.is_empty())
	assert(story.page_image.texture.resource_path=="res://assets/opening_story/page-1.jpg")
	assert(story.page_image.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED and story.page_image.size==Vector2(576,768))
	assert(story.story_text.text==OpeningStoryOverlayClass.PAGE_TEXTS[0] and story.page_count_label.text=="1 / 4")
	for expected_page in range(1,4):
		story.advance_page();await get_tree().create_timer(.3).timeout
		assert(story.current_page_index==expected_page)
		assert(story.page_image.texture.resource_path=="res://assets/opening_story/page-%d.jpg"%[expected_page+1])
		assert(story.story_text.text==OpeningStoryOverlayClass.PAGE_TEXTS[expected_page])
		assert(story.page_count_label.text=="%d / 4"%[expected_page+1])
	story.advance_page();await get_tree().process_frame;await get_tree().process_frame
	assert(not story.visible and game.opening_story_complete and game.intro_overlay.visible and game.shop_overlay.visible)
	assert(game.audio_manager.current_bgm_key=="shop")
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://records.json"));assert(saved is Dictionary and bool(saved.get("opening_story_complete",false)))
	game.intro_overlay.visible=false;game.shop_overlay.visible=false;game._replay_opening_story_for_development()
	assert(story.visible and story.replay_mode and story.current_page_index==0 and game.opening_story_complete)
	assert(game.settings_overlay.find_child("OpeningStoryReplay",true,false)!=null)
	game.free();await get_tree().process_frame
	print("OPENING_STORY_SMOKE_OK pages=4 exact_order=true silent=true save=true intro_connection=true replay=true")
	get_tree().quit()
