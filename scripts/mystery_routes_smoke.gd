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
	game.seed_shop_open = true
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
	# Research at cumulative 25 grants one special-route species directly.
	game.armadillo_research_total = 24
	game.mystery_seed_count = 1
	game.armadillo_research_rewards.clear()
	game._accept_armadillo_research()
	var research_id := str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_RESEARCH, ""))
	assert(research_id in mystery_ids)
	assert(bool(game.discovered.get(research_id, false)))
	assert(bool(game.habitat_returned_species.get(research_id, false)))
	assert(game.shop_chatter_acquired_species == [research_id])
	game._hide_shop_chatter(true)

	# A formal-play 100 cm greenhouse harvest grants a different species
	# directly; it never queues an unknown habitat plant.
	game.active_seed_type = "normal"
	game.play_active = true
	game._spawn_specific_plant("colorata")
	var giant = game.plants.back()
	giant.diameter_cm = 100.0
	giant.harvest()
	var best_id := str(game.mystery_route_assignments.get(game.MYSTERY_ROUTE_BEST_100, ""))
	assert(best_id in mystery_ids and best_id != research_id)
	assert(bool(game.discovered.get(best_id, false)))
	assert(bool(game.habitat_returned_species.get(best_id, false)))
	assert(best_id not in game.pending_habitat_species)
	game.play_active = false
	game._clear_greenhouse_plants()

	# There is no habitat-harvest completion route anymore.
	assert(game.mystery_route_assignments.size() == 2)

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

	game._save()
	var saved_assignments: Dictionary = game.mystery_route_assignments.duplicate(true)
	game.mystery_route_assignments.clear()
	game._load_save()
	assert(game.mystery_route_assignments == saved_assignments)
	assert(game.rain_completion_count == 0 and game.best_100_achieved)
	print("MYSTERY_ROUTES_SMOKE_OK routes=research+best100 rain_route=retired habitat_unknown_spawn=retired")
	get_tree().quit()
