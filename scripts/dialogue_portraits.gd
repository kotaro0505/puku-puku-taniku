class_name DialoguePortraits
extends RefCounted

const PANDA_TEXTURE: Texture2D = preload("res://assets/panda-clerk.png")
const ARMADILLO_TEXTURE: Texture2D = preload("res://assets/armadillo-dialogue.png")
const GIRL_TEXTURE: Texture2D = preload("res://assets/dialogue/girl-dialogue.png")


static func texture(speaker_id: String) -> Texture2D:
	match speaker_id:
		"panda":
			var portrait := AtlasTexture.new()
			portrait.atlas = PANDA_TEXTURE
			portrait.region = Rect2(0.0, 0.0, PANDA_TEXTURE.get_width(), PANDA_TEXTURE.get_height() * 0.70)
			return portrait
		"armadillo":
			return ARMADILLO_TEXTURE
		"girl":
			return GIRL_TEXTURE
		_:
			return null


static func speaker_id_from_key(speaker_key: String) -> String:
	match speaker_key:
		"story_speaker_panda", "panda_shop_name":
			return "panda"
		"story_speaker_armadillo", "armadillo_name":
			return "armadillo"
		"story_speaker_girl":
			return "girl"
		_:
			return ""
