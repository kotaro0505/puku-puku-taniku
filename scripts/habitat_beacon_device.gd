class_name HabitatBeaconDevice
extends Node3D

const APPEAR_SECONDS := 0.22
const DISAPPEAR_SECONDS := 0.20
const REST_SCALE := 1.35

var glow: MeshInstance3D
var idle_tween: Tween
var action_tween: Tween


func _ready() -> void:
	name = "PandaBeaconDevice"
	_build_device()


func show_immediately() -> void:
	scale = Vector3.ONE * REST_SCALE
	_start_idle_pulse()


func play_install() -> void:
	_stop_tweens()
	var resting_position := position
	position = resting_position + Vector3(0.0, -0.13, 0.0)
	scale = Vector3.ONE * REST_SCALE * 0.24
	if is_instance_valid(glow):
		glow.scale = Vector3.ONE * 0.45
	action_tween = create_tween().bind_node(self).set_parallel()
	action_tween.tween_property(self, "position", resting_position, APPEAR_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	action_tween.tween_property(self, "scale", Vector3.ONE * REST_SCALE, APPEAR_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(glow):
		action_tween.tween_property(glow, "scale", Vector3.ONE * 1.75, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		action_tween.chain().tween_property(glow, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	action_tween.chain().tween_callback(_start_idle_pulse)


func play_remove() -> void:
	_stop_tweens()
	action_tween = create_tween().bind_node(self).set_parallel()
	action_tween.tween_property(self, "position", position + Vector3(0.0, -0.14, 0.0), DISAPPEAR_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	action_tween.tween_property(self, "scale", Vector3.ONE * REST_SCALE * 0.08, DISAPPEAR_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if is_instance_valid(glow):
		action_tween.tween_property(glow, "scale", Vector3.ONE * 0.18, 0.11)
	action_tween.chain().tween_callback(queue_free)


func _start_idle_pulse() -> void:
	if not is_inside_tree() or not is_instance_valid(glow):
		return
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
	glow.scale = Vector3.ONE * 0.92
	idle_tween = create_tween().bind_node(self).set_loops()
	idle_tween.tween_property(glow, "scale", Vector3.ONE * 1.12, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(glow, "scale", Vector3.ONE * 0.92, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_tweens() -> void:
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
	idle_tween = null
	if action_tween and action_tween.is_valid():
		action_tween.kill()
	action_tween = null


func _build_device() -> void:
	var black := _material(Color("#1f2428"), 0.62, 0.18)
	var white := _material(Color("#ece9df"), 0.48, 0.08)
	var dark_white := _material(Color("#a8afb2"), 0.58, 0.12)
	var light := _material(Color("#88f0df"), 0.28, 0.05, Color("#39e8d2"), 2.4)

	var foot_mesh := CylinderMesh.new()
	foot_mesh.top_radius = 0.105
	foot_mesh.bottom_radius = 0.125
	foot_mesh.height = 0.055
	foot_mesh.radial_segments = 16
	_add_mesh(foot_mesh, black, Vector3(0.0, 0.028, 0.0))

	var stake_mesh := CylinderMesh.new()
	stake_mesh.top_radius = 0.025
	stake_mesh.bottom_radius = 0.034
	stake_mesh.height = 0.27
	stake_mesh.radial_segments = 12
	_add_mesh(stake_mesh, dark_white, Vector3(0.0, 0.18, 0.0))

	var terminal_mesh := BoxMesh.new()
	terminal_mesh.size = Vector3(0.19, 0.15, 0.105)
	_add_mesh(terminal_mesh, white, Vector3(0.0, 0.335, 0.0))

	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(0.202, 0.047, 0.112)
	_add_mesh(band_mesh, black, Vector3(0.0, 0.337, 0.0))

	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.011
	antenna_mesh.bottom_radius = 0.014
	antenna_mesh.height = 0.14
	antenna_mesh.radial_segments = 10
	_add_mesh(antenna_mesh, black, Vector3(0.0, 0.48, 0.0))

	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.035
	glow_mesh.height = 0.07
	glow_mesh.radial_segments = 12
	glow_mesh.rings = 6
	glow = _add_mesh(glow_mesh, light, Vector3(0.0, 0.565, 0.0))
	glow.name = "BeaconGlow"


func _add_mesh(mesh: PrimitiveMesh, material: StandardMaterial3D, local_position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = local_position
	add_child(instance)
	return instance


func _material(color: Color, roughness: float, metallic: float, emission := Color.TRANSPARENT, emission_energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	# Plant sprites are transparent billboards rendered without depth testing.
	# Keep the independent instrument readable even after the monitored rosette
	# grows around it.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = 10
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material
