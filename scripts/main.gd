extends Node

const SucculentClass = preload("res://scripts/succulent.gd")
const TARGET_COUNT := 12
const SOIL_SOURCE_CENTER := Vector2(426.5,700.0)
const SOIL_SOURCE_RADII := Vector2(360.0,190.0)
const SPAWN_SPRITE_MARGIN_SOURCE_PX := 40.0
const GREENHOUSE_DRAG_SCALE := 0.30
const GREENHOUSE_DRAG_DEAD_ZONE := 3.0
const GREENHOUSE_PAN_FOLLOW_SECONDS := 0.075
const HABITAT_DRAG_SCALE := 0.055
const HABITAT_ITEM_RADIUS := 9.0
const PLAY_DURATION_SECONDS := 60.0
const NORMAL_SEED_BAG_PRICE_YEN := 500
const PREMIUM_SEED_BAG_PRICE_YEN := 800
const PREMIUM_RARE_WEIGHT_MULTIPLIER := 3.0
const PREMIUM_SUPER_RARE_WEIGHT_MULTIPLIER := 5.0
const HABITAT_SAFE_PLANT_POINTS := [Vector2(70,400),Vector2(155,410),Vector2(245,400),Vector2(335,420),Vector2(430,405),Vector2(535,415),Vector2(705,430),Vector2(820,410),Vector2(920,395),Vector2(1025,420),Vector2(1130,400),Vector2(1220,415)]
const HABITAT_SAFE_SEED_POINTS := [Vector2(45,430),Vector2(115,445),Vector2(190,430),Vector2(275,445),Vector2(360,440),Vector2(455,435),Vector2(545,445),Vector2(625,455),Vector2(715,450),Vector2(805,440),Vector2(895,430),Vector2(980,445),Vector2(1060,435),Vector2(1140,445),Vector2(1210,435),Vector2(1260,455)]
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")
const UI_GOLD := Color("#e8aa35")

var rng := RandomNumberGenerator.new()
var species: Array = []
var catalog_species: Array = []
var opening_species: Array = []
var plants: Array = []
var recent_vacated_slots: Array[Vector3] = []
var camera: Camera3D
var world_root: Node3D
var pot_root: Node3D
var greenhouse_layer: CanvasLayer
var greenhouse_backdrop: TextureRect
var greenhouse_pan_x := 0.0
var greenhouse_pan_target_x := 0.0
var greenhouse_pan_limit := 0.0
var greenhouse_world_pan_x := 0.0
var habitat_env: WorldEnvironment
var habitat_environment: Environment
var habitat_items_root: Node3D
var habitat_pickups: Array = []
var habitat_new_species_id := ""
var mode_button: Button
var current_mode := "greenhouse"
var labels_layer: Control
var effects_layer: Control
var best_label: Label
var coin_label: Label
var record_card: PanelContainer
var record_text: Label
var encyclopedia_overlay: Control
var encyclopedia_list_page: Control
var encyclopedia_detail_page: Control
var encyclopedia_grid: GridContainer
var habitat_status_label: Label
var play_timer_label: Label
var play_open_button: Button
var play_overlay: Control
var play_bag_summary: Label
var play_selection_label: Label
var play_message: Label
var normal_play_button: Button
var premium_play_button: Button
var shop_overlay: Control
var shop_wallet_label: Label
var shop_bag_label: Label
var shop_message: Label
var panda_clerk_slot: TextureRect
var result_overlay: Control
var result_card: PanelContainer
var result_total_label: Label
var result_count_label: Label
var result_max_label: Label
var result_notable_label: Label
var encyclopedia_icon_button: Button
var external_navigation_controls: Array[Control] = []
var coins := 12450
var bests: Dictionary = {}
var discovered: Dictionary = {}
var unlocked_species: Dictionary = {}
var habitat_seed_date := ""
var habitat_seeds_collected := 0
var normal_seed_bags := 5
var premium_seed_bags := 0
var login_bonus_date := ""
var play_active := false
var play_time_remaining := 0.0
var active_seed_type := "normal"
var selected_seed_bag_count := 1
var play_modal_open := false
var play_earnings_total := 0
var play_harvest_count := 0
var play_max_size := 0.0
var play_notable_species: Dictionary = {}
var spawn_queue := 0
var spawn_timer := 0.0
var forced_golden_done := false
var view_yaw := 0.0
var view_pitch := -3.0
var habitat_target_yaw := 0.0
var habitat_target_pitch := -3.0
var pointer_down := false
var pointer_start := Vector2.ZERO
var pointer_last := Vector2.ZERO
var pointer_travel := 0.0
var greenhouse_drag_accumulator := 0.0
var greenhouse_drag_started := false

func _ready() -> void:
	rng.randomize()
	_load_species()
	_load_save()
	_grant_daily_seed_bag()
	_apply_saved_unlocks()
	_build_world()
	_build_ui()
	_build_habitat_items()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _load_species() -> void:
	var raw := FileAccess.get_file_as_string("res://data/species-v2.json")
	var all_species: Array = JSON.parse_string(raw)
	catalog_species=all_species.duplicate(true)
	var enabled := ["colorata", "lutea", "shaviana", "affinis", "laui", "kannte", "golden_laui"]
	for entry in all_species:
		if str(entry.species_id) in enabled:
			species.append(entry);unlocked_species[str(entry.species_id)]=true

func _load_save() -> void:
	if FileAccess.file_exists("user://records.json"):
		var value = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
		if value is Dictionary:
			bests = value.get("bests",{}); coins = int(value.get("yen",value.get("coins",12450))); discovered=value.get("discovered",{});habitat_seed_date=str(value.get("habitat_seed_date",""));habitat_seeds_collected=int(value.get("habitat_seeds_collected",0))
			if value.has("normal_seed_bags"):
				normal_seed_bags=int(value.get("normal_seed_bags",5));premium_seed_bags=int(value.get("premium_seed_bags",0));login_bonus_date=str(value.get("login_bonus_date",""))
			else:
				normal_seed_bags=5;premium_seed_bags=0;login_bonus_date=Time.get_date_string_from_system()
			var saved_unlocks=value.get("unlocked_species",{})
			if saved_unlocks is Dictionary:
				for species_id in saved_unlocks:
					if bool(saved_unlocks[species_id]):unlocked_species[species_id]=true
			# Saves created before the encyclopedia already contain valid best sizes.
			for species_id in bests:
				if float(bests[species_id])>0.0:discovered[species_id]=true

func _save() -> void:
	var f := FileAccess.open("user://records.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"bests":bests,"discovered":discovered,"unlocked_species":unlocked_species,"habitat_seed_date":habitat_seed_date,"habitat_seeds_collected":habitat_seeds_collected,"normal_seed_bags":normal_seed_bags,"premium_seed_bags":premium_seed_bags,"login_bonus_date":login_bonus_date,"yen":coins}))

func _grant_daily_seed_bag()->void:
	var today:=Time.get_date_string_from_system()
	if login_bonus_date.is_empty():login_bonus_date=today;_save();return
	if login_bonus_date!=today:normal_seed_bags+=1;login_bonus_date=today;_save()

func _apply_saved_unlocks()->void:
	var present:Dictionary={}
	for entry in species:present[str(entry.species_id)]=true
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(unlocked_species.get(species_id,false)) and not present.has(species_id):species.append(entry);present[species_id]=true

func _build_world() -> void:
	greenhouse_layer=CanvasLayer.new();greenhouse_layer.layer=-10;add_child(greenhouse_layer)
	greenhouse_backdrop=TextureRect.new();greenhouse_backdrop.texture=load("res://assets/greenhouse-main.jpg");greenhouse_backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;greenhouse_backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT;greenhouse_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;greenhouse_layer.add_child(greenhouse_backdrop)
	world_root = Node3D.new(); add_child(world_root)
	habitat_env=WorldEnvironment.new(); var env:=Environment.new()
	var sky := Sky.new(); var panorama := PanoramaSkyMaterial.new()
	# The default 256px sky radiance map noticeably softens this 1280x640
	# panorama. 1024 keeps the source detail while remaining Web/mobile-safe.
	sky.radiance_size = Sky.RADIANCE_SIZE_1024
	panorama.panorama = load("res://assets/highland-panorama.jpg")
	sky.sky_material = panorama
	env.background_mode=Environment.BG_SKY; env.sky=sky; env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("#d6b98b"); env.ambient_light_energy=0.32
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	habitat_environment=env;habitat_env.environment=env; world_root.add_child(habitat_env)
	habitat_items_root=Node3D.new();habitat_items_root.visible=false;world_root.add_child(habitat_items_root)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-18,72,0); sun.light_color=Color("#ffd9a0"); sun.light_energy=0.28; sun.shadow_enabled=false; world_root.add_child(sun)
	camera=Camera3D.new(); camera.fov=54.0; camera.current=true; world_root.add_child(camera)
	_build_greenhouse_pot()
	_apply_mode()

