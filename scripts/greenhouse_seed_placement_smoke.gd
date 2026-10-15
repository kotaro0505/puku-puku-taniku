extends Node

func _ready()->void:
	var game=load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_configure_greenhouse(game)
	_test_empty_soil_beats_root_only_clearance(game)
	_test_normal_refill_density(game)
	_test_scrolled_seed_placement(game)
	_test_growth_speed_independence(game)
	await _test_harvest_and_jelly_refill(game)
	await _test_fully_covered_soil_uses_rear_layer(game)
	game._clear_greenhouse_plants()
	game.queue_free()
	await get_tree().process_frame
	print("GREENHOUSE_SEED_PLACEMENT_SMOKE_OK alpha_visual_priority=true root_spacing_priority=true small_medium_5to8=true scrolled_left+right=true giant_fallback=behind speed=1x+10x harvest_refill=true jelly_refill=true soil_bounds=true")
	get_tree().quit()

func _configure_greenhouse(game)->void:
	game.opening_finished=true
	game.current_mode="greenhouse"
	game.play_active=false
	game.catalog_preview_mode_active=false
	game.dev_jelly_test_active=false
	for overlay in [game.opening_overlay,game.opening_story_overlay,game.intro_overlay,game.settings_overlay,game.play_overlay,game.result_overlay,game.tutorial_guide_overlay]:
		if overlay:overlay.visible=false
	game._apply_mode()
	game._clear_greenhouse_plants()
	game.recent_vacated_slots.clear()
	game.pending_seed_positions.clear()

func _spawn_at(game,species_id:String,position:Vector3,diameter_cm:float,growth_speed:=1.0):
	game.species_get_counts[species_id]=maxi(1,game._species_get_count(species_id))
	game._spawn_specific_plant(species_id)
	var plant=game.plants.back()
	plant.jelly_checks_enabled=false
	plant.original_pos=position
	plant.position=position
	plant.growth_speed_multiplier=growth_speed
	plant.fast_forward_to_diameter(diameter_cm)
	plant.plant_sprite.position.x=0.0
	plant.plant_sprite.rotation.z=0.0
	plant.sync_screen_visual(game.camera)
	return plant

func _root_clearance(game,candidate:Vector3)->float:
	var clearance:=99.0
	for plant in game.plants:
		if is_instance_valid(plant):clearance=minf(clearance,candidate.distance_to(plant.original_pos))
	for pending_position in game.pending_seed_positions:clearance=minf(clearance,candidate.distance_to(pending_position))
	for old_position in game.recent_vacated_slots:clearance=minf(clearance,candidate.distance_to(old_position)*.82)
	return clearance

func _sampled_regression_seed(game)->int:
	# Find a deterministic sample sequence where the former root-only early return
	# lands on a visible leaf even though a later sampled point is empty.
	for seed_value in range(1,401):
		var sample_rng:=RandomNumberGenerator.new();sample_rng.seed=seed_value
		var old_first_safe_overlaps:=false
		var old_first_safe_set:=false
		var has_empty:=false
		for _attempt in range(192):
			var angle:=sample_rng.randf_range(0.0,TAU)
			var radius:=sqrt(sample_rng.randf())
			var candidate:=Vector3(cos(angle)*3.55*radius,.12,sin(angle)*3.15*radius)
			if not game._spawn_center_inside_soil(candidate):continue
			var assessment:Dictionary=game._spawn_visual_assessment(candidate)
			if int(assessment.get("overlap_samples",0))==0:has_empty=true
			if not old_first_safe_set and _root_clearance(game,candidate)>=game.SPAWN_ROOT_CLEARANCE:
				old_first_safe_overlaps=int(assessment.get("overlap_samples",0))>0
				old_first_safe_set=true
		if old_first_safe_overlaps and has_empty:return seed_value
	return -1

