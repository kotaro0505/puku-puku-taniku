class_name HabitatNotificationService
extends Node

signal native_ready

const PLUGIN_SINGLETON_NAME := "NotificationSchedulerPlugin"
const CHANNEL_ID := "panda_beacon"
const CHANNEL_NAME := "パンダビーコン"
const CHANNEL_DESCRIPTION := "原生地の株が30cmに到達したお知らせ"

var _plugin: Object
var _initialized := false
var _permission_requested := false
var _scheduled: Dictionary = {}


func _ready() -> void:
	_initialize_native()


func native_available() -> bool:
	return _plugin != null


func native_initialized() -> bool:
	return _initialized


func notification_id_for(individual_id: String) -> int:
	# Stable across launches, positive, and safely inside signed 32-bit range.
	return 10000 + (absi(individual_id.hash()) % 2000000000)


func schedule_at(individual_id: String, trigger_unix: float, title: String, content: String, allow_native := true) -> bool:
	if individual_id.is_empty() or trigger_unix <= 0.0:
		return false
	var notification_id := notification_id_for(individual_id)
	_scheduled[individual_id] = {
		"notification_id": notification_id,
		"trigger_unix": trigger_unix,
		"title": title,
		"content": content,
		"native_allowed": allow_native
	}
	if not allow_native or not _initialized:
		return false
	return _schedule_native(individual_id)


func cancel(individual_id: String) -> void:
	var notification_id := notification_id_for(individual_id)
	_scheduled.erase(individual_id)
	if _initialized and _plugin != null:
		_plugin.cancel(notification_id)


func cancel_all(individual_ids: Array) -> void:
	for individual_id_value in individual_ids:
		cancel(str(individual_id_value))


func request_permissions() -> void:
	_permission_requested = true
	if not _initialized or _plugin == null:
		return
	if _plugin.has_method("has_post_notifications_permission") and not bool(_plugin.has_post_notifications_permission()):
		_plugin.request_post_notifications_permission()
	if OS.has_feature("android") and _plugin.has_method("has_schedule_exact_alarm_permission") and not bool(_plugin.has_schedule_exact_alarm_permission()):
		_plugin.request_schedule_exact_alarm_permission()


func scheduled_snapshot() -> Dictionary:
	return _scheduled.duplicate(true)


func _initialize_native() -> void:
	if not (OS.has_feature("ios") or OS.has_feature("android")):
		return
	if not Engine.has_singleton(PLUGIN_SINGLETON_NAME):
		push_warning("Panda Beacon local-notification plugin is unavailable on this build.")
		return
	_plugin = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
	if _plugin.has_signal("initialization_completed"):
		_plugin.connect("initialization_completed", _on_initialization_completed)
	if _plugin.has_signal("post_notifications_permission_granted"):
		_plugin.connect("post_notifications_permission_granted", _on_notification_permission_granted)
	if _plugin.has_signal("schedule_exact_alarm_permission_granted"):
		_plugin.connect("schedule_exact_alarm_permission_granted", _on_notification_permission_granted)
	_plugin.initialize()


func _on_initialization_completed() -> void:
	_initialized = true
	if _plugin.has_method("create_notification_channel"):
		_plugin.create_notification_channel({
			"channel_id": CHANNEL_ID,
			"channel_name": CHANNEL_NAME,
			"channel_description": CHANNEL_DESCRIPTION,
			"channel_importance": 4,
			"badge_enabled": false
		})
	if _permission_requested:
		request_permissions()
	for individual_id_value in _scheduled.keys():
		_schedule_native(str(individual_id_value))
	native_ready.emit()


func _on_notification_permission_granted(_permission_name: String) -> void:
	# A first-time install can reach schedule_at() before the operating-system
	# permission sheet resolves. Retry every still-valid beacon reservation as
	# soon as permission is granted; _schedule_native() cancels/replaces by ID.
	for individual_id_value in _scheduled.keys():
		_schedule_native(str(individual_id_value))


func _schedule_native(individual_id: String) -> bool:
	if not _initialized or _plugin == null or not _scheduled.has(individual_id):
		return false
	var scheduled: Dictionary = _scheduled[individual_id]
	if not bool(scheduled.get("native_allowed", true)):
		return false
	var delay := ceili(float(scheduled.get("trigger_unix", 0.0)) - Time.get_unix_time_from_system())
	var notification_id := int(scheduled.get("notification_id", notification_id_for(individual_id)))
	_plugin.cancel(notification_id)
	if delay <= 0:
		return false
	var result = _plugin.schedule({
		"notification_id": notification_id,
		"channel_id": CHANNEL_ID,
		"title": str(scheduled.get("title", "")),
		"content": str(scheduled.get("content", "")),
		"small_icon_name": "ic_default_notification",
		"delay": delay,
		"custom_data": {"habitat_individual_id": individual_id}
	})
	return int(result) == OK
