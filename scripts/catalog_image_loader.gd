extends Node

const EXTERNAL_ROOT := "res://assets/catalog/"
const MAX_PARALLEL_REQUESTS := 4
const MAX_TEXTURE_CACHE_ITEMS := 48
const CACHE_VERSION_BY_PREFIX := {
	"assets/catalog/glow/": "glow-20260915-2",
	"assets/catalog/hybrid/": "hybrid-20261002-2",
	"assets/catalog/fusion_tier1/": "fusion-tier1-20261002-2",
	"assets/catalog/fusion_tier2/": "fusion-tier2-20261007-3",
	"assets/catalog/fusion_tier3/": "fusion-tier3-20261006-1",
}

var placeholder_texture: ImageTexture
var network_request_count := 0
var cache_hit_count := 0
var request_count_by_path: Dictionary = {}

var _texture_cache: Dictionary = {}
var _last_used: Dictionary = {}
var _pending_callbacks: Dictionary = {}
var _request_high_priority: Dictionary = {}
var _active_request_paths: Dictionary = {}
var _high_priority_queue: Array[String] = []
var _prefetch_queue: Array[String] = []
var _decode_queue: Array[Dictionary] = []
var _decode_pump_running := false
var _active_requests := 0
var _access_serial := 0
var decode_count := 0
var last_decode_duration_msec := 0
var max_decode_duration_msec := 0
var total_decode_duration_msec := 0

func _ready() -> void:
	placeholder_texture = _build_placeholder_texture()

func is_external_path(path: String) -> bool:
	return OS.has_feature("web") and path.begins_with(EXTERNAL_ROOT)

func get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not is_external_path(path):
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	if _texture_cache.has(path):
		_touch(path)
		return _texture_cache[path] as Texture2D
	return placeholder_texture

func is_cached(path: String) -> bool:
	return _texture_cache.has(path)

func request_texture(path: String, callback: Callable, high_priority := true) -> void:
	if path.is_empty():
		callback.call_deferred(null)
		return
	if not is_external_path(path):
		callback.call_deferred(get_texture(path))
		return
	if _texture_cache.has(path):
		cache_hit_count += 1
		_touch(path)
		callback.call_deferred(_texture_cache[path])
		return
	if _pending_callbacks.has(path):
		(_pending_callbacks[path] as Array).append(callback)
		if high_priority:
			_request_high_priority[path] = true
			_prefetch_queue.erase(path)
			if not _active_request_paths.has(path) and path not in _high_priority_queue:
				_high_priority_queue.push_front(path)
		return
	_pending_callbacks[path] = [callback]
	_request_high_priority[path] = high_priority
	if high_priority:
		_high_priority_queue.append(path)
	else:
		_prefetch_queue.append(path)
	_pump_queue()

func cancel_texture_request(path: String, callback: Callable) -> void:
	if path.is_empty() or not _pending_callbacks.has(path):
		return
	var callbacks: Array = _pending_callbacks[path]
	callbacks.erase(callback)
	if not callbacks.is_empty():
		_pending_callbacks[path] = callbacks
		return
	_request_high_priority.erase(path)
	_high_priority_queue.erase(path)
	_prefetch_queue.erase(path)
	for index in range(_decode_queue.size()-1,-1,-1):
		if str(_decode_queue[index].get("path",""))==path:_decode_queue.remove_at(index)
	if _active_request_paths.has(path):
		# Keep an empty slot so a new consumer can join the in-flight request.
		_pending_callbacks[path] = []
	else:
		_pending_callbacks.erase(path)

func clear_texture_cache() -> void:
	_texture_cache.clear()
	_last_used.clear()

func _pump_queue() -> void:
	while _active_requests < MAX_PARALLEL_REQUESTS:
		var path := ""
		if not _high_priority_queue.is_empty():
			path = _high_priority_queue.pop_front()
		elif not _prefetch_queue.is_empty():
			path = _prefetch_queue.pop_front()
		else:
			return
		if not _pending_callbacks.has(path) or _active_request_paths.has(path):
			continue
		_start_request(path)

func _start_request(path: String) -> void:
	var request := HTTPRequest.new()
	request.use_threads = false
	add_child(request)
	request.request_completed.connect(_on_request_completed.bind(path, request), CONNECT_ONE_SHOT)
	_active_requests += 1
	_active_request_paths[path] = true
	network_request_count += 1
	request_count_by_path[path] = int(request_count_by_path.get(path, 0)) + 1
	var error := request.request(_external_url(path))
	if error != OK:
		call_deferred("_finish_request", path, request, PackedByteArray(), 0)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, path: String, request: HTTPRequest) -> void:
	_finish_request(path, request, body if result == HTTPRequest.RESULT_SUCCESS else PackedByteArray(), response_code)

