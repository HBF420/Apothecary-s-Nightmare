extends Node3D

signal state_changed
signal boil_ready

enum Fuel { COLD, LOGS, FIRE, EMBERS }
enum Placement { REST, HELD, HEARTH, HOOK }

@export_range(0.1, 600.0) var burn_seconds := 10.0
@export_range(0.1, 600.0) var ember_seconds := 60.0
@export_range(0.1, 600.0) var boil_seconds := 4.0

@onready var pot: Node3D = $Pot
@onready var mount: Node3D = $Forge.find_child("PotMount", true, false)
@onready var cook_mount: Node3D = $Forge.find_child("PotCookMount", true, false)
@onready var logs: Node3D = $Forge.find_child("HearthLogs", true, false)
@onready var fire: Node3D = $Forge.find_child("HearthFire", true, false)
@onready var embers: Node3D = $Forge.find_child("HearthEmbers", true, false)
@onready var contents: Node3D = pot.find_child("PotContents", true, false)
@onready var liquid_surface: MeshInstance3D = contents.get_child(0)
@onready var bubbles: Node3D = pot.find_child("PotBubbles", true, false)
@onready var handle_pivot: Node3D = pot.find_child("PotHandlePivot", true, false)
@onready var animator: AnimationPlayer = pot.find_child("AnimationPlayer", true, false)

var fuel := Fuel.COLD
var placement := Placement.REST
var doses := 0
var remedy_id: StringName
var is_boiling := false
var _fuel_time := 0.0
var _heat_time := 0.0
var _flame_clock := 0.0
var _raised_handle_angle := 0.0
var _remedy_color := Color.WHITE
var _remedy_material := StandardMaterial3D.new()


func _ready() -> void:
	pot.global_transform = mount.global_transform
	_raised_handle_angle = handle_pivot.rotation.x
	logs.scale = Vector3.ONE
	_remedy_material.roughness = 0.24
	_sync_visuals()

func start_ready() -> void:
	fuel = Fuel.EMBERS
	doses = 2
	is_boiling = true
	placement = Placement.HEARTH
	pot.global_transform = cook_mount.global_transform
	_sync_visuals()


func take_pot(hand: Node3D) -> bool:
	if placement == Placement.HELD or not is_instance_valid(hand):
		return false
	placement = Placement.HELD
	pot.reparent(hand, true)
	pot.transform = Transform3D(Basis.IDENTITY.scaled(mount.scale), Vector3(0, -0.5, 0))
	_reset_heat()
	_sync_visuals()
	return true


func place_pot_on_ashes(held: Node3D) -> bool:
	if held != pot or fuel != Fuel.EMBERS:
		return false
	if placement != Placement.HELD and placement != Placement.HOOK and placement != Placement.REST:
		return false
	_place(Placement.HEARTH, cook_mount)
	return true


func hang_pot(held: Node3D) -> bool:
	if held != pot or placement != Placement.HELD:
		return false
	_place(Placement.HOOK, mount)
	return true


func _place(target: Placement, marker: Node3D) -> void:
	pot.reparent(self, true)
	pot.global_transform = marker.global_transform
	placement = target
	_sync_visuals()


func add_logs() -> bool:
	if placement == Placement.HEARTH or fuel != Fuel.COLD:
		return false
	fuel = Fuel.LOGS
	_sync_visuals()
	return true


func light_logs() -> bool:
	if placement == Placement.HEARTH or fuel != Fuel.LOGS:
		return false
	fuel = Fuel.FIRE
	_fuel_time = burn_seconds
	_sync_visuals()
	return true


func fill_pot() -> bool:
	if placement != Placement.HEARTH or fuel != Fuel.EMBERS or doses != 0:
		return false
	doses = 2
	_sync_visuals()
	return true


func brew_remedy(recipe: StringName, tint: Color) -> bool:
	if not is_boiling or doses != 2 or remedy_id != &"" or recipe == &"":
		return false
	remedy_id = recipe
	_remedy_color = tint
	_remedy_material.albedo_color = tint
	_sync_visuals()
	return true


func draw_vial(vial_is_empty: bool) -> Dictionary:
	if not vial_is_empty or placement != Placement.HEARTH or doses == 0 or remedy_id == &"":
		return {}
	var vial := {"remedy_id": remedy_id, "color": _remedy_color}
	doses -= 1
	if doses == 0:
		remedy_id = &""
		_reset_heat()
	_sync_visuals()
	return vial


func _process(delta: float) -> void:
	var heat_delta := delta if fuel == Fuel.EMBERS else 0.0
	if fuel == Fuel.FIRE:
		_fuel_time -= delta
		if _fuel_time <= 0.0:
			fuel = Fuel.EMBERS
			_sync_visuals()
	if fuel == Fuel.FIRE:
		_flame_clock += delta
		var pulse := sin(_flame_clock * 14.0) * 0.07 + sin(_flame_clock * 23.0) * 0.04
		fire.scale = Vector3(1.0 - pulse * 0.25, 1.0 + pulse, 1.0)
		$FireGlow.light_energy = 0.7 + pulse
	if fuel == Fuel.EMBERS and placement == Placement.HEARTH and doses > 0 and not is_boiling:
		_heat_time += heat_delta
		if _heat_time >= boil_seconds:
			is_boiling = true
			_sync_visuals()
			boil_ready.emit()


func _reset_heat() -> void:
	is_boiling = false
	_heat_time = 0.0


func on_sleep() -> void:
	if fuel == Fuel.EMBERS:
		fuel = Fuel.COLD
		_reset_heat()
		_sync_visuals()


func _sync_visuals() -> void:
	var handle_up := placement == Placement.HOOK or placement == Placement.REST or placement == Placement.HELD
	handle_pivot.rotation.x = _raised_handle_angle if handle_up else _raised_handle_angle + deg_to_rad(80.0)
	logs.visible = fuel == Fuel.LOGS or fuel == Fuel.FIRE
	fire.visible = fuel == Fuel.FIRE
	embers.visible = fuel == Fuel.EMBERS
	$FireGlow.visible = fire.visible or embers.visible
	$FireGlow.light_energy = 0.7 if fire.visible else 0.22
	contents.visible = doses > 0
	contents.position.y = -0.168 if doses == 1 else 0.0
	contents.scale = Vector3(1.075, 1.0, 1.075) if doses == 1 else Vector3.ONE
	liquid_surface.material_override = _remedy_material if remedy_id != &"" else null
	bubbles.visible = is_boiling
	for bubble in bubbles.get_children():
		if bubble is MeshInstance3D:
			bubble.material_override = liquid_surface.material_override
	if animator and not animator.get_animation_list().is_empty():
		if is_boiling and not animator.is_playing():
			var clip: StringName = animator.get_animation_list()[0]
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			animator.play(clip)
		elif not is_boiling:
			animator.stop()
	state_changed.emit()
