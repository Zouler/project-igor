extends Node3D

## Zona de prueba MVP: la máquina despeja piedras; aspecto según BuildState.

const BuildStateScript := preload("res://scripts/build_state.gd")

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _start_button: Button = %StartTestButton
@onready var _continue_button: Button = %ContinueButton
@onready var _back_button: Button = %BackToWorkshopButton

var _build_state: BuildStateScript
var test_running: bool = false
var test_completed: bool = false


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_setup_camera()
	_apply_machine_from_build_state()
	_reset_mission_visuals()
	_igor_label.text = "Probemos la nueva máquina."
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _reset_mission_visuals() -> void:
	$ClearedPath.visible = false
	$SuccessSign.visible = false
	$RewardGear.visible = false
	$RewardGear.scale = Vector3.ONE
	_start_button.visible = true
	_start_button.disabled = false
	_continue_button.visible = false


func _apply_machine_from_build_state() -> void:
	print("TestZone BuildState complete: ", _build_state.is_complete())
	var machine := $Machine as Node3D
	var use_fallback: bool = not _build_state.is_complete()

	var show_base: bool = use_fallback or _build_state.has_base
	var show_wheels: bool = use_fallback or _build_state.has_wheels
	var show_motor: bool = use_fallback or _build_state.has_motor
	var show_battery: bool = use_fallback or _build_state.has_battery
	var show_shovel: bool = _build_state.tool_type == "shovel"
	var show_core: bool = use_fallback or _build_state.is_complete()

	machine.get_node("Body").visible = show_base
	machine.get_node("Wheels").visible = show_wheels
	machine.get_node("Motor").visible = show_motor
	machine.get_node("Battery").visible = show_battery
	machine.get_node("Shovel").visible = show_shovel
	machine.get_node("MotorlingCore").visible = show_core
	machine.get_node("MachineNameLabel").visible = show_base


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 50.0
	cam.position = Vector3(4.5, 3.2, 5.8)
	cam.look_at(Vector3(0.0, 0.2, 0.6), Vector3.UP)


func _go_to_workshop() -> void:
	get_tree().change_scene_to_file("res://scenes/workshop.tscn")


func _on_back_pressed() -> void:
	_go_to_workshop()


func _on_continue_pressed() -> void:
	_go_to_workshop()


func _on_start_pressed() -> void:
	if test_running or test_completed:
		return
	test_running = true
	print("Test started")
	_start_button.disabled = true
	_igor_label.text = "¡Mira! El motorcito está ayudando."
	await _run_clear_path_demo()
	test_running = false
	test_completed = true
	print("Test completed")
	$ClearedPath.visible = true
	$SuccessSign.visible = true
	$RewardGear.visible = true
	_igor_label.text = "¡Camino despejado! El planeta empieza a despertar."
	_start_button.visible = false
	_continue_button.visible = true
	_play_reward_pulse()


func _run_clear_path_demo() -> void:
	var machine := $Machine as Node3D
	var r1 := $Rocks/Rock1 as Node3D
	var r2 := $Rocks/Rock2 as Node3D
	var r3 := $Rocks/Rock3 as Node3D

	await _tween_machine_z(machine, -0.52, 1.05)
	await _tween_rock_aside(r1)
	await _tween_machine_z(machine, 0.32, 1.05)
	await _tween_rock_aside(r2)
	await _tween_machine_z(machine, 1.02, 1.05)
	await _tween_rock_aside(r3)
	await _tween_machine_z(machine, 1.48, 0.95)


func _tween_machine_z(machine: Node3D, target_z: float, duration: float) -> void:
	var dest := Vector3(machine.position.x, machine.position.y, target_z)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(machine, "position", dest, duration)
	await tw.finished


func _tween_rock_aside(rock: Node3D) -> void:
	var dest := rock.position + Vector3(0.95, 0.0, 0.22)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(rock, "position", dest, 0.52)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(rock, "scale", Vector3(0.15, 0.15, 0.15), 0.35)
	await tw2.finished
	rock.visible = false
	print("Rock cleared: ", rock.name)


func _play_reward_pulse() -> void:
	var rg := $RewardGear as Node3D
	rg.scale = Vector3(0.06, 0.06, 0.06)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(rg, "scale", Vector3.ONE, 0.78)
	await tw.finished
	var gear_disc := $RewardGear/GearDisc as MeshInstance3D
	var mat := gear_disc.get_active_material(0) as StandardMaterial3D
	if mat != null:
		var tw_glow := create_tween().set_loops(3)
		var e0 := mat.emission_energy_multiplier
		tw_glow.tween_property(mat, "emission_energy_multiplier", e0 * 1.45, 0.38)
		tw_glow.tween_property(mat, "emission_energy_multiplier", e0, 0.38)