func _finish_request(path: String, request: HTTPRequest, body: PackedByteArray, response_code: int) -> void:
	if is_instance_valid(request):
		request.queue_free()
	_active_requests = maxi(0, _active_requests - 1)
	_active_request_paths.erase(path)
	var callbacks: Array = _pending_callbacks.get(path, [])
	if callbacks.is_empty():
		_pending_callbacks.erase(path)
		_request_high_priority.erase(path)
		_pump_queue()
		return
	_decode_queue.append({"path": path, "body": body, "response_code": response_code, "high_priority": bool(_request_high_priority.get(path, false))})
	# Network concurrency stays at four, but image decoding and GPU texture
	# creation are serialized. Four 2-3 MB responses finishing together used to
	# decode in one main-thread frame and could stall a foreground card gesture.
	_pump_queue()
	if not _decode_pump_running:
		_decode_pump_running = true
		call_deferred("_drain_decode_queue")

func _drain_decode_queue() -> void:
	while not _decode_queue.is_empty():
		var selected_index := 0
		for index in range(_decode_queue.size()):
			if bool(_decode_queue[index].get("high_priority", false)):
				selected_index = index
				break
		var response: Dictionary = _decode_queue.pop_at(selected_index)
		_decode_response(str(response.get("path", "")), response.get("body", PackedByteArray()), int(response.get("response_code", 0)))
		if not _decode_queue.is_empty():
			# Preserve full-resolution images while preventing several expensive PNG
			# decodes from landing in the same rendered frame.
			if DisplayServer.get_name()=="headless":
				await get_tree().process_frame
			else:
				await RenderingServer.frame_post_draw
	_decode_pump_running = false

func _decode_response(path: String, body: PackedByteArray, response_code: int) -> void:
	var callbacks: Array = _pending_callbacks.get(path, [])
	if callbacks.is_empty():
		_pending_callbacks.erase(path)
		_request_high_priority.erase(path)
		return
	var decode_started_msec := Time.get_ticks_msec()
	var texture: Texture2D = placeholder_texture
	if response_code >= 200 and response_code < 300 and not body.is_empty():
		var image := Image.new()
		var error := image.load_png_from_buffer(body)
		if error != OK:
			error = image.load_jpg_from_buffer(body)
		if error == OK:
			texture = ImageTexture.create_from_image(image)
			_texture_cache[path] = texture
			_touch(path)
			_evict_old_textures()
	_pending_callbacks.erase(path)
	_request_high_priority.erase(path)
	for callback_value in callbacks:
		var callback: Callable = callback_value
		if callback.is_valid():
			callback.call_deferred(texture)
	last_decode_duration_msec = Time.get_ticks_msec() - decode_started_msec
	max_decode_duration_msec = maxi(max_decode_duration_msec, last_decode_duration_msec)
	total_decode_duration_msec += last_decode_duration_msec
	decode_count += 1

func _external_url(path: String) -> String:
	var relative_path := _versioned_relative_path(path.trim_prefix("res://"))
	if not OS.has_feature("web"):
		return relative_path
	var script := "new URL(%s, window.location.href).href" % JSON.stringify(relative_path)
	return str(JavaScriptBridge.eval(script))

func _versioned_relative_path(relative_path: String) -> String:
	for prefix_value in CACHE_VERSION_BY_PREFIX:
		var prefix := str(prefix_value)
		if relative_path.begins_with(prefix):
			return "%s?v=%s" % [relative_path, str(CACHE_VERSION_BY_PREFIX[prefix_value])]
	return relative_path

func _touch(path: String) -> void:
	_access_serial += 1
	_last_used[path] = _access_serial

func _evict_old_textures() -> void:
	while _texture_cache.size() > MAX_TEXTURE_CACHE_ITEMS:
		var oldest_path := ""
		var oldest_serial := _access_serial + 1
		for path_value in _texture_cache.keys():
			var path := str(path_value)
			var serial := int(_last_used.get(path, 0))
			if serial < oldest_serial:
				oldest_serial = serial
				oldest_path = path
		if oldest_path.is_empty():
			return
		_texture_cache.erase(oldest_path)
		_last_used.erase(oldest_path)

func _build_placeholder_texture() -> ImageTexture:
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.53)
	for y in range(size):
		for x in range(size):
			var point := Vector2(x, y)
			var alpha := 0.0
			for angle_index in range(8):
				var angle := TAU * float(angle_index) / 8.0
				var leaf_center := center + Vector2(cos(angle), sin(angle)) * 22.0
				var local := (point - leaf_center).rotated(-angle)
				var distance := Vector2(local.x / 21.0, local.y / 10.0).length()
				alpha = maxf(alpha, smoothstep(1.0, 0.72, distance))
			var core_distance := point.distance_to(center) / 18.0
			alpha = maxf(alpha, smoothstep(1.0, 0.68, core_distance))
			if alpha > 0.0:
				image.set_pixel(x, y, Color(0.48, 0.57, 0.43, alpha * 0.48))
	return ImageTexture.create_from_image(image)
