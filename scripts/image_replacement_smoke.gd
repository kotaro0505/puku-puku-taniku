extends Node

const SucculentClass = preload("res://scripts/succulent.gd")

const MAIN_SPRITES := {
	"colorata": "res://assets/plants/sprite-colorata.png",
	"juliana": "res://assets/plants/sprite-carnicolor-glau-grey.png",
	"tovarensis_tovar": "res://assets/plants/sprite-tovarensis-tovar.png",
	"jewel_opal_rosette": "res://assets/catalog/jewel/jewel-opal-rosette.png",
}

const HABITAT_SPRITES := {
	"colorata": "res://assets/plants/habitat/sprite-colorata.png",
	"juliana": "res://assets/plants/habitat/sprite-carnicolor-glau-grey.png",
	"tovarensis_tovar": "res://assets/plants/habitat/sprite-tovarensis-tovar.png",
}


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/species-v2.json"))
	assert(parsed is Array)
	var species: Array = parsed
	var colorata := _entry(species, "colorata")
	var carnicolor := _entry(species, "juliana")
	var tovar := _entry(species, "tovarensis_tovar")
	var opal := _entry(species, "jewel_opal_rosette")

	assert(str(colorata.get("name_ja", "")) == "コロラータ")
	assert(str(carnicolor.get("name_ja", "")) == "カルニカラー グラウグレイ")
	assert(str(carnicolor.get("name_hiragana", "")) == "かるにからー ぐらうぐれい")
	assert(str(carnicolor.get("name_en", "")) == "Carnicolor Glau Grey")
	assert(str(tovar.get("name_ja", "")) == "トバレンシス・トバー")
	assert(str(opal.get("name_ja", "")) == "オパールロゼット")

	# The former Juliana save/progression key deliberately remains unchanged.
	assert(str(carnicolor.get("species_id", "")) == "juliana")
	assert(is_equal_approx(float(carnicolor.get("spawn_weight", 0.0)), 17.0))
	assert(is_equal_approx(float(carnicolor.get("base_growth_rate", 0.0)), 1.02))
	assert(is_equal_approx(float(carnicolor.get("jelly_risk_curve", 0.0)), 0.99))
	assert(str(carnicolor.get("series_id", "")) == "base")

	for species_id in MAIN_SPRITES:
		var path := str(MAIN_SPRITES[species_id])
		assert(str(SucculentClass.SPRITES.get(species_id, "")) == path)
		_assert_transparent_source(path, Vector2i(1254, 1254))

	for species_id in HABITAT_SPRITES:
		var path := str(HABITAT_SPRITES[species_id])
		var entry := _entry(species, species_id)
		assert(str(entry.get("habitat_image_path", "")) == path)
		_assert_transparent_source(path, Vector2i(1254, 1254))
		var texture := load(path) as Texture2D
		assert(texture != null and texture.get_size() == Vector2(320, 320))

	assert(str(SucculentClass.SPRITES.get("lutea", "")) == "res://assets/plants/sprite-lutea.png")
	_assert_shop_backgrounds()
	print("IMAGE_REPLACEMENT_SMOKE_OK plants=4 transparent=true habitat=320 shop=720x1280 save_ids=stable")
	get_tree().quit()


func _entry(species: Array, species_id: String) -> Dictionary:
	for entry_value in species:
		if entry_value is Dictionary and str(entry_value.get("species_id", "")) == species_id:
			return entry_value
	assert(false, "Missing species: %s" % species_id)
	return {}


func _assert_transparent_source(path: String, expected_size: Vector2i) -> void:
	assert(FileAccess.file_exists(path) and ResourceLoader.exists(path))
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null)
	var image := Image.new()
	assert(image.load_png_from_buffer(file.get_buffer(file.get_length())) == OK)
	assert(image.get_size() == expected_size)
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	assert(image.get_pixel(0, 0).a <= 0.001)
	assert(image.get_pixel(image.get_width() - 1, 0).a <= 0.001)
	assert(image.get_pixel(0, image.get_height() - 1).a <= 0.001)
	assert(image.get_pixel(image.get_width() - 1, image.get_height() - 1).a <= 0.001)
	assert(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a >= 0.99)


func _assert_shop_backgrounds() -> void:
	var default_path := "res://assets/shop-background-final.jpg"
	var armadillo_path := "res://assets/shop-background-armadillo.jpg"
	assert(FileAccess.get_file_as_bytes(default_path) == FileAccess.get_file_as_bytes(armadillo_path))
	for path in [default_path, armadillo_path]:
		var texture := load(path) as Texture2D
		assert(texture != null and texture.get_size() == Vector2(720, 1280))
