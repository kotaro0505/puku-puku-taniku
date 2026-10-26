extends Node

const EndlessClass = preload("res://scripts/endless_greenhouse_experiment.gd")
const BuildProfileClass = preload("res://scripts/build_profile.gd")

func _ready() -> void:
	assert(not OS.has_feature("web"))
	assert(EndlessClass.DEFAULT_ENABLED)
	assert(EndlessClass.requested_by_runtime())
	assert(ProjectSettings.get_setting("application/config/name") == "ぷくぷく！たにくらいふ")
	assert(ProjectSettings.get_setting("application/config/icon") == "res://assets/ios/app-icon-1024.png")
	assert(ProjectSettings.get_setting("application/config/version") == "1.0.0")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility")
	assert(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"))
	var export_presets_source:=FileAccess.get_file_as_string("res://export_presets.cfg")
	assert(export_presets_source.contains('name="iOS"'))
	assert(export_presets_source.contains('custom_features="puku_app_store_release"'))
	assert(export_presets_source.contains('application/bundle_identifier="com.ohanayanouen.pukupukutaniku"'))
	assert(export_presets_source.contains('name="iOS Development"'))
	assert(export_presets_source.contains('custom_features="puku_development,puku_ios_test_ads"'))
	assert(export_presets_source.contains('application/bundle_identifier="com.ohanayanouen.pukupukutaniku.dev"'))
	assert(export_presets_source.count("privacy/file_timestamp_access_reasons=2") == 2)
	assert(export_presets_source.count("privacy/system_boot_time_access_reasons=1") == 2)
	assert(export_presets_source.count("privacy/disk_space_access_reasons=1") == 2)
	assert(export_presets_source.count("privacy/user_defaults_access_reasons=4") == 2)
	assert(export_presets_source.count("privacy/tracking_enabled=false") == 2)
	var release_profile:=BuildProfileClass.evaluate_feature_set({"puku_app_store_release":true,"puku_development":true,"puku_rewarded_ad_stub":true,"puku_ios_test_ads":true},true,true)
	assert(release_profile.app_store_release)
	assert(not release_profile.development_tools and not release_profile.rewarded_ad_stub and not release_profile.ios_test_ads)
	assert((release_profile.errors as Array).size() == 3)
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.gdip"))
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.debug.xcframework/ios-arm64/SharePlugin.a"))
	assert(FileAccess.file_exists("res://ios/plugins/SharePlugin.release.xcframework/ios-arm64/SharePlugin.a"))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/SharePlugin=true"))
	var share_plugin_descriptor:=FileAccess.get_file_as_string("res://ios/plugins/SharePlugin.gdip")
	assert(share_plugin_descriptor.contains('name="SharePlugin"'))
	assert(share_plugin_descriptor.contains('initialization="share_plugin_init"'))
	assert(share_plugin_descriptor.contains('system=["Foundation.framework", "AudioToolbox.framework", "UIKit.framework"]'))
	var share_plugin_binary:=FileAccess.get_file_as_bytes("res://ios/plugins/SharePlugin.release.xcframework/ios-arm64/SharePlugin.a")
	for symbol in ["SharePlugin::share", "share_plugin_init", "share_completed", "share_canceled", "share_failed", "UIActivityViewController"]:
		assert(_binary_contains_ascii(share_plugin_binary,symbol),symbol)
	assert(not _binary_contains_ascii(share_plugin_binary,"share_image") and not _binary_contains_ascii(share_plugin_binary,"share_file"))
	assert(FileAccess.file_exists("res://ios/plugins/NotificationSchedulerPlugin.gdip"))
	assert(FileAccess.file_exists("res://ios/plugins/NotificationSchedulerPlugin.release.xcframework/ios-arm64/NotificationSchedulerPlugin.a"))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/NotificationSchedulerPlugin=true"))
	var notification_plugin_binary:=FileAccess.get_file_as_bytes("res://ios/plugins/NotificationSchedulerPlugin.release.xcframework/ios-arm64/NotificationSchedulerPlugin.a")
	assert(_binary_contains_ascii(notification_plugin_binary,"NSUserDefaults"))
	assert(FileAccess.file_exists("res://addons/AdmobPlugin/plugin.cfg"))
	assert(FileAccess.file_exists("res://addons/AdmobPlugin/LICENSE.txt"))
	assert(FileAccess.file_exists("res://ios/plugins/AdmobPlugin.gdip"))
	assert(FileAccess.file_exists("res://ios/plugins/AdmobPlugin.release.xcframework/ios-arm64/AdmobPlugin.a"))
	assert(export_presets_source.count("plugins/AdmobPlugin=true") == 2)
	assert(FileAccess.get_file_as_string("res://project.godot").contains("res://addons/AdmobPlugin/plugin.cfg"))
	var admob_descriptor:=FileAccess.get_file_as_string("res://ios/plugins/AdmobPlugin.gdip")
	assert(admob_descriptor.contains('name="AdmobPlugin"'))
	var admob_binary:=FileAccess.get_file_as_bytes("res://ios/plugins/AdmobPlugin.release.xcframework/ios-arm64/AdmobPlugin.a")
	var ump_bridge_tokens:=PackedStringArray([
		"privacy_options_form_dismissed",
		"present_privacy_options_form",
		"get_privacy_options_requirement_status",
		"can_request_ads",
	])
	var ump_bridge_token_count:=0
	for token in ump_bridge_tokens:
		if _binary_contains_ascii(admob_binary,token):ump_bridge_token_count+=1
	# The checked-in upstream binary intentionally remains untouched. Codemagic
	# replaces it with an exact-Godot-version build; accept either the untouched
	# baseline or the complete bridge, but never a partial native contract.
	assert(ump_bridge_token_count in [0,ump_bridge_tokens.size()])
	assert(FileAccess.file_exists("res://scripts/ci/build_admob_plugin.sh"))
	assert(FileAccess.file_exists("res://scripts/ci/patch_admob_ump_native.py"))
	var admob_build_source:=FileAccess.get_file_as_string("res://scripts/ci/build_admob_plugin.sh")
	var admob_patch_source:=FileAccess.get_file_as_string("res://scripts/ci/patch_admob_ump_native.py")
	assert(admob_build_source.contains("4b4ddceab0be81f0dcb12a6313038dba6cf9eacf"))
	assert(admob_build_source.contains('GOOGLE_MOBILE_ADS_VERSION:-12.14.0'))
	assert(admob_build_source.contains('./script/run_gradle_task.sh copyiOSBuildArtifacts'))
	assert(admob_build_source.contains('BUILT_FRAMEWORKS="$PLUGIN_SOURCE/ios/build/framework"'))
	assert(admob_build_source.contains('BUILT_PLUGIN="$PLUGIN_SOURCE/common/build/plugin/ios/ios/plugins"'))
	assert(not admob_build_source.contains('BUILT_PLUGIN="$PLUGIN_SOURCE/common/build/plugin/ios/plugins"'))
	assert(admob_build_source.contains('["xcrun", "lipo", "-archs", str(library_path)]'))
	assert(admob_build_source.contains("ADMOB_BUILD_LAYOUT_OK"))
	assert(admob_build_source.contains("ADMOB_UMP_NATIVE_BUILT"))
	assert(admob_patch_source.contains("UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus"))
	assert(admob_patch_source.contains("UMPConsentInformation.sharedInstance.canRequestAds"))
	assert(admob_patch_source.contains("presentPrivacyOptionsFormFromViewController"))
	var admob_export_source:=FileAccess.get_file_as_string("res://addons/AdmobPlugin/AdmobPlugin.gd")
	assert(admob_export_source.contains("GoogleMobileAds") and admob_export_source.contains('version": "12.14.0"'))
	assert(admob_export_source.contains("NSAllowsArbitraryLoadsForMedia"))
	assert(admob_export_source.contains("NSAllowsArbitraryLoadsInWebContent"))
	assert(not admob_export_source.contains("<key>NSAllowsArbitraryLoads</key>"))
	var storekit_plugin_path:="res://ios/plugins/godot-storekit2/godot-storekit2.gdip"
	var storekit_plugin_present:=FileAccess.file_exists(storekit_plugin_path)
	# The exact Godot-version XCFramework is generated on the macOS CI runner;
	# local Windows source checks therefore accept the reproducible build script.
	assert(storekit_plugin_present or FileAccess.file_exists("res://scripts/ci/build_storekit2_plugin.sh"))
	if storekit_plugin_present:assert(FileAccess.get_file_as_string(storekit_plugin_path).contains("StoreKit.framework"))
	assert(FileAccess.get_file_as_string("res://export_presets.cfg").contains("plugins/godot-storekit2=true"))
	assert(export_presets_source.contains('application/min_ios_version="15.6"'))
	assert(not export_presets_source.contains('application/min_ios_version="15.0"'))
	var storekit_build_source:=FileAccess.get_file_as_string("res://scripts/ci/build_storekit2_plugin.sh")
	assert(storekit_build_source.contains('IOS_MIN_VERSION="${IOS_MIN_VERSION:-15.6}"'))
	assert(storekit_build_source.contains('STOREKIT2_COMPAT_REVISION="${STOREKIT2_COMPAT_REVISION:-compat2}"'))
	assert(storekit_build_source.contains('storekit2-${STOREKIT2_VERSION}-godot-${GODOT_VERSION}-ios${IOS_MIN_VERSION}-${STOREKIT2_COMPAT_REVISION}'))
	assert(storekit_build_source.contains('#include "core/variant/type_info.h"'))
	assert(storekit_build_source.contains("VARIANT_ENUM_CAST"))
	assert(storekit_build_source.contains("TYPE_INFO_INCLUDE_COUNT"))
	assert(storekit_build_source.contains("VARIANT_ENUM_CAST_USE_COUNT"))
	assert(storekit_build_source.contains("STOREKIT2_BUILD_DIAGNOSTICS"))
	assert(storekit_build_source.contains("STOREKIT2_SOURCE_HEAD"))
	assert(storekit_build_source.contains("STOREKIT2_PATCHED_HEADER_BEGIN"))
	assert(storekit_build_source.contains("STOREKIT2_GODOT_COMPAT_PATCH_OK"))
	assert(storekit_build_source.contains("STOREKIT2_DEPLOYMENT_TARGET_OK"))
	assert(not storekit_build_source.contains("IPHONEOS_DEPLOYMENT_TARGET = 15.0"))
	var codemagic_source:=FileAccess.get_file_as_string("res://codemagic.yaml")
	assert(FileAccess.file_exists("res://scripts/ci/validate_ios_export.py"))
	assert(FileAccess.file_exists("res://scripts/ci/validate_ios_export_smoke.py"))
	var ios_export_validator_source:=FileAccess.get_file_as_string("res://scripts/ci/validate_ios_export.py")
	assert(ios_export_validator_source.contains('privacy_path = project.parent / "PrivacyInfo.xcprivacy"'))
	assert(ios_export_validator_source.contains("IOS_EXPORT_VALIDATION_FAILED check="))
	assert(codemagic_source.contains('IOS_MIN_VERSION: "15.6"'))
	assert(codemagic_source.contains('STOREKIT2_COMPAT_REVISION: "compat2"'))
	assert(codemagic_source.contains("storekit2-v0.2-godot-4.7.2-ios15.6-compat2"))
	assert(codemagic_source.contains('ADMOB_NATIVE_COMPAT_REVISION: "ump1"'))
	assert(codemagic_source.contains("admob-v7.0-ump1-godot-4.7.2-gma-12.14.0-ios15.6"))
	assert(codemagic_source.contains("ADMOB_UMP_NATIVE_BRIDGE_OK"))
	assert(codemagic_source.contains('CODEMAGIC_SOURCE_HEAD=$(git rev-parse HEAD)'))
	assert(codemagic_source.contains("git status --short --branch"))
	assert(codemagic_source.contains("git log -1 --oneline"))
	assert(codemagic_source.contains('application/min_ios_version="15.6"'))
	assert(ios_export_validator_source.contains("GODOT_IOS_DEPLOYMENT_TARGET_OK"))
	assert(codemagic_source.contains("GODOT_IOS_EXPORT_COMMAND_FAILED"))
	assert(codemagic_source.contains("python3 scripts/ci/validate_ios_export.py"))
	assert(codemagic_source.contains('PRIVACY_MANIFEST="$(dirname "$CM_BUILD_DIR/$XCODE_PROJECT")/PrivacyInfo.xcprivacy"'))
	assert(not codemagic_source.contains("$IOS_APP_DIR/PrivacyInfo.xcprivacy"))
	assert(codemagic_source.contains("SharePlugin::share") and codemagic_source.contains("UIActivityViewController"))
	assert(codemagic_source.contains("ios-testflight:"))
	assert(codemagic_source.contains("ios-app-store-release:"))
	assert(codemagic_source.contains("ios-development:"))
	assert(codemagic_source.contains('BUILD_PROFILE: "app_store"'))
	assert(codemagic_source.contains('BUILD_PROFILE: "development"'))
	assert(codemagic_source.contains('MOBILE_ADS_MODE: "production"'))
	assert(codemagic_source.contains('MOBILE_ADS_MODE: "test"'))
	assert(codemagic_source.count("xcode: 26.5") == 3)
	assert(codemagic_source.contains("CA92.1"))
	assert(codemagic_source.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
	assert(codemagic_source.contains('testFlightInternalTestingOnly": true'))
	assert(codemagic_source.contains("submit_to_app_store: true"))
	assert(codemagic_source.contains("release_type: MANUAL"))
	assert(FileAccess.get_file_as_string("res://project.godot").contains("res://addons/NotificationSchedulerPlugin/plugin.cfg"))
	var main_source:=FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains("BuildProfileClass.development_tools_enabled()"))
	assert(main_source.contains("BuildProfileClass.rewarded_ad_stub_enabled()"))
	assert(not main_source.contains("const TRIAL_DEV_CONTROLS_ENABLED := true"))
	assert(not main_source.contains("const REWARDED_AD_DEVELOPMENT_STUB_ENABLED := true"))
	assert(main_source.contains('Engine.has_singleton("SharePlugin")'))
	assert(main_source.contains('has_method("share")'))
	assert(main_source.contains('share_plugin.call("share",{'))
	assert(main_source.contains('"file_path":absolute_path'))
	assert(main_source.contains('"mime_type":"image/png"'))
	assert(main_source.contains('_open_native_share_or_fallback(image_path,image_path.get_file(),"arrangement")'))
	assert(main_source.contains("_create_arrangement_share_image"))
	assert(not main_source.contains('has_method("share_image")') and not main_source.contains('has_method("share_file")'))
	assert(not main_source.contains('OS.shell_open(absolute_path)') and not main_source.contains('return "%s: %s"'))
	assert(main_source.contains("navigator.share"))
	assert(main_source.contains("error.name==='AbortError'?'canceled':'failed'"))
	assert(not main_source.contains(".catch(save)"))
	var notification_source:=FileAccess.get_file_as_string("res://scripts/habitat_notification_service.gd")
	assert(notification_source.contains('const PLUGIN_SINGLETON_NAME := "NotificationSchedulerPlugin"'))
	assert(notification_source.contains("Engine.has_singleton(PLUGIN_SINGLETON_NAME)"))
	assert(notification_source.contains("_plugin.schedule("))
	assert(notification_source.contains("_plugin.cancel("))
	assert(notification_source.contains('"post_notifications_permission_granted"'))
	assert(notification_source.contains("_on_notification_permission_granted"))
	var pot_iap_source:=FileAccess.get_file_as_string("res://scripts/pot_unlock_iap_service.gd")
	assert(pot_iap_source.contains('const STOREKIT2_CLASS_NAME := "GodotStoreKit2"'))
	assert(pot_iap_source.contains('ClassDB.instantiate(STOREKIT2_CLASS_NAME)'))
	assert(pot_iap_source.contains('localized_price'))
	assert(pot_iap_source.contains('_store_kit.call("sync")'))
	var rewarded_ad_source:=FileAccess.get_file_as_string("res://scripts/rewarded_ad_service.gd")
	assert(rewarded_ad_source.contains("rewarded_ad_user_earned_reward.connect"))
	assert(rewarded_ad_source.contains("rewarded_ad_dismissed_full_screen_content.connect"))
	assert(rewarded_ad_source.contains("rewarded_ad_failed_to_load.connect"))
	assert(rewarded_ad_source.contains("rewarded_ad_failed_to_show_full_screen_content.connect"))
	assert(rewarded_ad_source.contains("_completion_sent"))
	assert(rewarded_ad_source.contains("personalization_state = AdmobConfigClass.PersonalizationState.DISABLED"))
	assert(rewarded_ad_source.contains("att_enabled = false"))
	assert(rewarded_ad_source.contains("child_directed = AdmobConfigClass.TagForChildDirectedTreatment.UNSPECIFIED"))
	assert(rewarded_ad_source.contains("under_age_of_consent = AdmobConfigClass.TagForUnderAgeOfConsent.UNSPECIFIED"))
	assert(rewarded_ad_source.contains("privacy_options_form_dismissed.connect"))
	assert(rewarded_ad_source.contains("consent_disallows_ads"))
	var admob_wrapper_source:=FileAccess.get_file_as_string("res://addons/AdmobPlugin/Admob.gd")
	assert(admob_wrapper_source.contains("func is_privacy_options_supported()"))
	assert(admob_wrapper_source.contains('has_method("present_privacy_options_form")'))
	assert(admob_wrapper_source.contains('has_method("can_request_ads")'))
	assert(admob_wrapper_source.contains('return "UNKNOWN"'))

	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game._is_endless_greenhouse_enabled())
	# This local/native smoke is a debug build, so the development profile stays
	# usable without legacy URL or habitat-debug switches.
	game.habitat_debug_enabled = false
	assert(game.TRIAL_DEV_CONTROLS_ENABLED)
	assert(game._trial_dev_controls_enabled())
	assert(game._trial_dev_controls_enabled_for_context(false))
	for control_name in ["StoryDevOpen", "ProgressionDevReset", "JellyDevOpen", "TrialDevGachaOpen", "HabitatDevOpen", "OpeningStoryReplay", "CatalogPreviewDevOpen"]:
		assert(game.find_child(control_name, true, false) != null)
	assert(game.story_dev_panel != null and game.habitat_dev_panel != null)
	assert(game.jelly_dev_overlay != null and game.catalog_preview_ui != null)
	game.puku_balance_units=1000;game._adjust_progression_dev_value("puku_coin",0.1);assert(game.puku_balance_units==1100);game._adjust_progression_dev_value("puku_coin",-0.1);assert(game.puku_balance_units==1000)
	assert(game.endless_economy_debug_label!=null)
	assert(game.habitat_texture_mode == "full")
	assert(game.habitat_background_mode == "current")
	game.current_mode = "habitat"
	game._apply_mode()
	assert(game.habitat_environment.background_mode == Environment.BG_SKY)
	assert(game.habitat_environment.sky != null)
	assert(game.habitat_environment.sky.radiance_size == Sky.RADIANCE_SIZE_512)
	assert(game.habitat_panorama_mesh == null)
	assert(game.audio_manager.web_audio_unlocked)
	assert(game.audio_manager._stream_for("bgm", "greenhouse") is AudioStreamOggVorbis)
	assert(game.arrangement_ui!=null and game.pot_catalog.size()>=1)
	assert(bool(game.owned_pots.get("shallow_terracotta",false)))
	# Habitat plants have their own persistent size; greenhouse records do not alter them.
	game.habitat_wild_plants.clear()
	game.habitat_wild_initialized=false
	game.habitat_wild_next_spawn_unix=0
	game.pending_habitat_species.clear()
	# Habitat population now requires the first awakening and its permanent
	# settlement pool; make that prerequisite explicit instead of inheriting a
	# previous smoke test's user:// save state.
	game.habitat_awakened=true
	game.discovered["colorata"]=true
	game.habitat_returned_species["colorata"]=true
	game.habitat_tutorial_complete=true
	game._build_habitat_items(true)
	assert(game.habitat_wild_plants.size()>=game.HabitatWildSystemClass.INITIAL_POPULATION_MIN and game.habitat_wild_plants.size()<=game.HabitatWildSystemClass.INITIAL_POPULATION_MAX)
	var first_wild_item:Dictionary=game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant")[0]
	var first_wild_id:=str(first_wild_item.individual_id)
	var first_wild_scale:Vector3=first_wild_item.node.scale
	game.bests["colorata"] = 100.0
	game._build_habitat_items(true)
	var rebuilt_matches:Array=game.habitat_pickups.filter(func(item):return str(item.kind)=="wild_plant" and str(item.individual_id)==first_wild_id)
	assert(rebuilt_matches.size()==1)
	# A second may tick during this native smoke, so allow only the tiny independent
	# habitat-growth delta. A 100 cm greenhouse record must never resize the plant.
	assert((rebuilt_matches[0].node.scale as Vector3).distance_to(first_wild_scale)<0.03)

	var save_probe_path := "user://ios-native-save-probe.tmp"
	var probe := FileAccess.open(save_probe_path, FileAccess.WRITE)
	assert(probe != null)
	probe.store_string("ios-native-save-ok")
	probe.close()
	assert(FileAccess.get_file_as_string(save_probe_path) == "ios-native-save-ok")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_probe_path))

	print("IOS_NATIVE_SMOKE_OK endless_default_without_flags=true trial_dev_controls_without_debug=true renderer=gl_compatibility texture=full background=current audio=ogg share=plugin+web-fallback notification=scheduled-local save=user")
	game.free()
	await get_tree().process_frame
	get_tree().quit()

func _binary_contains_ascii(bytes:PackedByteArray,text:String)->bool:
	var needle:=text.to_ascii_buffer()
	if needle.is_empty() or bytes.size()<needle.size():return false
	for start in range(bytes.size()-needle.size()+1):
		if bytes[start]!=needle[0]:continue
		var matches:=true
		for offset in range(needle.size()):
			if bytes[start+offset]!=needle[offset]:matches=false;break
		if matches:return true
	return false
