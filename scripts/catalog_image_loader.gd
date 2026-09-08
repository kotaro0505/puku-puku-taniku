extends Node

const EXTERNAL_ROOT := "res://assets/catalog/"
const MAX_PARALLEL_REQUESTS := 4
const MAX_TEXTURE_CACHE_ITEMS := 48

var placeholder_texture: ImageTexture
var network_request_count := 0
var cache_hit_count := 0
var request_count_by_path: Dictionary = {}

var _texture_cache: Dictionary = {}
var _last_used: Dictionary = {}
var _pending_callbacks: Dictionary = {}
var _high_priority_queue: Array[String] = []
var _prefetch_queue: Array[String] = []
var _active_requests := 0
var _access_serial := 0

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
			_prefetch_queue.erase(path)
			if path not in _high_priority_queue:
				_high_priority_queue.push_front(path)
		return
	_pending_callbacks[path] = [callback]
	if high_priority:
		_high_priority_queue.append(path)
	else:
		_prefetch_queue.append(path)
	_pump_queue()

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
		if not _pending_callbacks.has(path):
			continue
		_start_request(path)

func _start_request(path: String) -> void:
	var request := HTTPRequest.new()
	request.use_threads = false
	add_child(request)
	request.request_completed.connect(_on_request_completed.bind(path, request), CONNECT_ONE_SHOT)
	_active_requests += 1
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
	var callbacks: Array = _pending_callbacks.get(path, [])
	_pending_callbacks.erase(path)
	for callback_value in callbacks:
		var callback: Callable = callback_value
		if callback.is_valid():
			callback.call_deferred(texture)
	_pump_queue()

func _external_url(path: String) -> String:
	var relative_path := path.trim_prefix("res://")
	if not OS.has_feature("web"):
		return relative_path
	var script := "new URL(%s, window.location.href).href" % JSON.stringify(relative_path)
	return str(JavaScriptBridge.eval(script))

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