func _build_greenhouse_pot()->void:
	pot_root=Node3D.new();world_root.add_child(pot_root)
	var body:=MeshInstance3D.new();var body_mesh:=CylinderMesh.new();body_mesh.top_radius=4.55;body_mesh.bottom_radius=3.75;body_mesh.height=1.65;body_mesh.radial_segments=64;body.mesh=body_mesh;body.position.y=-.86;body.material_override=_terracotta_material(false);pot_root.add_child(body)
	var rim:=MeshInstance3D.new();var rim_mesh:=TorusMesh.new();rim_mesh.inner_radius=4.18;rim_mesh.outer_radius=4.62;rim_mesh.rings=64;rim_mesh.ring_segments=16;rim.mesh=rim_mesh;rim.position.y=.02;rim.material_override=_terracotta_material(true);pot_root.add_child(rim)
	var soil:=MeshInstance3D.new();var soil_mesh:=CylinderMesh.new();soil_mesh.top_radius=4.18;soil_mesh.bottom_radius=4.18;soil_mesh.height=.18;soil_mesh.radial_segments=64;soil.mesh=soil_mesh;soil.position.y=-.03;soil.material_override=_soil_material();pot_root.add_child(soil)

func _mat(color: Color, rough: float, metallic: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=rough; m.metallic=metallic; return m

func _terracotta_material(is_rim: bool) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec3 clay_dark : source_color = vec3(0.31,0.105,0.055);
uniform vec3 clay_light : source_color = vec3(0.58,0.245,0.12);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){float grain=hash(floor(UV*vec2(180.0,90.0)));float bands=sin(UV.y*55.0+sin(UV.x*19.0))*0.5+0.5;float wear=smoothstep(0.40,0.92,grain)*0.13;ALBEDO=mix(clay_dark,clay_light,0.46+bands*0.12+wear);ROUGHNESS=0.78;SPECULAR=0.25;}"""
	var material:=ShaderMaterial.new();material.shader=shader
	if is_rim: material.set_shader_parameter("clay_light",Color("#a94f2c"));material.set_shader_parameter("clay_dark",Color("#572315"))
	return material

func _soil_material()->ShaderMaterial:
	var shader:=Shader.new();shader.code="""shader_type spatial;
