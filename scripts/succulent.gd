class_name Succulent
extends Node3D

const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")

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
	"juliana": "res://assets/plants/sprite-lutea.png",
	"kannte": "res://assets/plants/sprite-kante.png",
	"shaviana": "res://assets/plants/sprite-shaviana.png",
	"pinwheel": "res://assets/plants/sprite-pinwheel.png",
	"tovarensis_tovar": "res://assets/plants/sprite-tovarensis-tovar.png",
	"transparent_mystery": "res://assets/plants/sprite-transparent-mystery.png",
	"mystery_glow_colorata": "res://assets/plants/mystery-glow-colorata.png",
	"mystery_metal_laui": "res://assets/plants/mystery-metal-laui.png",
	"mystery_seaglass_veria": "res://assets/plants/mystery-seaglass-veria.png",
	"mystery_amber_agavoides": "res://assets/plants/mystery-amber-agavoides.png",
	"mystery_yumefuwa_jelly": "res://assets/plants/mystery-yumefuwa-jelly.png",
	"mystery_peach_jelly": "res://assets/plants/mystery-peach-jelly.png",
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
const JELLY_CHANCE_FINAL := 0.06
const GROWTH_RHYTHM_AMPLITUDE := 0.10

var visual_scale := 0.18
var plant_sprite: Sprite3D
var contact_shadow: MeshInstance3D
var is_special := false
var jelly_safe_end_seconds := 4.5
var jelly_ramp_end_seconds := 13.0
var growth_rhythm_period := 22.0
var growth_rhythm_phase := 0.0
var growth_rhythm_amplitude := GROWTH_RHYTHM_AMPLITUDE
var growth_speed_multiplier := 1.0
var individual_growth_multiplier := 1.0
var jelly_final_chance := JELLY_CHANCE_FINAL
var resistance_type := "normal"
var base_resistance_type := "normal"
var is_slow_sticky := false
var is_resilient := false
var jelly_permission:Callable
var jelly_checks_enabled := true
var sway_phase := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	sway_phase = rng.randf_range(0.0, TAU)
	is_special = rng.randf() < 0.10
	# Every plant gets a short guaranteed establishment period. Its later
	# vulnerability is individual: both the safe period and the time needed to
	# reach the common 6%/second mature risk vary continuously.
	var balance:=JellyBalanceClass.effective()
	jelly_final_chance=float(balance.final_chance);growth_speed_multiplier=float(balance.growth_speed);growth_rhythm_amplitude=float(balance.rhythm_amplitude)
	individual_growth_multiplier=1.0;is_slow_sticky=false;is_resilient=false
	jelly_safe_end_seconds = rng.randf_range(float(balance.safe_min), float(balance.safe_max))
	var ramp_roll := rng.randf()
	base_resistance_type=JellyBalanceClass.resistance_for_roll(ramp_roll,balance);resistance_type=base_resistance_type
	var ramp_min:=float(balance[base_resistance_type+"_min"]);var ramp_max:=float(balance[base_resistance_type+"_max"])
	# Conversion is a second, one-time roll only after the base short type wins.
	# At 0%, no extra RNG is consumed, preserving the exact legacy profile.
	if base_resistance_type=="short" and float(balance.slow_short_rate)>0.0:
		var slow_roll:=rng.randf()
		if JellyBalanceClass.slow_sticky_for_roll(base_resistance_type,slow_roll,balance):
			is_slow_sticky=true;resistance_type="slow_sticky"
			if float(balance.slow_resilient_rate)>0.0:is_resilient=JellyBalanceClass.resilient_for_roll(base_resistance_type,true,rng.randf(),balance)
			individual_growth_multiplier=rng.randf_range(float(balance.slow_growth_min),float(balance.slow_growth_max))
			ramp_min=float(balance.slow_ramp_min);ramp_max=float(balance.slow_ramp_max)
	if base_resistance_type=="short" and not is_slow_sticky and float(balance.regular_short_resilient_rate)>0.0:
		is_resilient=JellyBalanceClass.resilient_for_roll(base_resistance_type,false,rng.randf(),balance)
	if is_resilient:jelly_final_chance=float(balance.resilient_final_chance)
	jelly_ramp_end_seconds=jelly_safe_end_seconds+rng.randf_range(ramp_min,ramp_max)
	growth_rhythm_period = rng.randf_range(16.0, 28.0)
	growth_rhythm_phase = rng.randf_range(0.0, TAU)
	label = screen_label
	# Species rarity and the independent special roll never change growth speed.
	growth_rate = 1.0
	_build_contact_shadow()
	plant_sprite = Sprite3D.new()
	var variant := str(data.get("visual_variant", "laui"))
	var configured_image_path:=str(data.get("image_path",""))
	var texture_path:=configured_image_path if not configured_image_path.is_empty() and (CatalogImageLoader.is_external_path(configured_image_path) or ResourceLoader.exists(configured_image_path)) else str(SPRITES.get(variant, SPRITES.laui))
	plant_sprite.texture = CatalogImageLoader.get_texture(texture_path)
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
	plant_sprite.offset.y=-float(texture.get_height())*.18
	plant_sprite.pixel_size=1.42/maxf(1.0,float(texture.get_width()))

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
	if state != "growing": return
	if growth_time == 0.0 and diameter_cm > 1.6:
		growth_time = (diameter_cm - 1.6) / (GROWTH_CM_PER_SECOND * growth_rate * effective_growth_speed_multiplier())
	var previous_age := age
	age += delta
	growth_time += _integrated_growth_multiplier(previous_age, age)
	diameter_cm = 1.6 + growth_time * GROWTH_CM_PER_SECOND * growth_rate * effective_growth_speed_multiplier()
	# One physical-looking scale mapping for all sizes, with no clamp or cap.
	# 30cm is now a moderate plant; 60–70cm is when it dominates the view.
	visual_scale = .18 + (diameter_cm - 1.6) * .058
	_update_visual(delta)
	if jelly_checks_enabled:
		var jelly_probability := jelly_probability_for_interval(age - delta, delta, jelly_safe_end_seconds, jelly_ramp_end_seconds,jelly_final_chance)
		if rng.randf() < jelly_probability and (not jelly_permission.is_valid() or bool(jelly_permission.call())): jelly()

