extends Node3D

## Zona de prueba misión 2: máquina con caja de carga; aspecto según BuildState.tool_type.

const BuildStateScript := preload("res://scripts/build_state.gd")
const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")
const UIStyle := preload("res://scripts/ui_style_helper.gd")

const DEBUG_LOGS := false

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _blocks_progress_label: Label = %BlocksProgressLabel
@onready var _start_button: Button = %StartTestButton
@onready var _continue_button: Button = %ContinueButton
@onready var _back_button: Button = %BackToWorkshopButton

var _build_state: BuildStateScript
var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var test_running: bool = false
var test_completed: bool = false
var _blocks_delivered: int = 0


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_setup_camera()
	_apply_machine_from_build_state()
	_reset_mission_visuals()
	_apply_localized_text()
	_loc.locale_changed.connect(_apply_localized_text)
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_apply_button_feedback(_start_button)
	_apply_button_feedback(_continue_button)
	_apply_button_feedback(_back_button)
	UIStyle.apply_primary_button(_start_button)
	UIStyle.apply_primary_button(_continue_button)
	UIStyle.apply_primary_button(_back_button)


func _blocks_progress_text(count: int) -> String:
	return _loc.t("TEST_BLOCKS_PROGRESS").replace("{count}", str(count))


func _apply_localized_text() -> void:
	var title := get_node_or_null("CanvasLayer/UI/TitleLabel") as Label
	if title != null:
		title.text = _loc.t("TEST_TITLE")
	_start_button.text = _loc.t("TEST_BUTTON_START")
	_back_button.text = _loc.t("TEST_BUTTON_BACK")
	_continue_button.text = _loc.t("TEST_BUTTON_CONTINUE")
	if test_completed:
		_igor_label.text = _loc.t("MISSION_2_TEST_SUCCESS")
	elif not test_running:
		_igor_label.text = _loc.t("MISSION_2_TEST_INITIAL")
	_blocks_progress_label.text = _blocks_progress_text(_blocks_delivered)
	var hint := get_node_or_null("CanvasLayer/UI/HintPanel/HintLabel") as Label
	if hint != null:
		hint.text = _loc.t("TEST_BLOCKS_HINT")
	var sign_label := get_node_or_null("SuccessSign") as Label3D
	if sign_label != null:
		sign_label.text = _loc.t("TEST_SIGN_BLOCKS_READY")
	var machine_label := get_node_or_null("Machine/MachineNameLabel") as Label3D
	if machine_label != null:
		machine_label.text = _loc.t("TEST_MACHINE_LABEL")


func _reset_mission_visuals() -> void:
	$ClearedPath.visible = false
	$SuccessSign.visible = false
	$RewardGear.visible = false
	$RewardGear.scale = Vector3.ONE
	_start_button.visible = true
	_start_button.disabled = false
	_continue_button.visible = false
	_blocks_delivered = 0
	_blocks_progress_label.text = _blocks_progress_text(0)


func _apply_machine_from_build_state() -> void:
	if DEBUG_LOGS:
		print("TestZoneBlocks BuildState tool_type: ", _build_state.tool_type)
	var machine := $Machine as Node3D
	var use_fallback: bool = not _build_state.is_complete()

	var show_base: bool = use_fallback or _build_state.has_base
	var show_wheels: bool = use_fallback or _build_state.has_wheels
	var show_motor: bool = use_fallback or _build_state.has_motor
	var show_battery: bool = use_fallback or _build_state.has_battery
	var show_core: bool = use_fallback or _build_state.is_complete()

	var tt: String = _build_state.tool_type
	var show_cargo: bool = tt == "cargo_bed"
	var show_shovel: bool = tt == "shovel"
	if not show_cargo and not show_shovel:
		if DEBUG_LOGS:
			print("TestZoneBlocks: unexpected tool_type '", tt, "', falling back to shovel visual.")
		show_shovel = true
		show_cargo = false

	machine.get_node("Body").visible = show_base
	machine.get_node("Wheels").visible = show_wheels
	machine.get_node("Motor").visible = show_motor
	machine.get_node("Battery").visible = show_battery
	machine.get_node("Shovel").visible = show_shovel
	machine.get_node("CargoBed").visible = show_cargo
	machine.get_node("MotorlingCore").visible = show_core
	machine.get_node("MachineNameLabel").visible = show_base


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 50.0
	cam.position = Vector3(4.52, 3.2, 6.12)
	cam.look_at(Vector3(0.0, 0.17, 0.52), Vector3.UP)


