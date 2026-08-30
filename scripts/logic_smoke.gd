extends Node
func _ready()->void:
	_verify_jelly_probability()
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.plants.size()==12)
	assert(game.catalog_species.size()==11)
	var species_ids:Array=[]
	for entry in game.species:species_ids.append(str(entry.species_id))
	for required in ["laui","golden_laui","colorata","affinis","lutea","shaviana","kannte"]:assert(required in species_ids)
	var opening_ids:Array=[]
	for plant in game.plants:opening_ids.append(str(plant.data.species_id))
	for required in ["laui","golden_laui","colorata","affinis","lutea","shaviana","kannte"]:assert(required in opening_ids)
	for plant in game.plants:
		plant.jelly_checks_enabled=false
		assert(plant.growth_rhythm_period >= 16.0 and plant.growth_rhythm_period <= 28.0)
		assert(is_equal_approx(plant._integrated_growth_multiplier(0.0,plant.growth_rhythm_period),plant.growth_rhythm_period))
		var diameter_before:float=plant.diameter_cm
		plant.simulate(0.01)
		assert(plant.diameter_cm>diameter_before)
	var unique_positions:Dictionary={}
	for plant in game.plants:
		unique_positions["%.2f,%.2f"%[plant.original_pos.x,plant.original_pos.z]]=true
		assert(game._spawn_center_inside_soil(plant.original_pos))
	assert(unique_positions.size()>=11)
	var initial_count:int=game.plants.size()
	var harvest_target=game.plants[0]
	harvest_target.jelly_checks_enabled=false
	var rooted_position:Vector3=harvest_target.position
	var initial_sprite_scale:float=harvest_target.plant_sprite.scale.x
	for i in range(700): harvest_target.simulate(.1)
	assert(harvest_target.plant_sprite.scale.x>initial_sprite_scale)
	assert(harvest_target.diameter_cm>70.0)
	assert(harvest_target.position.is_equal_approx(rooted_position))
	assert(harvest_target.scale.is_equal_approx(Vector3.ONE))
	assert(harvest_target.plant_sprite.texture!=null)
	var grown_scale:float=harvest_target.plant_sprite.scale.x
	var grown_diameter:float=harvest_target.diameter_cm
	assert(game.current_mode=="greenhouse" and not game.pot_root.visible)
	game._toggle_mode();assert(game.current_mode=="habitat" and not game.pot_root.visible)
	game.view_yaw=0.0;game._apply_view_rotation();var first_basis:Basis=game.camera.transform.basis
	game.view_yaw=360.0;game._apply_view_rotation();assert(game.camera.transform.basis.is_equal_approx(first_basis))
	game.view_yaw=0.0;game.view_pitch=-3.0;var count_before_drag:int=game.plants.size();var yaw_before:float=game.view_yaw;var pitch_before:float=game.view_pitch;var paused_age:float=game.plants[0].age;game._begin_pointer(Vector2(300,500));game._drag_pointer(Vector2(380,560),Vector2(80,60));assert(game.habitat_target_yaw>yaw_before and game.habitat_target_pitch>pitch_before);game._update_habitat_view_follow(.5);game._end_pointer(Vector2(380,560));assert(game.plants.size()==count_before_drag);assert(game.view_yaw>yaw_before and game.view_pitch>pitch_before);game._process(.2);assert(is_equal_approx(game.plants[0].age,paused_age));assert(game.habitat_pickups.size()>=10)
	game._toggle_mode();assert(game.current_mode=="greenhouse")
	var pan_target=game.plants[0];var pan_screen_before:Vector2=game.camera.unproject_position(pan_target.global_position);var backdrop_y:float=game.greenhouse_backdrop.position.y
	game._begin_pointer(Vector2(280,500));game._drag_pointer(Vector2(282,500),Vector2(2,0));assert(is_equal_approx(game.greenhouse_pan_target_x,game.greenhouse_pan_x));game._drag_pointer(Vector2(380,500),Vector2(98,0));assert(game.greenhouse_pan_target_x>game.greenhouse_pan_x);game._update_greenhouse_pan_follow(.5);game._resolve_crowding(0.0);game._end_pointer(Vector2(380,500));var pan_screen_after:Vector2=game.camera.unproject_position(pan_target.global_position)
	assert(game.greenhouse_pan_x>0.0 and game.greenhouse_pan_x<=game.greenhouse_pan_limit);assert(game.greenhouse_pan_limit<80.0);assert(pan_screen_after.x>pan_screen_before.x);assert(is_equal_approx(game.greenhouse_backdrop.position.y,backdrop_y))
	for plant in game.plants:assert(game._spawn_center_inside_soil(plant.original_pos))
	game.greenhouse_pan_x=0.0;game._update_greenhouse_pan();game._resolve_crowding(0.0)
	var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(1.2).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	assert(bool(game.discovered.get(species_id,false)))
	game._open_encyclopedia();assert(game.encyclopedia_overlay.visible);assert(game.encyclopedia_grid.get_child_count()==game.catalog_species.size());game._close_encyclopedia()
	assert(game.plants.size()==initial_count)
	var replacement_position:Vector3=game.plants[-1].original_pos;assert(replacement_position.distance_to(rooted_position)>.1)
	for plant in game.plants:plant.jelly_checks_enabled=false
	var jelly_target=game.plants[0]
	jelly_target.jelly()
	assert(jelly_target.state=="jelly")
	await get_tree().create_timer(1.2).timeout
	assert(game.plants.size()==initial_count)
	print("SMOKE_OK panorama360 plants=",game.plants.size()," diameter=",grown_diameter," sprite_scale=",grown_scale," rooted=true species=",species_id)
	get_tree().quit()

func _verify_jelly_probability()->void:
	var succulent_script = load("res://scripts/succulent.gd")
	for ramp_end in [8.0,11.0,16.5,25.0]:
		assert(absf(succulent_script.jelly_chance_per_second(0.0,ramp_end)-0.0001)<0.000001)
		assert(absf(succulent_script.jelly_chance_per_second(4.0,ramp_end)-0.005)<0.000001)
		assert(absf(succulent_script.jelly_chance_per_second(ramp_end,ramp_end)-0.06)<0.000001)
		assert(absf(succulent_script.jelly_chance_per_second(100.0,ramp_end)-0.06)<0.000001)
		var reference_probability = succulent_script.jelly_probability_for_interval(0.0,35.0,ramp_end)
		for fps in [30,60,120]:
			var delta := 1.0/float(fps);var survival:=1.0
			for frame in range(35*fps):survival*=1.0-succulent_script.jelly_probability_for_interval(frame*delta,delta,ramp_end)
			assert(is_equal_approx(1.0-survival,reference_probability))
