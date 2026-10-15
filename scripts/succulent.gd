class_name Succulent
extends Node3D

const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const KakuhenSystemClass = preload("res://scripts/kakuhen_system.gd")

signal harvested(plant: Succulent)
signal jellied(plant: Succulent)

const SPRITES := {
	"laui": "res://assets/plants/sprite-laui.png",
	"gold_laui": "res://assets/plants/sprite-golden-laui.png",
	"colorata": "res://assets/plants/sprite-colorata.png",
	"affinis": "res://assets/plants/sprite-affinis.png",
	"hyalina_san_luis": "res://assets/plants/sprite-hyalina-san-luis.png",
	"purpusorum": "res://assets/plants/sprite-purpusorum.png",
	"lutea": "res://assets/plants/sprite-lutea.png",
	"juliana": "res://assets/plants/sprite-carnicolor-glau-grey.png",
	"kannte": "res://assets/plants/sprite-kante.png",
	"shaviana": "res://assets/plants/sprite-shaviana.png",
	"pinwheel": "res://assets/plants/sprite-pinwheel.png",
	"tovarensis_tovar": "res://assets/plants/sprite-tovarensis-tovar.png",
	"strictiflora_bustamante": "res://assets/plants/sprite-strictiflora-bustamante.png",
	"transparent_mystery": "res://assets/plants/sprite-transparent-mystery.png",
	"gummy_peach_milk": "res://assets/catalog/gummy/gummy-peach-milk.png",
	"gummy_melon_milk": "res://assets/catalog/gummy/gummy-melon-milk.png",
	"gummy_fruit_punch": "res://assets/catalog/gummy/gummy-fruit-punch.png",
	"gummy_grape_milk": "res://assets/catalog/gummy/gummy-grape-milk.png",
	"gummy_strawberry": "res://assets/catalog/gummy/gummy-strawberry.png",
	"gummy_orange": "res://assets/catalog/gummy/gummy-orange.png",
	"gummy_rainbow": "res://assets/catalog/gummy/gummy-rainbow.png",
	"gummy_soda": "res://assets/catalog/gummy/gummy-soda.png",
	"sweets_strawberry_shortcake": "res://assets/catalog/sweets/sweets-strawberry-shortcake.png",
	"sweets_blueberry_galaxy": "res://assets/catalog/sweets/sweets-blueberry-galaxy.png",
	"sweets_citrus_mint": "res://assets/catalog/sweets/sweets-citrus-mint.png",
	"sweets_chocolate_gold": "res://assets/catalog/sweets/sweets-chocolate-gold.png",
	"sweets_matcha_wafer": "res://assets/catalog/sweets/sweets-matcha-wafer.png",
	"sweets_mango_mint": "res://assets/catalog/sweets/sweets-mango-mint.png",
	"sweets_raspberry_jewel": "res://assets/catalog/sweets/sweets-raspberry-jewel.png",
	"sweets_fairy_sugar": "res://assets/catalog/sweets/sweets-fairy-sugar.png",
	"sweets_caramel_cherry": "res://assets/catalog/sweets/sweets-caramel-cherry.png",
	"sweets_mint_chocolate": "res://assets/catalog/sweets/sweets-mint-chocolate.png",
	"metal_silver_rosette": "res://assets/catalog/metal/metal-silver-rosette.png",
	"metal_cobalt_cluster": "res://assets/catalog/metal/metal-cobalt-cluster.png",
	"metal_rose_copper": "res://assets/catalog/metal/metal-rose-copper.png",
	"metal_gold_cluster": "res://assets/catalog/metal/metal-gold-cluster.png",
	"metal_gunmetal_rosette": "res://assets/catalog/metal/metal-gunmetal-rosette.png",
	"metal_iridescent_star": "res://assets/catalog/metal/metal-iridescent-star.png",
	"metal_silver_branch": "res://assets/catalog/metal/metal-silver-branch.png",
	"metal_obsidian_spike": "res://assets/catalog/metal/metal-obsidian-spike.png",
	"metal_sage_silver": "res://assets/catalog/metal/metal-sage-silver.png",
	"metal_patina_copper": "res://assets/catalog/metal/metal-patina-copper.png",
	"jewel_diamond_rosette": "res://assets/catalog/jewel/jewel-diamond-rosette.png",
	"jewel_emerald_rosette": "res://assets/catalog/jewel/jewel-emerald-rosette.png",
	"jewel_sapphire_star": "res://assets/catalog/jewel/jewel-sapphire-star.png",
	"jewel_opal_rosette": "res://assets/catalog/jewel/jewel-opal-rosette.png",
	"jewel_amethyst_rosette": "res://assets/catalog/jewel/jewel-amethyst-rosette.png",
	"jewel_rose_quartz_rosette": "res://assets/catalog/jewel/jewel-rose-quartz-rosette.png",
	"jewel_fluorite_rosette": "res://assets/catalog/jewel/jewel-fluorite-rosette.png",
	"jewel_labradorite_star": "res://assets/catalog/jewel/jewel-labradorite-star.png",
	"jewel_citrine_rosette": "res://assets/catalog/jewel/jewel-citrine-rosette.png",
	"jewel_turquoise_cluster": "res://assets/catalog/jewel/jewel-turquoise-cluster.png",
	"forest_amber_insect_rosette": "res://assets/catalog/forest-amber/forest-amber-insect-rosette.png",
	"forest_amber_capsules": "res://assets/catalog/forest-amber/forest-amber-capsules.png",
	"forest_amber_stag_rosette": "res://assets/catalog/forest-amber/forest-amber-stag-rosette.png",
	"forest_amber_moss_orbs": "res://assets/catalog/forest-amber/forest-amber-moss-orbs.png",
	"forest_amber_fly_rosette": "res://assets/catalog/forest-amber/forest-amber-fly-rosette.png",
	"forest_amber_moss_fingers": "res://assets/catalog/forest-amber/forest-amber-moss-fingers.png",
	"forest_amber_dragonfly_rosette": "res://assets/catalog/forest-amber/forest-amber-dragonfly-rosette.png",
	"forest_amber_aqua_rosette": "res://assets/catalog/forest-amber/forest-amber-aqua-rosette.png",
	"forest_amber_lavender_rosette": "res://assets/catalog/forest-amber/forest-amber-lavender-rosette.png",
	"forest_amber_owl_rosette": "res://assets/catalog/forest-amber/forest-amber-owl-rosette.png",
	"jelly_grape": "res://assets/catalog/jelly/jelly-grape.png",
	"jelly_orange": "res://assets/catalog/jelly/jelly-orange.png",
	"jelly_muscat": "res://assets/catalog/jelly/jelly-muscat.png",
	"jelly_green_apple": "res://assets/catalog/jelly/jelly-green-apple.png",
	"jelly_soda": "res://assets/catalog/jelly/jelly-soda.png",
	"jelly_peach_milk": "res://assets/catalog/jelly/jelly-peach-milk.png",
	"jelly_lemon": "res://assets/catalog/jelly/jelly-lemon.png",
	"jelly_strawberry": "res://assets/catalog/jelly/jelly-strawberry.png",
	"jelly_mint": "res://assets/catalog/jelly/jelly-mint.png",
	"jelly_fruit_mix": "res://assets/catalog/jelly/jelly-fruit-mix.png",
	"stone_black_lava_rosette": "res://assets/catalog/stone/stone-black-lava-rosette.png",
	"stone_serpentine_rosette": "res://assets/catalog/stone/stone-serpentine-rosette.png",
	"stone_granite_rosette": "res://assets/catalog/stone/stone-granite-rosette.png",
	"stone_red_lava_rosette": "res://assets/catalog/stone/stone-red-lava-rosette.png",
	"stone_sandstone_rosette": "res://assets/catalog/stone/stone-sandstone-rosette.png",
	"stone_slate_rosette": "res://assets/catalog/stone/stone-slate-rosette.png",
	"stone_green_schist_rosette": "res://assets/catalog/stone/stone-green-schist-rosette.png",
	"stone_silver_gneiss_rosette": "res://assets/catalog/stone/stone-silver-gneiss-rosette.png",
	"stone_obsidian_rosette": "res://assets/catalog/stone/stone-obsidian-rosette.png",
	"stone_white_marble_rosette": "res://assets/catalog/stone/stone-white-marble-rosette.png",
	"yumekawa_milky_dream": "res://assets/catalog/yumekawa/yumekawa-milky-dream.png",
	"yumekawa_pastel_drops": "res://assets/catalog/yumekawa/yumekawa-pastel-drops.png",
	"yumekawa_fairy_branch": "res://assets/catalog/yumekawa/yumekawa-fairy-branch.png",
	"yumekawa_moonlight_rosette": "res://assets/catalog/yumekawa/yumekawa-moonlight-rosette.png",
	"yumekawa_bubble_candy": "res://assets/catalog/yumekawa/yumekawa-bubble-candy.png",
	"yumekawa_mint_milk": "res://assets/catalog/yumekawa/yumekawa-mint-milk.png",
	"yumekawa_lavender_frill": "res://assets/catalog/yumekawa/yumekawa-lavender-frill.png",
	"yumekawa_dream_bouquet": "res://assets/catalog/yumekawa/yumekawa-dream-bouquet.png",
	"yumekawa_princess_rose": "res://assets/catalog/yumekawa/yumekawa-princess-rose.png",
	"yumekawa_tricolor_rosettes": "res://assets/catalog/yumekawa/yumekawa-tricolor-rosettes.png",
	"sea_coralline_drops": "res://assets/catalog/sea/sea-coralline-drops.png",
	"sea_sandy_tide": "res://assets/catalog/sea/sea-sandy-tide.png",
	"sea_coral_fingers": "res://assets/catalog/sea/sea-coral-fingers.png",
	"sea_jellyfish_rosette": "res://assets/catalog/sea/sea-jellyfish-rosette.png",
	"sea_seafoam_bubbles": "res://assets/catalog/sea/sea-seafoam-bubbles.png",
	"sea_starlight_lagoon": "res://assets/catalog/sea/sea-starlight-lagoon.png",
	"sea_sandy_lagoon": "res://assets/catalog/sea/sea-sandy-lagoon.png",
	"sea_neon_coral": "res://assets/catalog/sea/sea-neon-coral.png",
	"sea_pearl_shell": "res://assets/catalog/sea/sea-pearl-shell.png",
	"sea_tropical_bubbles": "res://assets/catalog/sea/sea-tropical-bubbles.png",
	"gold_kannte": "res://assets/plants/sprite-golden-laui.png"
}