func _integrated_growth_multiplier(start_time: float, end_time: float) -> float:
	# Integrate 1 + amplitude*sin(omega*t+phase) exactly. The multiplier stays
	# between 90% and 110%, never stops, and averages to 100% over each cycle.
	var omega := TAU / growth_rhythm_period
	return (end_time - start_time) + growth_rhythm_amplitude / omega * (
		cos(omega * start_time + growth_rhythm_phase)
		- cos(omega * end_time + growth_rhythm_phase)
	)

func effective_growth_speed_multiplier()->float:
	return growth_speed_multiplier*individual_growth_multiplier

func development_trait_text()->String:
	var type_name:=str({"short":"短命","normal":"普通","long":"長命","ultra":"超長命"}.get(base_resistance_type,base_resistance_type))
	return "%s\n%s / %s\n成長×%.2f\n最終%.1f%%"%[type_name,"遅育" if is_slow_sticky else "通常育","強健" if is_resilient else "標準",individual_growth_multiplier,jelly_final_chance*100.0]

static func jelly_probability_for_interval(start_age: float, delta: float, safe_end_seconds := 4.5, ramp_end_seconds := 13.0, final_chance:=JELLY_CHANCE_FINAL) -> float:
	# This is the single source of truth for jelly probability. Integrating the
	# smoothly varying hazard over the whole frame makes the result FPS independent.
	if delta <= 0.0: return 0.0
	var end_age := start_age + delta
	var integrated_hazard := _integrate_hazard_segment(start_age,end_age,safe_end_seconds,ramp_end_seconds,0.0,final_chance)
	var constant_start := maxf(start_age, ramp_end_seconds)
	if end_age > constant_start:
		integrated_hazard += -log(1.0 - final_chance) * (end_age - constant_start)
	return 1.0 - exp(-integrated_hazard)

static func jelly_chance_per_second(at_age: float, safe_end_seconds := 4.5, ramp_end_seconds := 13.0, final_chance:=JELLY_CHANCE_FINAL) -> float:
	var hazard := 0.0
	if at_age > safe_end_seconds and at_age < ramp_end_seconds:
		hazard = _smooth_hazard(at_age,safe_end_seconds,ramp_end_seconds,0.0,final_chance)
	elif at_age >= ramp_end_seconds:
		hazard = -log(1.0-final_chance)
	return 1.0 - exp(-hazard)

func fast_forward_to_diameter(target_cm:float)->void:
	var target_growth:=(target_cm-1.6)/(GROWTH_CM_PER_SECOND*growth_rate*effective_growth_speed_multiplier())
	var low:=0.0;var high:=maxf(1.0,target_growth*1.2)
	while _integrated_growth_multiplier(0.0,high)<target_growth:high*=2.0
	for i in range(32):
		var mid:=(low+high)*.5
		if _integrated_growth_multiplier(0.0,mid)<target_growth:low=mid
		else:high=mid
	age=(low+high)*.5;growth_time=_integrated_growth_multiplier(0.0,age);diameter_cm=1.6+growth_time*GROWTH_CM_PER_SECOND*growth_rate*effective_growth_speed_multiplier();visual_scale=.18+(diameter_cm-1.6)*.058;_update_visual(0.0)

static func _smooth_hazard(at_age: float, segment_start: float, segment_end: float, start_chance: float, end_chance: float) -> float:
	var t := clampf((at_age - segment_start) / (segment_end - segment_start), 0.0, 1.0)
	return lerpf(-log(1.0 - start_chance), -log(1.0 - end_chance), smoothstep(0.0, 1.0, t))

static func _integrate_hazard_segment(start_age: float, end_age: float, segment_start: float, segment_end: float, start_chance: float, end_chance: float) -> float:
	var clipped_start := maxf(start_age, segment_start)
	var clipped_end := minf(end_age, segment_end)
	if clipped_end <= clipped_start: return 0.0
	var length := segment_end - segment_start
	var t0 := (clipped_start - segment_start) / length
	var t1 := (clipped_end - segment_start) / length
	var smooth_integral := (pow(t1, 3.0) - 0.5 * pow(t1, 4.0)) - (pow(t0, 3.0) - 0.5 * pow(t0, 4.0))
	var start_hazard := -log(1.0 - start_chance)
	var end_hazard := -log(1.0 - end_chance)
	return start_hazard * (clipped_end - clipped_start) + (end_hazard - start_hazard) * length * smooth_integral

func _update_visual(delta: float) -> void:
	if plant_sprite == null: return
	var target: Vector3 = Vector3.ONE * visual_scale
	var response: float = 1.0 if delta <= 0.0 else min(delta * 4.5, 1.0)
	plant_sprite.scale = plant_sprite.scale.lerp(target, response)
	# Anchor the lower edge near the soil as the centered billboard grows.
	# Only the artwork rises; the plant node itself never changes position.
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
	plant_sprite.modulate = Color(0.78, 0.90, 0.86, 0.72)
	jellied.emit(self)

func hit_radius() -> float: return max(.42, visual_scale * .72)
