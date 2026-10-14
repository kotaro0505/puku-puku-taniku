extends Node

const Localizer = preload("res://scripts/game_localizer.gd")

const GAME_TITLES := {
	"ja": "ぷくぷく！たにくらいふ",
	"hiragana": "ぷくぷく！たにくらいふ",
	"en": "Puku Puku! Taniku Life",
}
const GAME_TITLES_COMPACT := {
	"ja": "ぷくぷく！\nたにくらいふ",
	"hiragana": "ぷくぷく！\nたにくらいふ",
	"en": "Puku Puku!\nTaniku Life",
}
const ENDING_TITLES := {
	"ja": "あそんでくれてありがとう！\nぷくぷく！たにくらいふ",
	"hiragana": "あそんでくれて ありがとう！\nぷくぷく！たにくらいふ",
	"en": "Thank you for playing!\nPuku Puku! Taniku Life",
}


func _ready() -> void:
	assert(ProjectSettings.get_setting("application/config/name") == GAME_TITLES.ja)
	assert(ProjectSettings.get_setting("application/config/icon") == "res://assets/ios/app-icon-1024.png")
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var original_language := str(game.language_code)
	var main_logo := game.find_child("MainLogo", true, false) as Label
	var main_ribbon := game.find_child("MainLogoRibbon", true, false) as Label
	var opening_background := game.opening_overlay.get_child(0) as TextureRect
	assert(main_logo != null and main_ribbon != null and opening_background != null)
	assert(opening_background.texture != null)
	assert(opening_background.texture.get_size() == Vector2(720, 1280))
	assert(opening_background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(game.find_child("OpeningTitlePanel", true, false) == null)
	var original_language_selected := bool(game.language_selected)
	game.language_selected = false
	game._refresh_opening_prompt()
	game.language_selected = true
	game._refresh_opening_prompt()
	for locale in Localizer.SUPPORTED_LANGUAGES:
		assert(Localizer.text(locale, "game_title") == str(GAME_TITLES[locale]))
		assert(Localizer.text(locale, "game_title_compact") == str(GAME_TITLES_COMPACT[locale]))
		assert(Localizer.text(locale, "game_title_ribbon") == " PUKU PUKU! TANIKU LIFE ")
		assert(Localizer.text(locale, "restoration_thank_you") == str(ENDING_TITLES[locale]))
		assert(Localizer.text(locale, "restoration_product_by") == "Produced by オハナ屋農園")
		game.language_code = locale
		game._apply_language_to_ui()
		assert(main_logo.text == str(GAME_TITLES_COMPACT[locale]))
		assert(main_ribbon.text == Localizer.text(locale, "game_title_ribbon"))
		assert(main_logo.get_minimum_size().x <= main_logo.size.x + 0.5)
		assert(main_logo.get_minimum_size().y <= main_logo.size.y + 0.5)
		assert(main_ribbon.position.x + main_ribbon.get_minimum_size().x < 204.0)
		game.habitat_restoration_ui.set_language(locale)
		assert(game.habitat_restoration_ui.ending_thank_you_label.text == str(ENDING_TITLES[locale]))
		assert(game.habitat_restoration_ui.ending_product_label.text == "Produced by オハナ屋農園")
		assert(game.habitat_restoration_ui.ending_thank_you_label.get_minimum_size().x <= game.habitat_restoration_ui.ending_thank_you_label.size.x)
		assert(game.habitat_restoration_ui.ending_product_label.get_minimum_size().x <= game.habitat_restoration_ui.ending_product_label.size.x)
	game.language_code = original_language
	game.language_selected = original_language_selected
	game._refresh_opening_prompt()
	game._apply_language_to_ui()
	var retired_title := "ぷくぷく" + "多肉"
	for path in ["res://scripts/main.gd", "res://scripts/game_localizer.gd", "res://project.godot", "res://index.html"]:
		assert(not FileAccess.get_file_as_string(path).contains(retired_title))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains('footer.text=Localizer.text(language_code,"game_title")'))
	var icon_file := FileAccess.open("res://assets/ios/app-icon-1024.png", FileAccess.READ)
	assert(icon_file != null)
	var app_icon := Image.new()
	assert(app_icon.load_png_from_buffer(icon_file.get_buffer(icon_file.get_length())) == OK)
	assert(app_icon.get_size() == Vector2i(1024, 1024) and app_icon.detect_alpha() == Image.ALPHA_NONE)
	game.queue_free()
	await get_tree().process_frame
	print("TITLE_BRANDING_SMOKE_OK locales=3 hud=true opening=true ending=true share=true metadata=true icon=1024")
	get_tree().quit()