var data: Dictionary
var age := 0.0
var growth_time := 0.0
var diameter_cm := 1.6
var growth_rate := 1.0
var state := "growing"
var original_pos := Vector3.ZERO
var target_offset := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var label: Label
const GROWTH_CM_PER_SECOND := 1.365625
const GROWTH_RHYTHM_AMPLITUDE := 0.10
const JELLY_STAGE_ENDS := [5.0,10.0,15.0]
const VISUAL_SCALE_BASE := 0.18
const VISUAL_SCALE_PER_CM := 0.058
const SCREEN_SPACE_GIANT_REFERENCE_CM := 120.0
const SCREEN_ALPHA_HIT_THRESHOLD := .08
const SCREEN_ALPHA_PROFILE_SAMPLE_RESOLUTION := 192

static var screen_growth_anchor_cache:Dictionary={}

var visual_scale := VISUAL_SCALE_BASE
var plant_sprite: Sprite3D
var contact_shadow: MeshInstance3D
var is_special := false
var growth_rhythm_period := 22.0
var growth_rhythm_phase := 0.0
var growth_rhythm_amplitude := GROWTH_RHYTHM_AMPLITUDE
var growth_speed_multiplier := 1.0
var jelly_rates_per_second:Array[float]=[0.01,0.02,0.03,0.04]
var jelly_rng:=RandomNumberGenerator.new()
var jelly_permission:Callable
var jelly_checks_enabled := true
var kakuhen_enabled := false
var kakuhen_state := KakuhenSystemClass.STATE_NONE
var kakuhen_next_boundary_age := INF
var kakuhen_entry_roll_count := 0
var kakuhen_continuation_roll_count := 0
var kakuhen_boundary_count := 0
var kakuhen_rng:=RandomNumberGenerator.new()
var sway_phase := 0.0
var screen_hit_image:Image
var screen_sprite:Polygon2D
var screen_camera:Camera3D
var screen_texture_transform:=Transform2D.IDENTITY
var screen_texture_transform_valid:=false
var screen_draw_order_value:=0

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label, logic_only := false, balance_override:Dictionary = {}) -> void:
	data = species
	rng.seed = seed_value
	jelly_rng.seed = int(seed_value) ^ 0x5A17B3C9
	kakuhen_rng.seed = int(seed_value) ^ 0x41C64E6D
	sway_phase = rng.randf_range(0.0, TAU)
	is_special = rng.randf() < 0.10
	var balance:=balance_override if not balance_override.is_empty() else JellyBalanceClass.NON_NORMAL
	jelly_rates_per_second=JellyBalanceClass.rate_values(balance)
	growth_speed_multiplier=float(balance.get("growth_speed",1.0));growth_rhythm_amplitude=float(balance.get("rhythm_amplitude",GROWTH_RHYTHM_AMPLITUDE))
	kakuhen_enabled=bool(balance.get("kakuhen_enabled",false));kakuhen_state=KakuhenSystemClass.STATE_NONE;kakuhen_entry_roll_count=0;kakuhen_continuation_roll_count=0;kakuhen_boundary_count=0
	kakuhen_next_boundary_age=KakuhenSystemClass.INTERVAL_SECONDS if kakuhen_enabled else INF
	if kakuhen_enabled:_roll_kakuhen_entry()
	growth_rhythm_period = rng.randf_range(16.0, 28.0)
	growth_rhythm_phase = rng.randf_range(0.0, TAU)
	label = screen_label
	# Species rarity and the independent special roll never change growth speed.
	growth_rate = 1.0
	# Battle plants use this same node as their simulation source of truth, but
	# render through the battle's clipped 2D field instead of constructing the
	# greenhouse-only Sprite3D/contact shadow presentation.
	if logic_only:
		return
	_build_contact_shadow()
	plant_sprite = Sprite3D.new()
	var variant := str(data.get("visual_variant", "laui"))
	var configured_image_path:=str(data.get("image_path",""))
	var texture_path:=configured_image_path if not configured_image_path.is_empty() and (CatalogImageLoader.is_external_path(configured_image_path) or ResourceLoader.exists(configured_image_path)) else str(SPRITES.get(variant, ""))
	plant_sprite.texture = CatalogImageLoader.get_texture(texture_path) if not texture_path.is_empty() else CatalogImageLoader.placeholder_texture
	screen_hit_image=null
	plant_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plant_sprite.no_depth_test = false
	plant_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	plant_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plant_sprite.position.y = .26
	# Lift the artwork inside its quad so scaling grows upward from the soil,
	# preventing the lower leaves from sinking behind the soil or pot rim.
	plant_sprite.offset.y = -float(plant_sprite.texture.get_height()) * .18
	plant_sprite.pixel_size = 1.42 / maxf(1.0, float(plant_sprite.texture.get_width()))
	add_child(plant_sprite)
	if CatalogImageLoader.is_external_path(texture_path):CatalogImageLoader.request_texture(texture_path,_apply_external_plant_texture,true)
	_update_visual(0.0)
	if is_special: _play_special_birth_glow()