void fragment(){float a=sin(UV.x*173.0+sin(UV.y*61.0)*2.7)*sin(UV.y*157.0+sin(UV.x*47.0)*2.2);float b=sin(UV.x*43.0+UV.y*51.0)*.5+.5;float grain=clamp(a*.5+.5,0.0,1.0);vec3 lo=vec3(.105,.047,.027);vec3 hi=vec3(.31,.145,.075);vec3 c=mix(lo,hi,grain*.34+b*.12);ALBEDO=c;ROUGHNESS=.96;SPECULAR=.08;}""";var material:=ShaderMaterial.new();material.shader=shader;return material

func _build_ui() -> void:
	var ui:=CanvasLayer.new(); ui.layer=10; add_child(ui)
	labels_layer=Control.new(); labels_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); labels_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(labels_layer)
	var hud:=Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(hud)
	effects_layer=Control.new(); effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); effects_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(effects_layer)
	var game_theme:=Theme.new();game_theme.default_font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf") as Font;game_theme.default_font_size=16
	labels_layer.theme=game_theme;hud.theme=game_theme;effects_layer.theme=game_theme
	# logo
	var logo:=Label.new(); logo.text="ぷくぷく\n多 肉"; logo.position=Vector2(26,34); logo.size=Vector2(190,105); logo.add_theme_font_size_override("font_size",31); logo.add_theme_color_override("font_color",Color("#fff2d3")); logo.add_theme_color_override("font_outline_color",UI_BROWN); logo.add_theme_constant_override("outline_size",8); logo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(logo)
	var ribbon:=Label.new(); ribbon.text=" PUKU PUKU TANIKU "; ribbon.position=Vector2(56,126); ribbon.add_theme_font_size_override("font_size",11); ribbon.add_theme_color_override("font_color",Color.WHITE); ribbon.add_theme_stylebox_override("normal",_box(Color("#d99a3c"),Color("#7b4a25"),12,2)); hud.add_child(ribbon)
	var best_panel:=PanelContainer.new(); best_panel.position=Vector2(220,54); best_panel.size=Vector2(168,66); best_panel.add_theme_stylebox_override("panel",_box(Color("#47261b"),Color("#f5c985"),16,2)); hud.add_child(best_panel)
	best_label=Label.new(); best_label.text="最高  ベスト記録\n     0.0 cm"; best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; best_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; best_label.add_theme_font_size_override("font_size",17); best_label.add_theme_color_override("font_color",Color.WHITE); best_panel.add_child(best_label)
	var coin_panel:=PanelContainer.new(); coin_panel.position=Vector2(398,54); coin_panel.size=Vector2(153,53); coin_panel.add_theme_stylebox_override("panel",_box(Color("#55301d"),Color("#f1d19c"),22,2)); hud.add_child(coin_panel)
	coin_label=Label.new(); coin_label.text=" ¥%s" % _comma(coins); coin_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; coin_label.add_theme_font_size_override("font_size",20); coin_label.add_theme_color_override("font_color",Color("#ffd85b")); coin_panel.add_child(coin_label)
	for entry in [{"x":421,"t":"図鑑"},{"x":495,"t":"設定"}]:
		var b:=Button.new(); b.text=entry.t; b.position=Vector2(entry.x,116); b.size=Vector2(68,73); _skin_button(b,Color("#fff0cf"),17); hud.add_child(b)
		external_navigation_controls.append(b)
		if entry.t=="図鑑":encyclopedia_icon_button=b;b.mouse_filter=Control.MOUSE_FILTER_STOP;b.pressed.connect(_open_encyclopedia)
	mode_button=Button.new();mode_button.text="原生地";mode_button.position=Vector2(465,202);mode_button.size=Vector2(98,45);_skin_button(mode_button,Color("#fff0cf"),15);mode_button.mouse_filter=Control.MOUSE_FILTER_STOP;mode_button.pressed.connect(_toggle_mode);hud.add_child(mode_button)
	external_navigation_controls.append(mode_button)
	habitat_status_label=Label.new();habitat_status_label.position=Vector2(163,42);habitat_status_label.size=Vector2(250,56);habitat_status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;habitat_status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;habitat_status_label.add_theme_font_size_override("font_size",18);habitat_status_label.add_theme_color_override("font_color",UI_CREAM);habitat_status_label.add_theme_stylebox_override("normal",_box(Color("#4b2d20"),Color("#d8ad68"),18,2));habitat_status_label.visible=false;hud.add_child(habitat_status_label)
	play_timer_label=Label.new();play_timer_label.position=Vector2(190,135);play_timer_label.size=Vector2(196,58);play_timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_timer_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;play_timer_label.add_theme_font_size_override("font_size",24);play_timer_label.add_theme_color_override("font_color",Color.WHITE);play_timer_label.add_theme_stylebox_override("normal",_box(Color("#5b3321"),Color("#f3cb72"),19,3));play_timer_label.visible=false;hud.add_child(play_timer_label)
	play_open_button=Button.new();play_open_button.text="▶  プレイ";play_open_button.position=Vector2(31,177);play_open_button.size=Vector2(180,58);_skin_button(play_open_button,Color("#8b5a35"),21);play_open_button.mouse_filter=Control.MOUSE_FILTER_STOP;play_open_button.pressed.connect(_open_play_modal);hud.add_child(play_open_button)
	# lower gradient cards
	var harvest:=Button.new(); harvest.text="タップで 収穫！"; harvest.position=Vector2(24,829); harvest.size=Vector2(360,121); _skin_button(harvest,Color("#caa538"),27); harvest.mouse_filter=Control.MOUSE_FILTER_IGNORE; hud.add_child(harvest)
	record_card=PanelContainer.new(); record_card.position=Vector2(394,816); record_card.size=Vector2(164,134); record_card.add_theme_stylebox_override("panel",_box(Color("#674135"),Color("#f4d36e"),18,3)); record_card.visible=false; hud.add_child(record_card)
	record_text=Label.new(); record_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; record_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; record_text.add_theme_font_size_override("font_size",19); record_text.add_theme_color_override("font_color",Color.WHITE); record_card.add_child(record_text)
	var nav:=HBoxContainer.new(); nav.position=Vector2(23,957); nav.size=Vector2(530,80); nav.add_theme_constant_override("separation",4); hud.add_child(nav)
	external_navigation_controls.append(nav)
	for item in ["図鑑","ホーム","マーケット"]:
		var b:=Button.new(); b.text=item; b.custom_minimum_size=Vector2(174,76); _skin_button(b,Color("#6d472d") if item!="ホーム" else Color("#fff0cf"),18); nav.add_child(b)
		if item=="図鑑":b.pressed.connect(_open_encyclopedia)
		elif item=="マーケット":b.pressed.connect(_open_shop)
	_build_encyclopedia(hud)
	_build_play_overlay(hud)
	_build_shop(hud)
	_build_result_overlay(hud)
	_update_best_ui()
	_update_play_ui()

func _build_play_overlay(hud:Control)->void:
	play_overlay=Control.new();play_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);play_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(play_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.12,0.07,0.04,.42);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;play_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(68,270);panel.size=Vector2(440,460);panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#9b642f"),26,4));play_overlay.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",13);panel.add_child(content)
	var title:=Label.new();title.text="種袋を選んで 60秒プレイ";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	play_bag_summary=Label.new();play_bag_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_bag_summary.add_theme_font_size_override("font_size",18);play_bag_summary.add_theme_color_override("font_color",Color("#70472d"));content.add_child(play_bag_summary)
	var selector:=HBoxContainer.new();selector.alignment=BoxContainer.ALIGNMENT_CENTER;selector.add_theme_constant_override("separation",10);content.add_child(selector)
	var minus:=Button.new();minus.text="−";minus.custom_minimum_size=Vector2(52,48);_skin_button(minus,Color("#ead8b1"),22);minus.pressed.connect(_adjust_play_bag_count.bind(-1));selector.add_child(minus)
	play_selection_label=Label.new();play_selection_label.custom_minimum_size=Vector2(260,48);play_selection_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_selection_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;play_selection_label.add_theme_font_size_override("font_size",17);play_selection_label.add_theme_color_override("font_color",UI_BROWN);selector.add_child(play_selection_label)
	var plus:=Button.new();plus.text="＋";plus.custom_minimum_size=Vector2(52,48);_skin_button(plus,Color("#ead8b1"),22);plus.pressed.connect(_adjust_play_bag_count.bind(1));selector.add_child(plus)
	normal_play_button=Button.new();normal_play_button.custom_minimum_size=Vector2(350,76);_skin_button(normal_play_button,Color("#d9b56a"),20);normal_play_button.pressed.connect(_start_greenhouse_play.bind("normal"));content.add_child(normal_play_button)
	premium_play_button=Button.new();premium_play_button.custom_minimum_size=Vector2(350,76);_skin_button(premium_play_button,Color("#d18a55"),20);premium_play_button.pressed.connect(_start_greenhouse_play.bind("premium"));content.add_child(premium_play_button)
	play_message=Label.new();play_message.text="1プレイにつき1袋消費します";play_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_message.add_theme_font_size_override("font_size",15);play_message.add_theme_color_override("font_color",Color("#815a42"));content.add_child(play_message)
	var close:=Button.new();close.text="閉じる";close.custom_minimum_size=Vector2(250,44);_skin_button(close,Color("#ead8b1"),16);close.pressed.connect(_close_play_modal);content.add_child(close)

func _build_shop(hud:Control)->void:
	shop_overlay=Control.new();shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;shop_overlay.visible=false;hud.add_child(shop_overlay)
	var background:=ColorRect.new();background.color=Color("#3b241a");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_overlay.add_child(background)
	var title:=Label.new();title.text="ぷくぷく種屋";title.position=Vector2(25,24);title.size=Vector2(350,60);title.add_theme_font_size_override("font_size",31);title.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(title)
	var close:=Button.new();close.text="もどる";close.position=Vector2(446,24);close.size=Vector2(106,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_shop);shop_overlay.add_child(close)
	var counter:=PanelContainer.new();counter.position=Vector2(24,104);counter.size=Vector2(528,300);counter.add_theme_stylebox_override("panel",_box(Color("#8a5637"),Color("#d8a765"),22,4));shop_overlay.add_child(counter)
	panda_clerk_slot=TextureRect.new();panda_clerk_slot.name="PandaClerkSlot";panda_clerk_slot.custom_minimum_size=Vector2(250,220);panda_clerk_slot.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;panda_clerk_slot.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;panda_clerk_slot.tooltip_text="将来のパンダ店員PNG表示枠";counter.add_child(panda_clerk_slot)
	var placeholder:=Label.new();placeholder.text="レジ\n店員準備中";placeholder.position=Vector2(275,72);placeholder.size=Vector2(220,130);placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;placeholder.add_theme_font_size_override("font_size",21);placeholder.add_theme_color_override("font_color",UI_CREAM);counter.add_child(placeholder)
	shop_wallet_label=Label.new();shop_wallet_label.position=Vector2(28,420);shop_wallet_label.size=Vector2(520,48);shop_wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet_label.add_theme_font_size_override("font_size",23);shop_wallet_label.add_theme_color_override("font_color",Color("#ffd778"));shop_overlay.add_child(shop_wallet_label)
	shop_bag_label=Label.new();shop_bag_label.position=Vector2(28,468);shop_bag_label.size=Vector2(520,42);shop_bag_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_bag_label.add_theme_font_size_override("font_size",17);shop_bag_label.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_bag_label)
	var normal_buy:=Button.new();normal_buy.text="通常種  1袋  500円";normal_buy.position=Vector2(70,540);normal_buy.size=Vector2(436,90);_skin_button(normal_buy,Color("#d8b56b"),22);normal_buy.pressed.connect(_buy_seed_bag.bind("normal"));shop_overlay.add_child(normal_buy)
	var premium_buy:=Button.new();premium_buy.text="プレミアム種  1袋  800円";premium_buy.position=Vector2(70,650);premium_buy.size=Vector2(436,90);_skin_button(premium_buy,Color("#d18a55"),22);premium_buy.pressed.connect(_buy_seed_bag.bind("premium"));shop_overlay.add_child(premium_buy)
	shop_message=Label.new();shop_message.position=Vector2(40,770);shop_message.size=Vector2(496,72);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.add_theme_font_size_override("font_size",18);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_message)

func _build_result_overlay(hud:Control)->void:
	result_overlay=Control.new();result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.visible=false;hud.add_child(result_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.05,0.035,.68);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.add_child(shade)
	result_card=PanelContainer.new();result_card.position=Vector2(54,205);result_card.size=Vector2(468,610);result_card.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#c8944f"),28,4));result_overlay.add_child(result_card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",15);result_card.add_child(content)
	var title:=Label.new();title.text="今回の収穫";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	result_total_label=Label.new();result_total_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_total_label.add_theme_font_size_override("font_size",34);result_total_label.add_theme_color_override("font_color",Color("#b06c24"));content.add_child(result_total_label)
	result_count_label=_result_line_label();content.add_child(result_count_label)
	result_max_label=_result_line_label();content.add_child(result_max_label)
	var divider:=HSeparator.new();divider.custom_minimum_size=Vector2(380,10);content.add_child(divider)
	var notable_title:=Label.new();notable_title.text="目立った収穫株";notable_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notable_title.add_theme_font_size_override("font_size",19);notable_title.add_theme_color_override("font_color",Color("#725039"));content.add_child(notable_title)
	result_notable_label=Label.new();result_notable_label.custom_minimum_size=Vector2(390,112);result_notable_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_notable_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_notable_label.add_theme_font_size_override("font_size",18);result_notable_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(result_notable_label)
	var replay:=Button.new();replay.text="もう一度プレイ";replay.custom_minimum_size=Vector2(350,62);_skin_button(replay,Color("#b98542"),20);replay.pressed.connect(_replay_from_result);content.add_child(replay)
	var close:=Button.new();close.text="閉じる / 戻る";close.custom_minimum_size=Vector2(350,54);_skin_button(close,Color("#ead8b1"),17);close.pressed.connect(_close_result);content.add_child(close)

func _result_line_label()->Label:
	var label:=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",21);label.add_theme_color_override("font_color",Color("#65432e"));return label

func _open_play_modal()->void:
	if play_active or current_mode!="greenhouse":return
	play_modal_open=true;play_message.text="選んだ袋数をまとめて使用します";_update_play_ui()

func _close_play_modal()->void:
	play_modal_open=false;_update_play_ui()

func _start_greenhouse_play(seed_type:String)->void:
	if play_active:return
	if seed_type=="premium":
		if premium_seed_bags<selected_seed_bag_count:play_message.text="プレミアム種の袋数が足りません";return
		premium_seed_bags-=selected_seed_bag_count
	else:
		if normal_seed_bags<selected_seed_bag_count:play_message.text="通常種の袋数が足りません";return
		normal_seed_bags-=selected_seed_bag_count
	active_seed_type=seed_type;play_time_remaining=PLAY_DURATION_SECONDS*selected_seed_bag_count;play_active=true;play_modal_open=false;play_earnings_total=0;play_harvest_count=0;play_max_size=0.0;play_notable_species.clear();spawn_queue=0;spawn_timer=0.0;opening_species.clear();_clear_greenhouse_plants()
	if result_overlay:result_overlay.visible=false
	for i in range(TARGET_COUNT):spawn_plant()
	_save();_update_play_ui()

func _finish_greenhouse_play()->void:
	if not play_active:return
	play_active=false;play_time_remaining=0.0;spawn_queue=0;spawn_timer=0.0;_clear_greenhouse_plants();play_message.text="次の種袋を選んでください";_save();_update_play_ui();_show_play_result()

func _clear_greenhouse_plants()->void:
	for plant in plants.duplicate():
		if is_instance_valid(plant):
			if plant.label and is_instance_valid(plant.label):plant.label.free()
			plant.free()
	plants.clear();recent_vacated_slots.clear()

func _update_play_ui()->void:
	if not play_overlay:return
	play_overlay.visible=current_mode=="greenhouse" and not play_active and play_modal_open
	play_open_button.visible=current_mode=="greenhouse" and not play_active and not play_modal_open and (not result_overlay or not result_overlay.visible) and (not shop_overlay or not shop_overlay.visible) and (not encyclopedia_overlay or not encyclopedia_overlay.visible)
	play_timer_label.visible=current_mode=="greenhouse" and play_active
	for control in external_navigation_controls:control.visible=not play_active
	play_timer_label.text="残り %d秒"%ceili(play_time_remaining)
	play_bag_summary.text="通常種 %d袋　 プレミアム種 %d袋"%[normal_seed_bags,premium_seed_bags]
	var maximum_selectable:=maxi(1,maxi(normal_seed_bags,premium_seed_bags));selected_seed_bag_count=clampi(selected_seed_bag_count,1,maximum_selectable)
	play_selection_label.text="使用：%d袋 / プレイ時間：%d秒"%[selected_seed_bag_count,int(PLAY_DURATION_SECONDS)*selected_seed_bag_count]
	normal_play_button.text="通常種で遊ぶ　残り%d袋"%normal_seed_bags;normal_play_button.disabled=normal_seed_bags<selected_seed_bag_count
	premium_play_button.text="プレミアム種で遊ぶ　残り%d袋"%premium_seed_bags;premium_play_button.disabled=premium_seed_bags<selected_seed_bag_count

func _adjust_play_bag_count(change:int)->void:
	var maximum_selectable:=maxi(1,maxi(normal_seed_bags,premium_seed_bags));selected_seed_bag_count=clampi(selected_seed_bag_count+change,1,maximum_selectable);play_message.text="選んだ袋数をまとめて使用します";_update_play_ui()

func _open_shop()->void:
	play_modal_open=false;_update_shop_ui();shop_message.text="種袋を1袋ずつ購入できます";play_overlay.visible=false;shop_overlay.visible=true;_update_play_ui()

func _close_shop()->void:
	shop_overlay.visible=false;_update_play_ui()

func _buy_seed_bag(seed_type:String)->void:
	var price:=PREMIUM_SEED_BAG_PRICE_YEN if seed_type=="premium" else NORMAL_SEED_BAG_PRICE_YEN
	if coins<price:shop_message.text="所持金が足りません";return
	coins-=price
	if seed_type=="premium":premium_seed_bags+=1;shop_message.text="プレミアム種を1袋購入しました"
	else:normal_seed_bags+=1;shop_message.text="通常種を1袋購入しました"
	_save();_update_currency_ui();_update_shop_ui();_update_play_ui()

func _update_shop_ui()->void:
	if not shop_wallet_label:return
	shop_wallet_label.text="所持金　¥%s"%_comma(coins);shop_bag_label.text="通常種 %d袋　｜　プレミアム種 %d袋"%[normal_seed_bags,premium_seed_bags]

func _update_currency_ui()->void:
	if coin_label:coin_label.text=" ¥%s"%_comma(coins)

func _show_play_result()->void:
	result_total_label.text="合計  ＋¥%s"%_comma(play_earnings_total);result_count_label.text="収穫株数　%d株"%play_harvest_count;result_max_label.text="最大サイズ　%.1fcm"%play_max_size
	var notable:Array=play_notable_species.values();notable.sort_custom(func(a,b):return float(a.get("size",0.0))>float(b.get("size",0.0)));var lines:Array[String]=[]
	for i in range(mini(3,notable.size())):lines.append("%s　%.1fcm"%[str(notable[i].get("name","")),float(notable[i].get("size",0.0))])
	result_notable_label.text="\n".join(lines) if not lines.is_empty() else "今回はまだありません"
	result_overlay.visible=true;result_overlay.modulate.a=0.0;result_card.position.y=225.0;play_open_button.visible=false
	var tween:=create_tween().set_parallel();tween.tween_property(result_overlay,"modulate:a",1.0,.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(result_card,"position:y",205.0,.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_result()->void:
	result_overlay.visible=false;result_overlay.modulate.a=1.0;_update_play_ui()

func _replay_from_result()->void:
	_close_result();_open_play_modal()

func _build_encyclopedia(hud:Control)->void:
	encyclopedia_overlay=Control.new();encyclopedia_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.visible=false;hud.add_child(encyclopedia_overlay)
	var background:=ColorRect.new();background.color=Color("#3d2419");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.add_child(background)
	encyclopedia_list_page=Control.new();encyclopedia_list_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.add_child(encyclopedia_list_page)
	var title:=Label.new();title.text="ぷくぷく図鑑";title.position=Vector2(28,28);title.size=Vector2(390,65);title.add_theme_font_size_override("font_size",31);title.add_theme_color_override("font_color",UI_CREAM);encyclopedia_list_page.add_child(title)
	var close:=Button.new();close.text="もどる";close.position=Vector2(447,27);close.size=Vector2(105,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_encyclopedia);encyclopedia_list_page.add_child(close)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(20,105);scroll.size=Vector2(536,890);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;encyclopedia_list_page.add_child(scroll)
	encyclopedia_grid=GridContainer.new();encyclopedia_grid.columns=2;encyclopedia_grid.custom_minimum_size=Vector2(516,0);encyclopedia_grid.add_theme_constant_override("h_separation",12);encyclopedia_grid.add_theme_constant_override("v_separation",14);scroll.add_child(encyclopedia_grid)
	encyclopedia_detail_page=Control.new();encyclopedia_detail_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_detail_page.visible=false;encyclopedia_overlay.add_child(encyclopedia_detail_page)

func _open_encyclopedia()->void:
	play_modal_open=false;_refresh_encyclopedia_cards();encyclopedia_detail_page.visible=false;encyclopedia_list_page.visible=true;play_overlay.visible=false;encyclopedia_overlay.visible=true;_update_play_ui()

func _close_encyclopedia()->void:
	encyclopedia_overlay.visible=false;_update_play_ui()

func _refresh_encyclopedia_cards()->void:
	for child in encyclopedia_grid.get_children():child.free()
	for entry in catalog_species:
		var species_id:=str(entry.get("species_id",""));var found:=bool(discovered.get(species_id,false))
		var card:=Button.new();card.custom_minimum_size=Vector2(252,218);_skin_button(card,Color("#f6e7c5"),16);card.disabled=not found;encyclopedia_grid.add_child(card)
		var content:=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=10;content.offset_top=8;content.offset_right=-10;content.offset_bottom=-8;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(content)
		var image:=TextureRect.new();image.custom_minimum_size=Vector2(210,137);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=_species_texture(entry);image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if not found:image.modulate=Color(0.12,0.09,0.08,0.82)
		content.add_child(image)
		var name_label:=Label.new();name_label.text=str(entry.get("name_ja","？？？")) if found else "？？？";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",18);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
		var best_label_card:=Label.new();best_label_card.text=("自己ベスト  %.1f cm"%float(bests.get(species_id,0.0))) if found else "未発見";best_label_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_label_card.add_theme_font_size_override("font_size",14);best_label_card.add_theme_color_override("font_color",Color("#79543a"));content.add_child(best_label_card)
		if found:card.pressed.connect(_open_species_detail.bind(entry))

func _species_texture(entry:Dictionary)->Texture2D:
	var variant:=str(entry.get("visual_variant","laui"));var path:=str(SucculentClass.SPRITES.get(variant,SucculentClass.SPRITES.laui));return load(path) as Texture2D

func _build_habitat_items()->void:
	for child in habitat_items_root.get_children():child.free()
	habitat_pickups.clear();habitat_new_species_id=""
	var plant_points:Array=HABITAT_SAFE_PLANT_POINTS.duplicate()
	var point_index:=0
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(discovered.get(species_id,false)) and point_index<plant_points.size():
			_add_habitat_plant(entry,plant_points[point_index],false);point_index+=1
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if not bool(unlocked_species.get(species_id,false)):
			habitat_new_species_id=species_id
			_add_habitat_plant(entry,plant_points[min(point_index,plant_points.size()-1)],true)
			break
	_reset_daily_seeds_if_needed()
	var seed_points:Array=HABITAT_SAFE_SEED_POINTS.duplicate();var daily_rng:=RandomNumberGenerator.new();daily_rng.seed=habitat_seed_date.hash()
	for i in range(seed_points.size()-1,0,-1):
		var swap_index:=daily_rng.randi_range(0,i);var held=seed_points[i];seed_points[i]=seed_points[swap_index];seed_points[swap_index]=held
	for i in range(maxi(0,10-habitat_seeds_collected)):_add_habitat_seed(seed_points[i])
	_update_habitat_ui()

func _add_habitat_plant(entry:Dictionary,panorama_point:Vector2,is_new:bool)->void:
	var sprite:=Sprite3D.new();sprite.texture=_species_texture(entry);sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.pixel_size=1.15/maxf(1.0,float(sprite.texture.get_width()));sprite.offset.y=-float(sprite.texture.get_height())*.18;sprite.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(sprite)
	var item={"node":sprite,"kind":"new_species" if is_new else "found_species","species_id":str(entry.species_id)};habitat_pickups.append(item)
	if is_new:
		sprite.modulate=Color(1.18,1.12,.78,1.0)
		var badge:=Label3D.new();badge.text="NEW!";badge.position.y=.72;badge.font_size=42;badge.outline_size=9;badge.modulate=Color("#ffe26f");sprite.add_child(badge)

func _add_habitat_seed(panorama_point:Vector2)->void:
	var seed:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.105;mesh.height=.24;mesh.radial_segments=12;mesh.rings=6;seed.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color("#b87932");material.roughness=.72;material.emission_enabled=true;material.emission=Color("#5c3514");material.emission_energy_multiplier=.35;seed.material_override=material;seed.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(seed);habitat_pickups.append({"node":seed,"kind":"seed"})

func _panorama_point_to_world(point:Vector2,radius:float)->Vector3:
	var longitude:float=(point.x/1280.0-.5)*TAU;var latitude:float=(.5-point.y/640.0)*PI;var horizontal:=cos(latitude)
	return Vector3(sin(longitude)*horizontal,sin(latitude),-cos(longitude)*horizontal)*radius

func _reset_daily_seeds_if_needed()->void:
	var today:=Time.get_date_string_from_system()
	if habitat_seed_date!=today:habitat_seed_date=today;habitat_seeds_collected=0;_save()

func _update_habitat_ui()->void:
	if habitat_status_label:habitat_status_label.text="謎の種  %d / 10"%habitat_seeds_collected
	if mode_button and current_mode=="greenhouse":mode_button.text="原生地！" if not habitat_new_species_id.is_empty() else "原生地"

func _open_species_detail(entry:Dictionary)->void:
	for child in encyclopedia_detail_page.get_children():child.free()
	encyclopedia_list_page.visible=false;encyclopedia_detail_page.visible=true
	var back:=Button.new();back.text="一覧へ";back.position=Vector2(24,28);back.size=Vector2(105,55);_skin_button(back,Color("#fff0cf"),17);back.pressed.connect(func():encyclopedia_detail_page.visible=false;encyclopedia_list_page.visible=true);encyclopedia_detail_page.add_child(back)
	var panel:=PanelContainer.new();panel.position=Vector2(28,115);panel.size=Vector2(520,760);panel.add_theme_stylebox_override("panel",_box(Color("#f6e7c5"),Color("#d3a75f"),24,4));encyclopedia_detail_page.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",18);panel.add_child(content)
	var image:=TextureRect.new();image.custom_minimum_size=Vector2(450,470);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=_species_texture(entry);content.add_child(image)
	var name_label:=Label.new();name_label.text=str(entry.get("name_ja",""));name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",31);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
	var species_id:=str(entry.get("species_id",""));var best_detail:=Label.new();best_detail.text="自己ベスト  %.1f cm"%float(bests.get(species_id,0.0));best_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_detail.add_theme_font_size_override("font_size",23);best_detail.add_theme_color_override("font_color",Color("#98602e"));content.add_child(best_detail)

func _box(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(width); s.set_corner_radius_all(radius); s.shadow_color=Color(0.18,0.08,0.02,0.34); s.shadow_size=6; s.shadow_offset=Vector2(0,3); s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=6; s.content_margin_bottom=6; return s

func _skin_button(b:Button,bg:Color,font_size:int)->void:
	b.add_theme_font_size_override("font_size",font_size); b.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE); b.add_theme_color_override("font_hover_color",UI_BROWN); b.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.22),20,3)); b.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,20,3)); b.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.2),20,3))

func _layout() -> void:
	_update_greenhouse_pan()

func _update_greenhouse_pan()->void:
	if greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return
	var viewport_size:=get_viewport().get_visible_rect().size
	var texture_size:=greenhouse_backdrop.texture.get_size()
	var cover_scale:=maxf(viewport_size.x/texture_size.x,viewport_size.y/texture_size.y)
	var display_size:=texture_size*cover_scale
	greenhouse_pan_limit=maxf(0.0,(display_size.x-viewport_size.x)*.5)
	greenhouse_pan_x=clampf(greenhouse_pan_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_pan_target_x=clampf(greenhouse_pan_target_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_backdrop.size=display_size
	greenhouse_backdrop.position=Vector2((viewport_size.x-display_size.x)*.5+greenhouse_pan_x,(viewport_size.y-display_size.y)*.5)
	greenhouse_world_pan_x=0.0
	if camera:
		var soil_center:=camera.unproject_position(Vector3(0,.12,0))
		var soil_right:=camera.unproject_position(Vector3(1,.12,0))
		var pixels_per_world:=soil_right.x-soil_center.x
		if absf(pixels_per_world)>.001:greenhouse_world_pan_x=greenhouse_pan_x/pixels_per_world

func spawn_plant(force_golden := false) -> void:
	var chosen:Dictionary
	if force_golden:
		for entry in species:
			if str(entry.visual_variant) == "gold_laui": chosen = entry
		if chosen.is_empty(): chosen = species[0]
		forced_golden_done=true
	elif not opening_species.is_empty():chosen=opening_species.pop_front()
	else:chosen=_weighted_species()
	var pos:=_find_spawn_position()
	var label:=_plant_label(); labels_layer.add_child(label)
	var p = SucculentClass.new()
	p.original_pos=pos; p.position=pos; world_root.add_child(p); p.setup(chosen,rng.randi(),label,null)
	p.harvested.connect(_on_harvested); p.jellied.connect(_on_jellied)
	plants.append(p)

func _weighted_species()->Dictionary:
	var total:=0.0
	for s in species:total+=float(s.spawn_weight)*_seed_rarity_multiplier(s)
	var roll:=rng.randf()*total
	for s in species:
		roll-=float(s.spawn_weight)*_seed_rarity_multiplier(s)
		if roll<=0:return s
	return species[0]

func _seed_rarity_multiplier(entry:Dictionary)->float:
	if active_seed_type!="premium":return 1.0
	var rarity:=str(entry.get("rarity","通常"))
	if rarity=="スーパーレア":return PREMIUM_SUPER_RARE_WEIGHT_MULTIPLIER
	if rarity=="レア":return PREMIUM_RARE_WEIGHT_MULTIPLIER
	return 1.0

func _find_spawn_position()->Vector3:
	# Sample world positions, but accept them only after projecting into the
	# scrolling background image's source-pixel coordinates.
	var best := Vector3.ZERO
	var best_clearance := -1.0
	for attempt in range(192):
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf())
		var candidate := Vector3(cos(angle)*3.55*radius,.12,sin(angle)*3.15*radius)
		if not _spawn_center_inside_soil(candidate):continue
		var clearance := 99.0
		for plant in plants:
			if is_instance_valid(plant): clearance = minf(clearance, candidate.distance_to(plant.original_pos))
		for old_pos in recent_vacated_slots:
			clearance = minf(clearance, candidate.distance_to(old_pos) * .82)
		if clearance > best_clearance:
			best = candidate
			best_clearance = clearance
		if clearance >= .82: return candidate
	return best

func _spawn_center_inside_soil(candidate:Vector3)->bool:
	if camera==null or greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return false
	var displayed_world:=candidate+Vector3(greenhouse_world_pan_x,0,0)
	if camera.is_position_behind(displayed_world):return false
	var screen_point:=camera.unproject_position(displayed_world)
	var texture_scale:=greenhouse_backdrop.size.x/greenhouse_backdrop.texture.get_width()
	if texture_scale<=0.0:return false
	var source_point:=(screen_point-greenhouse_backdrop.position)/texture_scale
	var safe_radii:=SOIL_SOURCE_RADII-Vector2.ONE*SPAWN_SPRITE_MARGIN_SOURCE_PX
	var normalized:=source_point-SOIL_SOURCE_CENTER
	return pow(normalized.x/safe_radii.x,2.0)+pow(normalized.y/safe_radii.y,2.0)<=1.0

func _plant_label()->Label:
	var l:=Label.new(); l.text="1.6 cm"; l.size=Vector2(92,34); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",17); l.add_theme_color_override("font_color",Color.WHITE); l.add_theme_stylebox_override("normal",_box(Color(0.14,0.08,0.05,.92),Color("#f4e1be"),11,2)); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; return l

func _process(delta:float)->void:
	_update_greenhouse_pan_follow(delta)
	_update_habitat_view_follow(delta)
	if play_active:
		play_time_remaining=maxf(0.0,play_time_remaining-delta)
		if play_time_remaining<=0.0:_finish_greenhouse_play()
		elif play_timer_label:play_timer_label.text="残り %d秒"%ceili(play_time_remaining)
	if current_mode=="greenhouse" and play_active:
		for p in plants:
			if is_instance_valid(p):p.simulate(delta)
	_resolve_crowding(delta)
	_update_labels()
	if current_mode=="greenhouse" and play_active and spawn_queue>0:
		spawn_timer-=delta
		if spawn_timer<=0: spawn_queue-=1; spawn_plant(); spawn_timer=rng.randf_range(.35,.9)

func _update_greenhouse_pan_follow(delta:float)->void:
	if current_mode!="greenhouse" or is_equal_approx(greenhouse_pan_x,greenhouse_pan_target_x):return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	greenhouse_pan_x=lerpf(greenhouse_pan_x,greenhouse_pan_target_x,follow)
	if absf(greenhouse_pan_target_x-greenhouse_pan_x)<0.05:greenhouse_pan_x=greenhouse_pan_target_x
	_update_greenhouse_pan()

func _update_habitat_view_follow(delta:float)->void:
	if current_mode!="habitat":return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	view_yaw=rad_to_deg(lerp_angle(deg_to_rad(view_yaw),deg_to_rad(habitat_target_yaw),follow));view_pitch=lerpf(view_pitch,habitat_target_pitch,follow)
	if absf(wrapf(habitat_target_yaw-view_yaw,-180.0,180.0))<.02:view_yaw=habitat_target_yaw
	if absf(habitat_target_pitch-view_pitch)<.02:view_pitch=habitat_target_pitch
	_apply_view_rotation()

func _toggle_mode()->void:
	current_mode="habitat" if current_mode=="greenhouse" else "greenhouse"
	_apply_mode()

func _apply_mode()->void:
	if camera==null:return
	var greenhouse_mode:=current_mode=="greenhouse"
	if not greenhouse_mode:_build_habitat_items()
	greenhouse_layer.visible=greenhouse_mode
	habitat_items_root.visible=not greenhouse_mode
	if habitat_status_label:habitat_status_label.visible=not greenhouse_mode
	# The official greenhouse artwork already contains the finished pot and soil.
	# Keep the old geometry disabled so no duplicate rim covers the sprites.
	pot_root.visible=false
	habitat_environment.background_mode=Environment.BG_CANVAS if greenhouse_mode else Environment.BG_SKY
	for p in plants:
		if is_instance_valid(p):p.visible=greenhouse_mode;p.label.visible=false
	if greenhouse_mode:
		camera.position=Vector3(0,7.3,8.6);camera.look_at_from_position(camera.position,Vector3(0,1.05,0),Vector3.UP)
		_update_greenhouse_pan()
	else:
		camera.position=Vector3.ZERO;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()
	if mode_button:
		mode_button.text=("原生地！" if not habitat_new_species_id.is_empty() else "原生地") if greenhouse_mode else "温室"
	_update_play_ui()

func _resolve_crowding(_delta:float)->void:
	# Sprite plants remain rooted at their spawn point. Natural overlap is less
	# distracting than sliding a planted rosette around as it grows.
	for p in plants:
		if is_instance_valid(p):
			p.target_offset = Vector3.ZERO
			p.position.x = p.original_pos.x + (greenhouse_world_pan_x if current_mode=="greenhouse" else 0.0)
			p.position.z = p.original_pos.z

func _update_labels()->void:
	if current_mode!="greenhouse":
		for p in plants:
			if is_instance_valid(p):p.label.visible=false
		return
	var occupied:Array[Rect2]=[]
	var sorted:=plants.duplicate(); sorted.sort_custom(func(a,b):return a.position.z<b.position.z)
	for p in sorted:
		if not is_instance_valid(p):continue
		if camera.is_position_behind(p.global_position):
			p.label.visible=false
			continue
		var screen:=camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.7,0))
		var r:=Rect2(screen-Vector2(46,62),Vector2(92,34))
		for other in occupied:
			if r.intersects(other):r.position.y=other.position.y-37
		occupied.append(r)
		p.label.position=r.position; p.label.text="%.1f cm"%p.diameter_cm; p.label.visible=p.state=="growing" and Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).grow(80).has_point(screen)

func _input(event:InputEvent)->void:
	if (encyclopedia_overlay and encyclopedia_overlay.visible) or (shop_overlay and shop_overlay.visible) or (result_overlay and result_overlay.visible) or (play_overlay and play_overlay.visible):return
	if current_mode=="greenhouse" and not play_active:return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_end_pointer(event.position)
	elif event is InputEventScreenDrag and pointer_down:
		_drag_pointer(event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_end_pointer(event.position)
	elif event is InputEventMouseMotion and pointer_down and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_pointer(event.position, event.relative)

func _begin_pointer(screen_pos:Vector2)->void:
	pointer_down=true;pointer_start=screen_pos;pointer_last=screen_pos;pointer_travel=0.0
	greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false;greenhouse_pan_target_x=greenhouse_pan_x
	habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch

func _drag_pointer(screen_pos:Vector2,relative:Vector2)->void:
	pointer_travel+=relative.length();pointer_last=screen_pos
	if current_mode=="greenhouse":
		if not greenhouse_drag_started:
			greenhouse_drag_accumulator+=relative.x
			if absf(greenhouse_drag_accumulator)<=GREENHOUSE_DRAG_DEAD_ZONE:return
			greenhouse_drag_started=true
			var excess:=greenhouse_drag_accumulator-signf(greenhouse_drag_accumulator)*GREENHOUSE_DRAG_DEAD_ZONE
			greenhouse_pan_target_x=clampf(greenhouse_pan_target_x+excess*GREENHOUSE_DRAG_SCALE,-greenhouse_pan_limit,greenhouse_pan_limit)
		else:
			greenhouse_pan_target_x=clampf(greenhouse_pan_target_x+relative.x*GREENHOUSE_DRAG_SCALE,-greenhouse_pan_limit,greenhouse_pan_limit)
		return
	if current_mode!="habitat":return
	if not greenhouse_drag_started:
		greenhouse_drag_accumulator+=relative.x
		if absf(greenhouse_drag_accumulator)<=GREENHOUSE_DRAG_DEAD_ZONE:return
		greenhouse_drag_started=true
		var excess:=greenhouse_drag_accumulator-signf(greenhouse_drag_accumulator)*GREENHOUSE_DRAG_DEAD_ZONE
		habitat_target_yaw=fmod(habitat_target_yaw+excess*HABITAT_DRAG_SCALE,360.0)
	else:habitat_target_yaw=fmod(habitat_target_yaw+relative.x*HABITAT_DRAG_SCALE,360.0)
	habitat_target_pitch=clampf(habitat_target_pitch+relative.y*.025,-13.0,9.0)

func _end_pointer(screen_pos:Vector2)->void:
	if not pointer_down:return
	pointer_down=false
	if pointer_travel<13.0 and pointer_start.distance_to(screen_pos)<16.0:
		if current_mode=="greenhouse":_try_harvest(screen_pos)
		elif current_mode=="habitat":_try_habitat_pick(screen_pos)

func _apply_view_rotation()->void:
	if camera:camera.rotation_degrees=Vector3(view_pitch,view_yaw,0.0)

func _try_harvest(screen_pos:Vector2)->void:
	# label-aware screen selection favors small visible plants when overlap occurs
	var candidates:Array=[]
	for p in plants:
		if not is_instance_valid(p) or p.state!="growing" or camera.is_position_behind(p.global_position):continue
		var center: Vector2 = camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.48,0))
		var top: Vector2 = camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*1.25,0))
		var radius: float=clamp(center.distance_to(top)*1.15,30.0,180.0)
		var dist: float=center.distance_to(screen_pos)
		if dist<radius:candidates.append({"p":p,"score":dist/max(radius,1.0)+p.visual_scale*.08})
	if candidates.size()>0:
		candidates.sort_custom(func(a,b):return a.score<b.score);candidates[0].p.harvest()

func _try_habitat_pick(screen_pos:Vector2)->void:
	var candidates:Array=[]
	for item in habitat_pickups:
		var node=item.get("node")
		if not is_instance_valid(node) or camera.is_position_behind(node.global_position):continue
		var projected:=camera.unproject_position(node.global_position);var distance:=projected.distance_to(screen_pos)
		if distance<42.0:candidates.append({"item":item,"distance":distance})
	if candidates.is_empty():return
	candidates.sort_custom(func(a,b):return a.distance<b.distance);var selected:Dictionary=candidates[0].item
	if str(selected.kind)=="seed":_collect_habitat_seed(selected)
	elif str(selected.kind)=="new_species":_collect_habitat_species(selected)
	elif str(selected.kind)=="found_species":_squish_habitat_plant(selected)

func _collect_habitat_seed(item:Dictionary)->void:
	if habitat_seeds_collected>=10:return
	habitat_seeds_collected+=1;habitat_pickups.erase(item);var node=item.node;_show_habitat_message(node.global_position,"謎の種 GET!",Color("#ffe4a0"));node.queue_free();_save();_update_habitat_ui()

func _collect_habitat_species(item:Dictionary)->void:
	var node:Sprite3D=item.node;habitat_pickups.erase(item);node.visible=false
	var flying:=TextureRect.new();flying.texture=node.texture;flying.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flying.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;flying.mouse_filter=Control.MOUSE_FILTER_IGNORE;flying.size=Vector2(112,112);flying.position=camera.unproject_position(node.global_position)-flying.size*.5;flying.pivot_offset=flying.size*.5;effects_layer.add_child(flying)
	var target:=Vector2(500,150)
	if encyclopedia_icon_button:target=encyclopedia_icon_button.global_position+encyclopedia_icon_button.size*.5
	var tween:=create_tween().set_parallel();tween.tween_property(flying,"position",target-flying.size*.5,.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);tween.tween_property(flying,"scale",Vector2(.08,.08),.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);tween.tween_property(flying,"rotation",.18,.62);tween.chain().tween_callback(_complete_habitat_species_get.bind(item,flying))

func _complete_habitat_species_get(item:Dictionary,flying:TextureRect)->void:
	var species_id:=str(item.species_id);unlocked_species[species_id]=true;discovered[species_id]=true;habitat_new_species_id=""
	for entry in catalog_species:
		if str(entry.species_id)==species_id:
			var already_present:=false
			for active_entry in species:
				if str(active_entry.species_id)==species_id:already_present=true;break
			if not already_present:species.append(entry);opening_species.append(entry)
			_show_habitat_message(item.node.global_position,"%s GET!"%str(entry.name_ja),Color("#fff18a"));break
	if is_instance_valid(item.node):item.node.queue_free()
	if is_instance_valid(flying):flying.queue_free()
	_save();_update_habitat_ui()

func _squish_habitat_plant(item:Dictionary)->void:
	var node:Sprite3D=item.node;var original_scale:=node.scale;var tween:=create_tween();tween.tween_property(node,"scale",Vector3(original_scale.x*1.04,original_scale.y*.84,original_scale.z),.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(node,"scale",original_scale,.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_habitat_message(world_position:Vector3,message:String,color:Color)->void:
	var label:=Label.new();label.text=message;label.size=Vector2(300,80);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",25);label.add_theme_color_override("font_color",color);label.add_theme_color_override("font_outline_color",UI_BROWN);label.add_theme_constant_override("outline_size",8);label.position=camera.unproject_position(world_position)-Vector2(150,40);effects_layer.add_child(label)
	var tween:=create_tween().set_parallel();tween.tween_property(label,"position:y",label.position.y-70,.7);tween.tween_property(label,"modulate:a",0.0,.7).set_delay(.25);tween.chain().tween_callback(label.queue_free)

func _on_harvested(p)->void:
	var old:=float(bests.get(p.data.species_id,0.0));var is_record:bool=p.diameter_cm>old
	discovered[p.data.species_id]=true
	if is_record:bests[p.data.species_id]=p.diameter_cm
	var reward:=harvest_reward_yen(p.diameter_cm);coins+=reward;_save();_update_best_ui();_update_currency_ui()
	if play_active:
		play_earnings_total+=reward;play_harvest_count+=1;play_max_size=maxf(play_max_size,p.diameter_cm)
		var species_id:=str(p.data.species_id);var notable=play_notable_species.get(species_id,{})
		if notable.is_empty() or p.diameter_cm>float(notable.get("size",0.0)):play_notable_species[species_id]={"name":str(p.data.name_ja),"size":p.diameter_cm}
	_show_harvest_result(p,reward)
	if is_record:_show_record(p,reward)
	var tween:=create_tween().set_parallel();tween.tween_property(p,"position:y",p.position.y+2.0,.42).set_trans(Tween.TRANS_BACK);tween.tween_property(p,"scale",p.scale*1.2,.22);tween.chain().tween_property(p,"scale",Vector3.ONE*0.01,.24)
	_cleanup_later(p,.68)

func _on_jellied(p)->void:
	_show_float(p,"ぷるん…\nジュレ",Color("#e7c9f0"))
	var tw:=create_tween();tw.tween_property(p,"scale",Vector3(p.scale.x*1.05,p.scale.y*.46,p.scale.z*1.05),.28).set_trans(Tween.TRANS_BOUNCE);tw.tween_interval(.25);tw.tween_property(p,"scale",Vector3.ONE*0.01,.38)
	_cleanup_later(p,1.0)

func _cleanup_later(p,delay:float)->void:
	recent_vacated_slots.append(p.original_pos)
	while recent_vacated_slots.size()>12:recent_vacated_slots.pop_front()
	plants.erase(p)
	if play_active:spawn_queue+=1;spawn_timer=rng.randf_range(.35,.85)
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(p):p.label.queue_free();p.queue_free()

func _show_float(p,text:String,color:Color)->void:
	var l:=Label.new();l.text=text;l.size=Vector2(230,90);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_outline_color",UI_BROWN);l.add_theme_constant_override("outline_size",7);l.position=camera.unproject_position(p.global_position)-Vector2(115,40);effects_layer.add_child(l)
	var tw:=create_tween().set_parallel();tw.tween_property(l,"position:y",l.position.y-85,.62).set_trans(Tween.TRANS_BACK);tw.tween_property(l,"modulate:a",0.0,.62).set_delay(.18);tw.chain().tween_callback(l.queue_free)

func _show_harvest_result(plant,reward:int)->void:
	var panel:=PanelContainer.new();panel.size=Vector2(220,132);panel.position=camera.unproject_position(plant.global_position)-Vector2(110,82);panel.pivot_offset=panel.size*.5;panel.scale=Vector2(.78,.78);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.92),Color("#f0cc82"),17,2));effects_layer.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",0);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(content)
	var name_label:=Label.new();name_label.text=str(plant.data.name_ja);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",20);name_label.add_theme_color_override("font_color",Color.WHITE);content.add_child(name_label)
	var size_label:=Label.new();size_label.text="%.1fcm"%plant.diameter_cm;size_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;size_label.add_theme_font_size_override("font_size",19);size_label.add_theme_color_override("font_color",UI_CREAM);content.add_child(size_label)
	var yen_label:=Label.new();yen_label.text="＋¥%d"%reward;yen_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;yen_label.add_theme_font_size_override("font_size",27);yen_label.add_theme_color_override("font_color",Color("#ffe06f"));yen_label.add_theme_color_override("font_outline_color",Color("#6b3518"));yen_label.add_theme_constant_override("outline_size",4);content.add_child(yen_label)
	var tween:=create_tween();tween.tween_property(panel,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);tween.tween_interval(1.12);tween.set_parallel(true);tween.tween_property(panel,"position:y",panel.position.y-34,.5).set_trans(Tween.TRANS_QUAD);tween.tween_property(panel,"modulate:a",0.0,.5);tween.set_parallel(false);tween.tween_callback(panel.queue_free)

func _show_record(p,reward:int)->void:
	record_text.text="収穫記録更新！\nNEW RECORD\n%.1f cm\n+%d円"%[p.diameter_cm,reward];record_card.visible=true;record_card.scale=Vector2(.72,.72);record_card.pivot_offset=record_card.size/2
	var tw:=create_tween();tw.tween_property(record_card,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK);tw.tween_interval(2.2);tw.tween_property(record_card,"modulate:a",0.0,.25);tw.tween_callback(func():record_card.visible=false;record_card.modulate.a=1.0)

func _update_best_ui()->void:
	var top:=0.0
	for v in bests.values():top=max(top,float(v))
	best_label.text="最高  ベスト記録\n     %.1f cm"%top

static func harvest_reward_yen(size_cm:float)->int:
	if size_cm<10.0:return 0
	if size_cm<20.0:return 10
	if size_cm<30.0:return 50
	if size_cm<40.0:return 100
	if size_cm<50.0:return 200
	if size_cm<60.0:return 300
	if size_cm<70.0:return 400
	if size_cm<80.0:return 500
	if size_cm<90.0:return 600
	if size_cm<100.0:return 1000
	if size_cm<110.0:return 1500
	if size_cm<120.0:return 2000
	if size_cm<130.0:return 2500
	if size_cm<140.0:return 3000
	return 3500+maxi(0,int(floor((size_cm-140.0)/10.0)))*500

func _comma(value:int)->String:
	var s:=str(value);var out:="";var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0:out=","+out
		out=s[i]+out;count+=1
	return out