func _assert_spawn_policy(game,candidate:Vector3,context:String)->Dictionary:
	assert(game._spawn_center_inside_soil(candidate),"spawn left the visible soil context=%s position=%s"%[context,candidate])
	game._sync_plant_screen_visuals()
	var assessment:Dictionary=game._spawn_visual_assessment(candidate)
	var independent_alpha_hits:=0
	for plant in game.plants:
		if not is_instance_valid(plant) or plant.state!="growing":continue
		for screen_point in game._spawn_seed_screen_samples(candidate):
			if bool(plant.screen_hit_test(game.camera,screen_point).get("opaque_artwork_hit",false)):independent_alpha_hits+=1
	assert(independent_alpha_hits==int(assessment.get("overlap_samples",-1)),"fast spawn alpha sampling disagreed with the established rendered hit transform context=%s fast=%s reference=%d"%[context,assessment,independent_alpha_hits])
	if int(assessment.get("overlap_samples",0))>0:
		assert(bool(assessment.get("behind_all_overlaps",false)),"covered spawn was not behind every overlapping plant context=%s assessment=%s position=%s"%[context,assessment,candidate])
	return assessment

func _test_empty_soil_beats_root_only_clearance(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	_spawn_at(game,"colorata",Vector3(0,.12,2.5),30.0)
	game._sync_plant_screen_visuals()
	var regression_seed:=_sampled_regression_seed(game)
	assert(regression_seed>0,"could not construct a root-clear but artwork-covered regression sequence")
	var position_rng:=RandomNumberGenerator.new();position_rng.seed=regression_seed
	var chosen:Vector3=game._find_spawn_position(position_rng)
	var assessment:=_assert_spawn_policy(game,chosen,"visual_priority")
	assert(int(assessment.get("overlap_samples",-1))==0,"empty sampled soil lost to a root-only early return seed=%d assessment=%s"%[regression_seed,assessment])

func _test_normal_refill_density(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	var position_rng:=RandomNumberGenerator.new();position_rng.seed=52058
	var sizes:Array[float]=[10.0,18.0,30.0,45.0,60.0,80.0,100.0,150.0]
	var species_ids:Array[String]=["colorata","laui","yumekawa_milky_dream"]
	for index in range(sizes.size()):
		var chosen:Vector3=game._find_spawn_position(position_rng)
		_assert_spawn_policy(game,chosen,"normal_refill_%d"%(index+1))
		_spawn_at(game,species_ids[index%species_ids.size()],chosen,sizes[index])
	game._sync_plant_screen_visuals()
	assert(game.plants.size()==8,"normal 5-8 plant refill setup did not retain eight plants")

func _test_scrolled_seed_placement(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	_spawn_at(game,"colorata",Vector3(-1.75,.12,2.15),40.0)
	_spawn_at(game,"laui",Vector3(1.45,.12,.35),80.0)
	_spawn_at(game,"yumekawa_milky_dream",Vector3(-.25,.12,-1.8),120.0)
	for index in range(2):
		var ratio:float=-.9 if index==0 else .9
		game.greenhouse_pan_x=game.greenhouse_pan_limit*ratio;game.greenhouse_pan_target_x=game.greenhouse_pan_x;game._update_greenhouse_pan();game._resolve_crowding(0.0);game._sync_plant_screen_visuals()
		var position_rng:=RandomNumberGenerator.new();position_rng.seed=71173+index
		_assert_spawn_policy(game,game._find_spawn_position(position_rng),"scrolled_%s"%("left" if index==0 else "right"))
	game.greenhouse_pan_x=0.0;game.greenhouse_pan_target_x=0.0;game._update_greenhouse_pan();game._resolve_crowding(0.0)

func _test_growth_speed_independence(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	var slow=_spawn_at(game,"laui",Vector3(-1.45,.12,.8),120.0,1.0)
	var fast=_spawn_at(game,"yumekawa_milky_dream",Vector3(1.35,.12,.15),500.0,10.0)
	fast.simulate(1.0/30.0);slow.simulate(1.0/30.0)
	game._sync_plant_screen_visuals()
	var position_rng:=RandomNumberGenerator.new();position_rng.seed=101001
	_assert_spawn_policy(game,game._find_spawn_position(position_rng),"speed_1x_10x")

func _test_harvest_and_jelly_refill(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	var first=_spawn_at(game,"colorata",Vector3(-1.2,.12,.65),100.0)
	_spawn_at(game,"laui",Vector3(1.1,.12,.4),100.0)
	_spawn_at(game,"yumekawa_milky_dream",Vector3(0,.12,-.9),150.0)
	game._sync_plant_screen_visuals()
	first.state="harvested"
	game._cleanup_later(first,.01)
	var harvest_rng:=RandomNumberGenerator.new();harvest_rng.seed=4401
	_assert_spawn_policy(game,game._find_spawn_position(harvest_rng),"after_harvest")
	await get_tree().create_timer(.02).timeout
	var jelly=game.plants.front();jelly.state="jelly"
	game._cleanup_later(jelly,.01)
	var jelly_rng:=RandomNumberGenerator.new();jelly_rng.seed=4402
	_assert_spawn_policy(game,game._find_spawn_position(jelly_rng),"after_jelly")
	await get_tree().create_timer(.02).timeout

func _test_fully_covered_soil_uses_rear_layer(game)->void:
	game._clear_greenhouse_plants();game.recent_vacated_slots.clear();game.pending_seed_positions.clear()
	_spawn_at(game,"colorata",Vector3(-.3,.12,2.5),10000.0)
	_spawn_at(game,"laui",Vector3(.3,.12,.4),10000.0)
	game._sync_plant_screen_visuals()
	var seed_value:=987654
	var expected_max_rear_clearance:=-1.0
	var audit_rng:=RandomNumberGenerator.new();audit_rng.seed=seed_value
	for _attempt in range(192):
		var angle:=audit_rng.randf_range(0.0,TAU)
		var radius:=sqrt(audit_rng.randf())
		var candidate:=Vector3(cos(angle)*3.55*radius,.12,sin(angle)*3.15*radius)
		if not game._spawn_center_inside_soil(candidate):continue
		var candidate_assessment:Dictionary=game._spawn_visual_assessment(candidate)
		if int(candidate_assessment.get("overlap_samples",0))>0 and int(candidate_assessment.get("front_conflict_samples",0))==0:
			expected_max_rear_clearance=maxf(expected_max_rear_clearance,_root_clearance(game,candidate))
	assert(expected_max_rear_clearance>0.0,"fully covered fallback audit found no rear-layer candidate")
	var position_rng:=RandomNumberGenerator.new();position_rng.seed=seed_value
	var chosen:Vector3=game._find_spawn_position(position_rng)
	var assessment:=_assert_spawn_policy(game,chosen,"fully_covered")
	assert(int(assessment.get("overlap_samples",0))>0,"fully covered fallback setup unexpectedly found empty soil assessment=%s"%assessment)
	var chosen_clearance:=_root_clearance(game,chosen)
	assert(chosen_clearance>=expected_max_rear_clearance-.0001,"covered fallback sacrificed natural root spacing chosen=%.4f best_rear=%.4f position=%s assessment=%s"%[chosen_clearance,expected_max_rear_clearance,chosen,assessment])
	assert(int(assessment.get("seed_draw_order",0))<0,"fallback seed did not receive a draw order behind the plant artwork assessment=%s"%assessment)
	game._animate_and_spawn_greenhouse_seed(chosen)
	var seed_visual=game.plant_screen_layer.find_child("GreenhouseSeedAnimation",false,false)
	assert(seed_visual!=null,"covered seed animation stayed in the foreground UI layer")
	assert(str(seed_visual.get_meta("visual_spawn_mode",""))=="behind" and seed_visual.z_index==int(assessment.get("seed_draw_order",-1)),"covered seed animation was not composited behind its overlapping leaves")
	var capture_path:=OS.get_environment("SEED_PLACEMENT_CAPTURE_PATH")
	if not capture_path.is_empty():
		await get_tree().create_timer(.19).timeout
		await get_tree().process_frame
		var capture:=get_viewport().get_texture().get_image()
		assert(capture!=null and not capture.is_empty() and capture.save_png(capture_path)==OK,"could not save rendered seed placement capture")
	await get_tree().create_timer(.16).timeout