func _apply_external_plant_texture(texture:Texture2D)->void:
	if not is_instance_valid(plant_sprite) or texture==null:return
	plant_sprite.texture=texture
	if is_instance_valid(screen_sprite):screen_sprite.texture=texture
	plant_sprite.remove_meta("screen_hit_used_rect")
	screen_hit_image=null
	plant_sprite.offset.y=-float(texture.get_height())*.18
	plant_sprite.pixel_size=1.42/maxf(1.0,float(texture.get_width()))
	sync_screen_visual(screen_camera)

func attach_screen_visual(screen_parent:Node,camera:Camera3D)->void:
	if screen_parent==null or camera==null or plant_sprite==null or plant_sprite.texture==null:return
	if is_instance_valid(screen_sprite):screen_sprite.queue_free()
	screen_camera=camera
	screen_sprite=Polygon2D.new()
	screen_sprite.name="ScreenArtwork"
	screen_sprite.texture=plant_sprite.texture
	screen_sprite.z_as_relative=false
	screen_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	screen_parent.add_child(screen_sprite)
	# The 3D sprite remains the source of texture, tint, sway and interpolated
	# growth state, but only the screen-space copy is drawn in the greenhouse.
	# Its quad can therefore grow past the camera without entering the near plane.
	plant_sprite.visible=false
	sync_screen_visual(camera)