func _go_to_workshop() -> void:
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _go_to_community() -> void:
	_scene_transition.fade_to_scene("res://scenes/community.tscn")


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)


func _on_back_pressed() -> void:
	_go_to_workshop()


func _on_continue_pressed() -> void:
	_go_to_community()


func _on_start_pressed() -> void:
	if test_running or test_completed:
		return
	test_running = true
	if DEBUG_LOGS:
		print("TestZoneBlocks started")
	_start_button.disabled = true
	_igor_label.text = _loc.t("MISSION_2_TEST_START")
	await _run_carry_demo()
	test_running = false
	test_completed = true
	if DEBUG_LOGS:
		print("TestZoneBlocks completed")
	_mission_state.mark_test_completed()
	$ClearedPath.visible = true
	$SuccessSign.visible = true
	$RewardGear.visible = true
	_igor_label.text = _loc.t("MISSION_2_TEST_SUCCESS")
	_start_button.visible = false
	_continue_button.visible = true
	_play_reward_pulse()


func _run_carry_demo() -> void:
	var machine := $Machine as Node3D
	var bed := machine.get_node("CargoBed") as Node3D
	var delivered_root := $DeliveredBlocksRoot as Node3D
	var stacks: Array = [$DeliveryZone/Stack1, $DeliveryZone/Stack2, $DeliveryZone/Stack3]
	var blocks: Array = [$PickupArea/Blocks/Block1, $PickupArea/Blocks/Block2, $PickupArea/Blocks/Block3]
	var delivery_anchor_z: float = ($DeliveryZone as Node3D).global_position.z

	for i in range(blocks.size()):
		var block: Node3D = blocks[i]
		var stack: Node3D = stacks[i]
		var approach_z: float = block.global_position.z - 0.5
		await _tween_machine_z(machine, approach_z, 0.88)

		block.reparent(bed, true)
		var tw_pickup := create_tween()
		tw_pickup.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_pickup.tween_property(block, "position", Vector3(0.0, 0.12, 0.02), 0.5)
		await tw_pickup.finished

		var at_drop_z: float = delivery_anchor_z - 0.72
		await _tween_machine_z(machine, at_drop_z, 1.02)

		var end_pos: Vector3 = stack.global_position + Vector3(0.0, 0.09, 0.0)
		block.reparent(delivered_root, true)
		var tw_drop := create_tween()
		tw_drop.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_drop.tween_property(block, "global_position", end_pos, 0.45)
		await tw_drop.finished

		_blocks_delivered = i + 1
		_blocks_progress_label.text = _blocks_progress_text(_blocks_delivered)

		if i == 0:
			_igor_label.text = _loc.t("TEST_BLOCKS_ONE_DELIVERED")
			await get_tree().create_timer(0.75).timeout
		elif i == 1:
			_igor_label.text = _loc.t("TEST_BLOCKS_TWO_DELIVERED")
			await get_tree().create_timer(0.75).timeout

	_igor_label.text = _loc.t("TEST_BLOCKS_ALL_DELIVERED")
	await get_tree().create_timer(0.85).timeout

	var rest_z: float = delivery_anchor_z - 0.35
	await _tween_machine_z(machine, rest_z, 0.75)


func _tween_machine_z(machine: Node3D, target_z: float, duration: float) -> void:
	var dest := Vector3(machine.position.x, machine.position.y, target_z)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(machine, "position", dest, duration)
	await tw.finished


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
