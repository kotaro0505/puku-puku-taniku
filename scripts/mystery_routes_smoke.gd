extends Node


func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._reset_progression_state()
	game.intro_story_complete = true
	game.first_colorata_confirmed = true
	game.trio_originals_confirmed = true
	game.total_play_count = 3
	game.formal_play_count = 1
	game.habitat_unlocked = true
	game.habitat_awakened = true
	game.habitat_awakening_event_complete = true
	game.habitat_second_awakened = true
	game.habitat_second_awakening_complete = true
	game.act2_unlocked = true
	game.seed_shop_open = true
	game.mystery_items_acquired = true
	game.puku_gauge_intro_complete = true
	game.habitat_tutorial_complete = true
	game.tutorial_steps["play1_dialog"] = true

	# Post-awakening rain gameplay no longer exists and cannot assign a species.
	game.rain_event_pending = false
	game.rain_bonus_active = false
	game._roll_rain_event()
	assert(not game.rain_event_pending and not game.rain_bonus_active)
	assert(game.rain_completion_count == 0)

	var mystery_ids: Array[String] = game._mystery_event_species_ids()
	assert(mystery_ids.size() == 6)
	# The retired research-25 route never assigns or gifts a mystery species.
	game.armadillo_research_total = 24
	game.mystery_seed_count = 1
	game.armadillo_research_rewards.clear()
	game._accept_armadillo_research()
	assert(game.armadillo_research_total == 25)
	assert(not game.mystery_route_assignments.has(game.MYSTERY_ROUTE_RESEARCH))
	assert(game.shop_chatter_acquired_species.is_empty())
	for species_id in mystery_ids:
		assert(not bool(game.discovered.get(species_id, false)))
	game._hide_shop_chatter(true)

	# The retired 100 cm route likewise records the harvest but gives no special
	# species and creates no replacement condition.
	game.active_seed_type = "normal"
	game.play_active = true
	game._spawn_specific_plant("colorata")
	var giant = game.plants.back()
	giant.diameter_cm = 100.0
	giant.harvest()
	assert(not game.mystery_route_assignments.has(game.MYSTERY_ROUTE_BEST_100))
	assert(not game.best_100_achieved)
	for species_id in mystery_ids:
		assert(not bool(game.discovered.get(species_id, false)))
		assert(species_id not in game.pending_habitat_species)
	game.play_active = false
	game._clear_greenhouse_plants()

	assert(game.mystery_route_assignments.is_empty())

	# Ordinary seed packs still exclude all special-route mystery species.
	for species_id in mystery_ids:
		game.greenhouse_available[species_id] = true
		game.discovered[species_id] = true
	game._apply_saved_unlocks()
	for seed_type in ["normal", "volume", "premium"]:
		for draw in range(120):
			assert(str(game._select_species_for_seed(seed_type).get("species_id", "")) not in mystery_ids)
	game.discovered["transparent_succulent"] = true
	game._refresh_seed_pack_unlocks()
	assert(game._mystery_seed_pack_unlocked())
	for draw in range(30):
		assert(str(game._select_species_for_seed("mystery").get("species_id", "")) == "transparent_succulent")

	# A legacy save that already received a route reward keeps every owned and
	# settled record, but loading it does not grant a second copy.
	game.mystery_route_assignments={game.MYSTERY_ROUTE_RESEARCH:"transparent_succulent"}
	game.mystery_route_completed={game.MYSTERY_ROUTE_RESEARCH:true}
	game.mystery_route_dialog_seen={game.MYSTERY_ROUTE_RESEARCH:true}
	game.discovered["transparent_succulent"]=true
	game.species_get_counts["transparent_succulent"]=1
	game.greenhouse_available["transparent_succulent"]=true
	game.habitat_returned_species["transparent_succulent"]=true
	game.best_100_achieved=true
	game._save()
	var saved_assignments: Dictionary = game.mystery_route_assignments.duplicate(true)
	game.mystery_route_assignments.clear()
	game.discovered.erase("transparent_succulent");game.species_get_counts.erase("transparent_succulent");game.habitat_returned_species.erase("transparent_succulent")
	game._load_save()
	assert(game.mystery_route_assignments == saved_assignments)
	assert(bool(game.discovered.get("transparent_succulent",false)) and game._species_get_count("transparent_succulent")==1 and bool(game.habitat_returned_species.get("transparent_succulent",false)))
	assert(game.rain_completion_count == 0 and game.best_100_achieved)
	print("MYSTERY_ROUTES_SMOKE_OK research25=retired best100=retired rain_route=retired legacy_rewards=preserved")
	get_tree().quit()