func _process(_delta:float)->void:
	if is_instance_valid(screen_sprite):sync_screen_visual(screen_camera)

func _exit_tree()->void:
	if is_instance_valid(screen_sprite):screen_sprite.queue_free()
	screen_sprite=null
	screen_texture_transform_valid=false

func set_screen_draw_order(value:int)->void:
	screen_draw_order_value=value
	if is_instance_valid(screen_sprite):screen_sprite.z_index=value

func screen_draw_order()->int:
	return screen_draw_order_value

func uses_giant_screen_transform()->bool:
	if plant_sprite==null:return false
	return plant_sprite.scale.x>visual_scale_for_diameter(SCREEN_SPACE_GIANT_REFERENCE_CM)+.0001

func _screen_growth_anchor_pixel()->Vector2:
	if plant_sprite==null or plant_sprite.texture==null:return Vector2.ZERO
	var texture_size:=plant_sprite.texture.get_size()
	var fallback:=texture_size*.5
	var cache_key:="%s:%s"%[plant_sprite.texture.get_rid(),texture_size]
	if screen_growth_anchor_cache.has(cache_key):return screen_growth_anchor_cache[cache_key]
	var image:=screen_hit_image
	if image==null or image.is_empty():image=plant_sprite.texture.get_image();screen_hit_image=image
	if image==null or image.is_empty():return fallback
	var used:=image.get_used_rect()
	if used.size.x<=0 or used.size.y<=0:return fallback
	# Use the opaque main body's alpha-weighted centroid as a stable reference for
	# the visible leaf mass. Transparent fringe pixels and isolated tips therefore
	# cannot pull this measurement away from the principal artwork.
	# The centroid is evaluated only once per texture and sampled at a bounded
	# resolution to avoid a frame hitch when a large imported image reaches 120 cm.
	var longest_side:=maxi(used.size.x,used.size.y)
	var sample_step:=maxi(1,ceili(float(longest_side)/float(SCREEN_ALPHA_PROFILE_SAMPLE_RESOLUTION)))
	var weighted_position:=Vector2.ZERO
	var total_weight:=0.0
	for y in range(maxi(used.position.y,0),mini(used.end.y,image.get_height()),sample_step):
		for x in range(maxi(used.position.x,0),mini(used.end.x,image.get_width()),sample_step):
			var alpha:=image.get_pixel(x,y).a
			if alpha<=SCREEN_ALPHA_HIT_THRESHOLD:continue
			weighted_position+=Vector2(float(x)+.5,float(y)+.5)*alpha
			total_weight+=alpha
	var anchor:=Vector2(float(used.position.x)+float(used.size.x)*.5,float(used.position.y)+float(used.size.y)*.5)
	if total_weight>0.0:anchor=weighted_position/total_weight
	screen_growth_anchor_cache[cache_key]=anchor
	return anchor

func _projected_texture_polygon(camera:Camera3D)->PackedVector2Array:
	var points:=PackedVector2Array()
	if camera==null or plant_sprite==null or plant_sprite.texture==null:return points
	var texture_size:=plant_sprite.texture.get_size()
	if texture_size.x<=0.0 or texture_size.y<=0.0:return points
	var near_depth:=maxf(.01,camera.near*1.01)
	var root_camera:=camera.to_local(global_position)
	if -root_camera.z<=near_depth:return points
	var basis:=camera.global_transform.basis
	var angle:=plant_sprite.rotation.z
	var plane_right:Vector3=basis.x*cos(angle)+basis.y*sin(angle)
	var plane_up:Vector3=-basis.x*sin(angle)+basis.y*cos(angle)
	var origin:=plant_sprite.global_position
	var global_scale:=plant_sprite.global_transform.basis.get_scale()
	var giant_transform:=uses_giant_screen_transform()
	var reference_scale:=visual_scale_for_diameter(SCREEN_SPACE_GIANT_REFERENCE_CM)
	if giant_transform:
		# Freeze the 3D projection at the exact legacy 120 cm transform. Further
		# growth happens in screen space so a huge billboard cannot cross the camera.
		var owner_scale:=global_transform.basis.get_scale()
		var reference_local_position:=Vector3(plant_sprite.position.x,.10+reference_scale*.62,plant_sprite.position.z)
		origin=global_transform*reference_local_position
		global_scale=Vector3(owner_scale.x*reference_scale,owner_scale.y*reference_scale,owner_scale.z*reference_scale)
	var texture_points:=[Vector2.ZERO,Vector2(texture_size.x,0.0),texture_size,Vector2(0.0,texture_size.y)]
	for pixel_point in texture_points:
		var local_pixels:=Vector2(
			pixel_point.x-texture_size.x*.5+plant_sprite.offset.x,
			-(pixel_point.y-texture_size.y*.5)+plant_sprite.offset.y
		)
		var world_point:=origin+plane_right*local_pixels.x*plant_sprite.pixel_size*global_scale.x+plane_up*local_pixels.y*plant_sprite.pixel_size*global_scale.y
		var camera_point:=camera.to_local(world_point)
		if -camera_point.z<=near_depth:return PackedVector2Array()
		var projected:=camera.unproject_position(world_point)
		if is_nan(projected.x) or is_inf(projected.x) or is_nan(projected.y) or is_inf(projected.y):return PackedVector2Array()
		points.append(projected)
	if giant_transform:
		var reference_axis_x:=(points[1]-points[0])/texture_size.x
		var reference_axis_y:=(points[3]-points[0])/texture_size.y
		var reference_transform:=Transform2D(reference_axis_x,reference_axis_y,points[0])
		var growth_anchor:=reference_transform*_screen_growth_anchor_pixel()
		if is_nan(growth_anchor.x) or is_inf(growth_anchor.x) or is_nan(growth_anchor.y) or is_inf(growth_anchor.y):return PackedVector2Array()
		var growth_ratio:=plant_sprite.scale.x/reference_scale
		for index in range(points.size()):points[index]=growth_anchor+(points[index]-growth_anchor)*growth_ratio
	return points

func sync_screen_visual(camera:Camera3D)->void:
	if not is_instance_valid(screen_sprite):return
	if camera==null or plant_sprite==null or plant_sprite.texture==null:
		screen_sprite.visible=false;screen_texture_transform_valid=false;return
	var texture_size:=plant_sprite.texture.get_size()
	var points:=_projected_texture_polygon(camera)
	if points.size()!=4 or texture_size.x<=0.0 or texture_size.y<=0.0:
		screen_sprite.visible=false;screen_texture_transform_valid=false;return
	var axis_x:=(points[1]-points[0])/texture_size.x
	var axis_y:=(points[3]-points[0])/texture_size.y
	screen_texture_transform=Transform2D(axis_x,axis_y,points[0])
	screen_texture_transform_valid=true
	# A transformed Sprite2D eventually exceeds the Compatibility renderer's
	# canvas-item bounds and vanishes even though its texture still crosses the
	# viewport. Draw only the on-screen slice of the same unbounded transform.
	# Polygon vertices therefore remain viewport-sized at 2,000 cm and beyond,
	# while UVs retain the exact linear scale and root anchoring of the full image.
	var viewport_rect:=camera.get_viewport().get_visible_rect().grow(2.0)
	var viewport_polygon:=PackedVector2Array([
		viewport_rect.position,
		Vector2(viewport_rect.end.x,viewport_rect.position.y),
		viewport_rect.end,
		Vector2(viewport_rect.position.x,viewport_rect.end.y)
	])
	var clipped_polygons:=Geometry2D.intersect_polygons(points,viewport_polygon)
	var clipped:=PackedVector2Array()
	for candidate in clipped_polygons:
		if candidate.size()>=3:
			clipped=candidate
			break
	if clipped.size()<3:
		screen_sprite.visible=false
		screen_sprite.polygon=PackedVector2Array()
		screen_sprite.uv=PackedVector2Array()
		return
	var inverse_transform:=screen_texture_transform.affine_inverse()
	var texture_uv:=PackedVector2Array()
	for screen_point in clipped:texture_uv.append(inverse_transform*screen_point)
	screen_sprite.texture=plant_sprite.texture
	screen_sprite.transform=Transform2D.IDENTITY
	screen_sprite.polygon=clipped
	screen_sprite.uv=texture_uv
	screen_sprite.modulate=plant_sprite.modulate
	screen_sprite.z_index=screen_draw_order_value
	screen_sprite.visible=is_visible_in_tree()

func _screen_hit_used_rect()->Rect2:
	if plant_sprite==null or plant_sprite.texture==null:return Rect2()
	if plant_sprite.has_meta("screen_hit_used_rect"):
		var cached:Variant=plant_sprite.get_meta("screen_hit_used_rect")
		if cached is Rect2:return cached
	var texture_size:=plant_sprite.texture.get_size()
	var result:=Rect2(Vector2.ZERO,texture_size)
	var image:=plant_sprite.texture.get_image()
	screen_hit_image=image
	if image!=null and not image.is_empty():
		var used:=image.get_used_rect()
		if used.size.x>0 and used.size.y>0:result=Rect2(used)
	plant_sprite.set_meta("screen_hit_used_rect",result)
	return result

func _screen_visual_polygon(camera:Camera3D)->PackedVector2Array:
	var points:=PackedVector2Array()
	if camera==null or plant_sprite==null or plant_sprite.texture==null:return points
	if is_instance_valid(screen_sprite):
		sync_screen_visual(camera)
		if not screen_texture_transform_valid:return points
		var screen_used:=_screen_hit_used_rect()
		if screen_used.size.x<=0.0 or screen_used.size.y<=0.0:screen_used=Rect2(Vector2.ZERO,plant_sprite.texture.get_size())
		for pixel_point in [screen_used.position,Vector2(screen_used.end.x,screen_used.position.y),screen_used.end,Vector2(screen_used.position.x,screen_used.end.y)]:
			points.append(screen_texture_transform*pixel_point)
		return points
	var texture_size:=plant_sprite.texture.get_size()
	if texture_size.x<=0.0 or texture_size.y<=0.0:return points
	var used:=_screen_hit_used_rect()
	if used.size.x<=0.0 or used.size.y<=0.0:used=Rect2(Vector2.ZERO,texture_size)
	var full_points:=_projected_texture_polygon(camera)
	if full_points.size()!=4:return points
	var axis_x:=(full_points[1]-full_points[0])/texture_size.x
	var axis_y:=(full_points[3]-full_points[0])/texture_size.y
	var texture_transform:=Transform2D(axis_x,axis_y,full_points[0])
	for pixel_point in [used.position,Vector2(used.end.x,used.position.y),used.end,Vector2(used.position.x,used.end.y)]:points.append(texture_transform*pixel_point)
	return points

func screen_depth(camera:Camera3D)->float:
	if camera==null:return INF
	# Root depth is stable at every diameter and is also the natural overlap order
	# for screen-space plants rooted in the soil.
	return -camera.to_local(global_position).z

func screen_label_anchor(camera:Camera3D)->Vector2:
	if camera==null:return Vector2.ZERO
	var root_screen:=camera.unproject_position(global_position)
	var rendered_scale:=visual_scale
	if plant_sprite!=null:rendered_scale=plant_sprite.scale.x
	var reference_scale:=visual_scale_for_diameter(SCREEN_SPACE_GIANT_REFERENCE_CM)
	var anchor_scale:=minf(rendered_scale,reference_scale)
	var reference_world:=global_position+Vector3(0,anchor_scale*.7,0)
	var reference_camera:=camera.to_local(reference_world)
	if -reference_camera.z<=maxf(.01,camera.near*1.01):return root_screen
	var reference_screen:=camera.unproject_position(reference_world)
	if is_nan(reference_screen.x) or is_inf(reference_screen.x) or is_nan(reference_screen.y) or is_inf(reference_screen.y):return root_screen
	if rendered_scale<=reference_scale:return reference_screen
	# Follow the actual upper edge of the screen-space artwork. Preserve the
	# established label offset at exactly 120 cm, then let the UI clamp stop it at
	# the viewport top. Scaling around the main body must never send the label down.
	if is_instance_valid(screen_sprite) and screen_texture_transform_valid:
		var growth_ratio:=rendered_scale/reference_scale
		var growth_anchor:=screen_texture_transform*_screen_growth_anchor_pixel()
		var used:=_screen_hit_used_rect()
		var current_top:=screen_texture_transform*Vector2(_screen_growth_anchor_pixel().x,used.position.y)
		var reference_top:=growth_anchor+(current_top-growth_anchor)/growth_ratio
		return current_top+(reference_screen-reference_top)
	return reference_screen

func screen_visual_rect(camera:Camera3D)->Rect2:
	var points:=_screen_visual_polygon(camera)
	if points.is_empty():return Rect2()
	var visible_rect:=Rect2(points[0],Vector2.ZERO)
	for point in points:visible_rect=visible_rect.expand(point)
	return visible_rect

func screen_opaque_sample_count(screen_points:PackedVector2Array)->int:
	# Spawn placement runs many probes per candidate. Reuse the already-synced
	# texture transform instead of rebuilding/clipping the visual polygon for
	# every point, while still testing the real per-pixel alpha artwork.
	if not screen_texture_transform_valid or plant_sprite==null or plant_sprite.texture==null:return 0
	var image:=screen_hit_image
	if image==null or image.is_empty():image=plant_sprite.texture.get_image();screen_hit_image=image
	var used:=_screen_hit_used_rect()
	if used.size.x<=0.0 or used.size.y<=0.0:return 0
	var inverse_transform:=screen_texture_transform.affine_inverse()
	var image_size:=Vector2i.ZERO if image==null or image.is_empty() else image.get_size()
	var count:=0
	for screen_point in screen_points:
		var pixel:=inverse_transform*screen_point
		if not used.has_point(pixel):continue
		if image_size==Vector2i.ZERO:
			count+=1
			continue
		var pixel_position:=Vector2i(clampi(floori(pixel.x),0,maxi(0,image_size.x-1)),clampi(floori(pixel.y),0,maxi(0,image_size.y-1)))
		if image.get_pixelv(pixel_position).a>SCREEN_ALPHA_HIT_THRESHOLD:count+=1
	return count

func screen_hit_test(camera:Camera3D,screen_point:Vector2)->Dictionary:
	# Sprite3D's billboard rotation is applied by the renderer and is not present
	# in its Node3D transform. Reconstruct the rendered quad in the camera plane
	# from the actual texture, pixel size, offset, and current sprite scale. This
	# keeps touch input aligned with leaves even when a 100+ cm plant's root and
	# old center-radius test sit far outside the visible part of the artwork.
	var points:=_screen_visual_polygon(camera)
	if points.is_empty():return {"hit":false}
	var visible_rect:=Rect2(points[0],Vector2.ZERO)
	for point in points:visible_rect=visible_rect.expand(point)
	var padding:=clampf(minf(visible_rect.size.x,visible_rect.size.y)*.08,14.0,36.0)
	var inside_artwork_bounds:=Geometry2D.is_point_in_polygon(screen_point,points)
	var opaque_artwork_hit:=inside_artwork_bounds and _screen_point_hits_opaque_artwork(screen_point,points)
	if uses_giant_screen_transform() and not opaque_artwork_hit:return {"hit":false,"rect":visible_rect,"polygon":points,"inside_artwork_bounds":inside_artwork_bounds,"opaque_artwork_hit":false,"depth":screen_depth(camera),"draw_order":screen_draw_order_value}
	# Transparent space remains a low-priority accessibility target so the center
	# of a single tutorial rosette is still tappable. Opaque leaves always win when
	# another plant overlaps this fallback area.
	if not inside_artwork_bounds and not visible_rect.grow(padding).has_point(screen_point):return {"hit":false,"rect":visible_rect,"polygon":points}
	var half_size:=Vector2(maxf(visible_rect.size.x*.5,1.0),maxf(visible_rect.size.y*.5,1.0))
	var normalized_delta:=(screen_point-visible_rect.get_center())/half_size
	var score:=normalized_delta.length()+(0.0 if opaque_artwork_hit else .85)
	return {"hit":true,"score":score,"rect":visible_rect,"polygon":points,"center":visible_rect.get_center(),"inside_artwork_bounds":inside_artwork_bounds,"opaque_artwork_hit":opaque_artwork_hit,"depth":screen_depth(camera),"draw_order":screen_draw_order_value}

func _screen_point_hits_opaque_artwork(screen_point:Vector2,points:PackedVector2Array)->bool:
	if points.size()!=4:return false
	var axis_u:=points[1]-points[0];var axis_v:=points[3]-points[0];var delta:=screen_point-points[0];var determinant:=axis_u.cross(axis_v)
	if absf(determinant)<.00001:return false
	var u:=delta.cross(axis_v)/determinant;var v:=axis_u.cross(delta)/determinant
	if u<0.0 or u>1.0 or v<0.0 or v>1.0:return false
	if screen_hit_image==null or screen_hit_image.is_empty():return true
	var used:=_screen_hit_used_rect();var pixel:=used.position+Vector2(u*used.size.x,v*used.size.y)
	var image_size:=screen_hit_image.get_size();var pixel_position:=Vector2i(clampi(floori(pixel.x),0,maxi(0,image_size.x-1)),clampi(floori(pixel.y),0,maxi(0,image_size.y-1)))
	return screen_hit_image.get_pixelv(pixel_position).a>SCREEN_ALPHA_HIT_THRESHOLD

static func visual_scale_for_diameter(value_cm:float)->float:
	# One linear physical-looking mapping for every size. The renderer switches to
	# a planting-relative screen transform after 120 cm, so this can remain
	# genuinely unbounded without pushing a 3D billboard through the camera.
	var diameter:=maxf(1.6,value_cm)
	return VISUAL_SCALE_BASE+(diameter-1.6)*VISUAL_SCALE_PER_CM

func _play_special_birth_glow() -> void:
	# A brief warm bloom announces the 10% roll without leaving a permanent mark.
	plant_sprite.modulate = Color(1.38, 1.18, .68, 1.0)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffd56a")
	glow.light_energy = 2.0
	glow.omni_range = 3.2
	glow.position = Vector3(0, .75, .08)
	add_child(glow)
	var tw := create_tween().bind_node(glow).set_parallel()
	tw.tween_property(plant_sprite, "modulate", Color.WHITE, .9).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(glow, "light_energy", 0.0, .9).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(glow.queue_free)

func _build_contact_shadow() -> void:
	contact_shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.55, .78)
	contact_shadow.mesh = quad
	contact_shadow.rotation_degrees.x = -90.0
	contact_shadow.position.y = .025
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment(){vec2 p=(UV-vec2(.5))*2.0;float a=smoothstep(1.0,.08,dot(p,p));ALBEDO=vec3(.035,.018,.012);ALPHA=a*.30;}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	contact_shadow.material_override = material
	add_child(contact_shadow)

func simulate(delta: float) -> void:
	if state != "growing" or delta<=0.0:return
	if growth_time==0.0 and diameter_cm>1.6:
		# growth_time stores already-earned effective growth.  Speed changes can
		# therefore affect only future growth and can never resize the past.
		growth_time=(diameter_cm-1.6)/(GROWTH_CM_PER_SECOND*maxf(.000001,growth_rate))
	var target_age:=age+delta
	while state=="growing" and age<target_age-.0000001:
		var segment_end:=target_age
		if kakuhen_enabled:segment_end=minf(segment_end,kakuhen_next_boundary_age)
		if segment_end>age+.0000001:
			_simulate_growth_segment(segment_end-age)
			if state!="growing":return
		if kakuhen_enabled and age>=kakuhen_next_boundary_age-.0000001 and age<=target_age+.0000001:
			_advance_kakuhen_boundary()
			kakuhen_next_boundary_age+=KakuhenSystemClass.INTERVAL_SECONDS


func _simulate_growth_segment(segment_seconds:float)->void:
	var segment_start:=age
	var segment_end:=age+segment_seconds
	var segment_speed:=effective_growth_speed_multiplier()
	growth_time+=_integrated_growth_multiplier(segment_start,segment_end)*segment_speed
	age=segment_end
	diameter_cm=1.6+growth_time*GROWTH_CM_PER_SECOND*growth_rate
	visual_scale=visual_scale_for_diameter(diameter_cm)
	_update_visual(segment_seconds)
	if jelly_checks_enabled and not KakuhenSystemClass.is_real(kakuhen_state):
		var jelly_probability:=jelly_probability_for_interval(segment_start,segment_seconds,jelly_rates_per_second)
		if jelly_rng.randf()<jelly_probability and (not jelly_permission.is_valid() or bool(jelly_permission.call())):jelly()


func _roll_kakuhen_entry()->void:
	if not kakuhen_enabled:return
	kakuhen_entry_roll_count+=1
	kakuhen_state=KakuhenSystemClass.entry_outcome(kakuhen_rng.randf())


func _advance_kakuhen_boundary()->void:
	kakuhen_boundary_count+=1
	if KakuhenSystemClass.is_real(kakuhen_state):
		kakuhen_continuation_roll_count+=1
		if kakuhen_rng.randf()>=KakuhenSystemClass.CONTINUE_CHANCE:
			# A real mode that ends cannot immediately enter again at this same
			# boundary. STATE_NONE receives its next entry roll ten seconds later.
			kakuhen_state=KakuhenSystemClass.STATE_NONE
		return
	if kakuhen_state==KakuhenSystemClass.STATE_FAKE_ACCELERATED:
		# Fake acceleration expires after one interval. It may use that boundary as
		# its next ordinary entry opportunity, as specified.
		kakuhen_state=KakuhenSystemClass.STATE_NONE
	_roll_kakuhen_entry()

func _integrated_growth_multiplier(start_time: float, end_time: float) -> float:
	# Integrate 1 + amplitude*sin(omega*t+phase) exactly. The multiplier stays
	# between 90% and 110%, never stops, and averages to 100% over each cycle.
	var omega := TAU / growth_rhythm_period
	return (end_time - start_time) + growth_rhythm_amplitude / omega * (
		cos(omega * start_time + growth_rhythm_phase)
		- cos(omega * end_time + growth_rhythm_phase)
	)

func effective_growth_speed_multiplier()->float:
	return growth_speed_multiplier*(KakuhenSystemClass.ACCELERATION_MULTIPLIER if KakuhenSystemClass.is_accelerated(kakuhen_state) else 1.0)

static func jelly_stage_index(at_age:float)->int:
	if at_age<5.0:return 0
	if at_age<10.0:return 1
	if at_age<15.0:return 2
	return 3

static func jelly_probability_for_interval(start_age:float,delta:float,rates_per_second:Array=[]) -> float:
	# Each stage stores a probability per full second. Multiplying the survival
	# factors for every crossed segment makes the result independent of frame rate.
	if delta<=0.0:return 0.0
	var rates:Array=JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL) if rates_per_second.is_empty() else rates_per_second
	if rates.size()<4:return 0.0
	var cursor:=maxf(0.0,start_age)
	var end_age:=maxf(cursor,start_age+delta)
	var survival:=1.0
	while cursor<end_age:
		var stage:=jelly_stage_index(cursor)
		var stage_end:=float(JELLY_STAGE_ENDS[stage]) if stage<3 else end_age
		var segment_end:=minf(end_age,stage_end)
		var segment_seconds:=segment_end-cursor
		var chance_per_second:=clampf(float(rates[stage]),0.0,1.0)
		if chance_per_second>=1.0:return 1.0
		if chance_per_second>0.0:survival*=pow(1.0-chance_per_second,segment_seconds)
		cursor=segment_end
	return clampf(1.0-survival,0.0,1.0)

static func jelly_chance_per_second(at_age:float,rates_per_second:Array=[]) -> float:
	var rates:Array=JellyBalanceClass.rate_values(JellyBalanceClass.FORMAL) if rates_per_second.is_empty() else rates_per_second
	if rates.size()<4:return 0.0
	return clampf(float(rates[jelly_stage_index(maxf(0.0,at_age))]),0.0,1.0)

func fast_forward_to_diameter(target_cm:float)->void:
	var clamped_target_cm:=maxf(1.6,target_cm)
	var target_growth:=(clamped_target_cm-1.6)/(GROWTH_CM_PER_SECOND*maxf(.000001,growth_rate))
	var base_speed:=maxf(.000001,growth_speed_multiplier)
	var target_rhythmic_time:=target_growth/base_speed
	var low:=0.0;var high:=maxf(1.0,target_rhythmic_time*1.2)
	while _integrated_growth_multiplier(0.0,high)<target_rhythmic_time:high*=2.0
	for i in range(32):
		var mid:=(low+high)*.5
		if _integrated_growth_multiplier(0.0,mid)<target_rhythmic_time:low=mid
		else:high=mid
	# The bisection finds the matching rhythmic age, while this development/test
	# helper must land on the requested diameter exactly. Re-evaluating the
	# integral at the approximate age can round microscopically below a story
	# threshold and make otherwise deterministic smoke tests intermittent.
	age=(low+high)*.5;growth_time=target_growth;diameter_cm=clamped_target_cm;visual_scale=visual_scale_for_diameter(diameter_cm)
	# This is a deterministic development/test teleport rather than simulated
	# history. Clear any transient mode and resume rolls at the next boundary.
	if kakuhen_enabled:
		kakuhen_state=KakuhenSystemClass.STATE_NONE
		kakuhen_next_boundary_age=(floorf(age/KakuhenSystemClass.INTERVAL_SECONDS)+1.0)*KakuhenSystemClass.INTERVAL_SECONDS
	_update_visual(0.0)

func _update_visual(delta: float) -> void:
	if plant_sprite == null: return
	var target: Vector3 = Vector3.ONE * visual_scale
	var response: float = 1.0 if delta <= 0.0 else min(delta * 4.5, 1.0)
	plant_sprite.scale = plant_sprite.scale.lerp(target, response)
	# Exact pre-giant-renderer Sprite3D placement from 7ecbc903/cf4d2dc7.
	# The texture offset below is part of this transform; do not replace it with a
	# measured alpha anchor or force either the artwork center or bottom to soil.
	plant_sprite.position.y = .10 + visual_scale * .62
	plant_sprite.rotation.z = sin(age * .72 + sway_phase) * .0045
	plant_sprite.position.x = sin(age * .58 + sway_phase * .73) * .007
	contact_shadow.scale = Vector3(visual_scale * 1.04, visual_scale * 1.04, visual_scale * .72)

func get_risk_percent() -> float: return 0.0

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	harvested.emit(self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	if plant_sprite != null:
		plant_sprite.modulate = Color(0.78, 0.90, 0.86, 0.72)
	jellied.emit(self)

func hit_radius() -> float: return max(.42, visual_scale * .72)
