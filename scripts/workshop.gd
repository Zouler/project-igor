extends Node3D

## Escena principal 3D del taller: selección de pieza + click en slot, validación con «Probar».

const BuildStateScript := preload("res://scripts/build_state.gd")
const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")
const UIStyle := preload("res://scripts/ui_style_helper.gd")

const DEBUG_LOGS := false ## Incluye logs [IGOR workshop] de selección; normalmente apagado.

## Coincide con el primer valor de @export_enum en build_slot.gd (BASE).
const SLOT_TYPE_BASE := 0
const SLOT_TYPE_WHEELS := 1
const SLOT_TYPE_MOTOR := 2
const SLOT_TYPE_BATTERY := 3
const SLOT_TYPE_TOOL := 4

const IgorGuideScript := preload("res://scripts/igor_guide.gd")

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _title_label: Label = %TitleLabel
@onready var _mission_label: Label = %MissionLabel
@onready var _test_button: Button = %TestButton
@onready var _reset_button: Button = %ResetButton

var _selected_part: Node = null
var _validation_slots: Array = []
var _igor_guide: RefCounted
var _build_state: BuildStateScript
var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
## Transform local inicial de cada pieza respecto a Parts (para Reiniciar).
var _part_initial_transform: Dictionary = {}
## Evita programar varias veces el cambio a la zona de prueba si se aprieta Probar repetidamente.
var _test_zone_transition_scheduled: bool = false

## Tutorial muy simple (MVP 1.1): guía del primer armado (sin bloqueo duro).
const STEP_SELECT_BASE := 0
const STEP_PLACE_BASE := 1
const STEP_SELECT_WHEELS := 2
const STEP_PLACE_WHEELS := 3
const STEP_SELECT_MOTOR := 4
const STEP_PLACE_MOTOR := 5
const STEP_SELECT_BATTERY := 6
const STEP_PLACE_BATTERY := 7
const STEP_SELECT_TOOL := 8
const STEP_PLACE_TOOL := 9
const STEP_PRESS_TEST := 10
const STEP_DONE := 11

var _tutorial_step: int = STEP_SELECT_BASE
var _tutorial_part_tween: Tween = null
var _tutorial_slot_tween: Tween = null
var _tutorial_pointer: Node3D = null
var _tutorial_pointer_base: Node3D = null
var _tutorial_pointer_move_tween: Tween = null

var _placing_tween: Tween = null
var _reset_tween: Tween = null
var _tutorial_pointer_bob_tween: Tween = null


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_igor_guide = IgorGuideScript.new()
	_setup_camera()
	_title_label.text = _loc.t("WORKSHOP_TITLE")
	_test_button.text = _loc.t("WORKSHOP_BUTTON_TEST")
	_reset_button.text = _loc.t("WORKSHOP_BUTTON_RESET")
	_update_mission_title_label()
	_set_workshop_labels()
	set_igor_message(_loc.t("WORKSHOP_MOTORLING_INTRO"))

	if not _mission_state.mission_started:
		_mission_state.start_first_mission()
	_loc.locale_changed.connect(_on_locale_changed_workshop)
	_apply_mission_tool_parts_visibility()

	_validation_slots = [
		$Slots/SlotBase,
		$Slots/SlotWheels,
		$Slots/SlotMotor,
		$Slots/SlotBattery,
		$Slots/SlotTool,
	]

	for child: Node in $Parts.get_children():
		if child.has_signal("part_clicked"):
			child.part_clicked.connect(_on_part_clicked)
			_part_initial_transform[child] = child.transform

	for slot_node: Node in $Slots.get_children():
		if slot_node.has_signal("slot_clicked"):
			slot_node.slot_clicked.connect(_on_slot_clicked)

	_test_button.pressed.connect(_on_test_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_apply_button_feedback(_test_button)
	_apply_button_feedback(_reset_button)
	UIStyle.apply_primary_button(_test_button)
	UIStyle.apply_primary_button(_reset_button)

	_setup_tutorial_pointer()
	_set_tutorial_step(STEP_SELECT_BASE)
	_sync_tutorial_step_from_slots()


func _exit_tree() -> void:
	if _loc != null and _loc.locale_changed.is_connected(_on_locale_changed_workshop):
		_loc.locale_changed.disconnect(_on_locale_changed_workshop)
	if _tutorial_part_tween != null and _tutorial_part_tween.is_valid():
		_tutorial_part_tween.kill()
	_tutorial_part_tween = null
	if _tutorial_slot_tween != null and _tutorial_slot_tween.is_valid():
		_tutorial_slot_tween.kill()
	_tutorial_slot_tween = null
	if _tutorial_pointer_move_tween != null and _tutorial_pointer_move_tween.is_valid():
		_tutorial_pointer_move_tween.kill()
	_tutorial_pointer_move_tween = null
	if _tutorial_pointer_bob_tween != null and _tutorial_pointer_bob_tween.is_valid():
		_tutorial_pointer_bob_tween.kill()
	_tutorial_pointer_bob_tween = null
	if _placing_tween != null and _placing_tween.is_valid():
		_placing_tween.kill()
	_placing_tween = null
	if _reset_tween != null and _reset_tween.is_valid():
		_reset_tween.kill()
	_reset_tween = null


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	# Encuadre más amplio: mesa, huecos y piezas visibles sin que la UI tape el centro.
	cam.fov = 52.0
	cam.position = Vector3(0.12, 3.48, 8.5)
	cam.look_at(Vector3(0.0, 0.11, -0.06), Vector3.UP)


func set_igor_message(text: String) -> void:
	_igor_label.text = text


func _on_locale_changed_workshop() -> void:
	_title_label.text = _loc.t("WORKSHOP_TITLE")
	_test_button.text = _loc.t("WORKSHOP_BUTTON_TEST")
	_reset_button.text = _loc.t("WORKSHOP_BUTTON_RESET")
	_update_mission_title_label()
	_set_workshop_labels()
	set_igor_message(_get_tutorial_message_for_step(_tutorial_step))


func _update_mission_title_label() -> void:
	if _mission_state.current_mission_id == "carry_first_blocks":
		_mission_label.text = _loc.t("WORKSHOP_MISSION_LABEL_M2")
	else:
		_mission_label.text = _loc.t("WORKSHOP_MISSION_LABEL")


func _apply_mission_tool_parts_visibility() -> void:
	var shovel := $Parts/ShovelPart as StaticBody3D
	var cargo := $Parts/CargoBedPart as StaticBody3D
	if _mission_state.current_mission_id == "carry_first_blocks":
		shovel.visible = false
		shovel.input_ray_pickable = false
		cargo.visible = true
		cargo.input_ray_pickable = true
	else:
		shovel.visible = true
		shovel.input_ray_pickable = true
		cargo.visible = false
		cargo.input_ray_pickable = false


func _setup_tutorial_pointer() -> void:
	if _tutorial_pointer != null:
		return
	_tutorial_pointer = Node3D.new()
	_tutorial_pointer.name = "TutorialPointer"
	add_child(_tutorial_pointer)
	_tutorial_pointer.visible = false

	_tutorial_pointer_base = Node3D.new()
	_tutorial_pointer_base.name = "Base"
	_tutorial_pointer.add_child(_tutorial_pointer_base)

	var arrow := Label3D.new()
	arrow.text = "↓"
	arrow.pixel_size = 0.0085
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.modulate = Color(1, 0.97, 0.78, 1)
	arrow.outline_modulate = Color(0.05, 0.05, 0.1, 0.9)
	arrow.outline_size = 10
	_tutorial_pointer_base.add_child(arrow)

	if _tutorial_pointer_bob_tween != null and _tutorial_pointer_bob_tween.is_valid():
		_tutorial_pointer_bob_tween.kill()
	_tutorial_pointer_bob_tween = create_tween()
	_tutorial_pointer_bob_tween.set_loops()
	_tutorial_pointer_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tutorial_pointer_bob_tween.tween_property(_tutorial_pointer_base, "position:y", 0.14, 0.6)
	_tutorial_pointer_bob_tween.tween_property(_tutorial_pointer_base, "position:y", 0.0, 0.6)


func _set_tutorial_step(step: int) -> void:
	_tutorial_step = step
	set_igor_message(_get_tutorial_message_for_step(step))
	_update_tutorial_highlights()


func _get_tutorial_message_for_step(step: int) -> String:
	match step:
		STEP_SELECT_BASE:
			return _loc.t("WORKSHOP_SELECT_BASE")
		STEP_PLACE_BASE:
			return _loc.t("WORKSHOP_PLACE_BASE")
		STEP_SELECT_WHEELS:
			return _loc.t("WORKSHOP_SELECT_WHEELS")
		STEP_PLACE_WHEELS:
			return _loc.t("WORKSHOP_PLACE_WHEELS")
		STEP_SELECT_MOTOR:
			return _loc.t("WORKSHOP_SELECT_MOTOR")
		STEP_PLACE_MOTOR:
			return _loc.t("WORKSHOP_PLACE_MOTOR")
		STEP_SELECT_BATTERY:
			return _loc.t("WORKSHOP_SELECT_BATTERY")
		STEP_PLACE_BATTERY:
			return _loc.t("WORKSHOP_PLACE_BATTERY")
		STEP_SELECT_TOOL:
			if _mission_state.current_mission_id == "carry_first_blocks":
				return _loc.t("WORKSHOP_SELECT_CARGO")
			return _loc.t("WORKSHOP_SELECT_TOOL")
		STEP_PLACE_TOOL:
			if _mission_state.current_mission_id == "carry_first_blocks":
				return _loc.t("WORKSHOP_PLACE_CARGO")
			return _loc.t("WORKSHOP_PLACE_TOOL")
		STEP_PRESS_TEST:
			return _loc.t("WORKSHOP_PRESS_TEST")
		STEP_DONE:
			return _loc.t("WORKSHOP_DONE")
		_:
			return _loc.t("WORKSHOP_SELECT_BASE")


func _set_workshop_labels() -> void:
	# Part labels
	($Parts/BasePart/PartLabel as Label3D).text = _loc.t("PART_BASE")
	($Parts/WheelsPart/PartLabel as Label3D).text = _loc.t("PART_WHEELS")
	($Parts/MotorPart/PartLabel as Label3D).text = _loc.t("PART_MOTOR")
	($Parts/BatteryPart/PartLabel as Label3D).text = _loc.t("PART_BATTERY")
	($Parts/ShovelPart/PartLabel as Label3D).text = _loc.t("PART_SHOVEL")
	($Parts/CargoBedPart/PartLabel as Label3D).text = _loc.t("PART_CARGO_BED")
	# Slot labels
	($Slots/SlotBase/SlotLabel as Label3D).text = _loc.t("SLOT_BASE")
	($Slots/SlotWheels/SlotLabel as Label3D).text = _loc.t("SLOT_WHEELS")
	($Slots/SlotMotor/SlotLabel as Label3D).text = _loc.t("SLOT_MOTOR")
	($Slots/SlotBattery/SlotLabel as Label3D).text = _loc.t("SLOT_BATTERY")
	($Slots/SlotTool/SlotLabel as Label3D).text = _loc.t("SLOT_TOOL")
	# Motorling label
	($MotorlingPlaceholder/MotorlingLabel as Label3D).text = _loc.t("MOTORLING_LABEL")
	# Hint panel label
	var hint := get_node_or_null("CanvasLayer/UI/PartsPanel/HintLabel") as Label
	if hint != null:
		hint.text = _loc.t("WORKSHOP_HINT")


func _sync_tutorial_step_from_slots() -> void:
	# Encuentra el primer hueco faltante (orden MVP: base, ruedas, motor, batería, herramienta)
	var next_missing_slot: Node = null
	for i in range(_validation_slots.size()):
		var s: Node = _validation_slots[i]
		if s.placed_part == null:
			next_missing_slot = s
			break

	if next_missing_slot == null:
		if _igor_guide.is_build_complete(_validation_slots):
			_set_tutorial_step(STEP_PRESS_TEST)
		else:
			_set_tutorial_step(STEP_SELECT_BASE)
		return

	var slot_type: int = int(next_missing_slot.slot_type)
	var expects_place: bool = _selected_part != null and int(_selected_part.part_type) == slot_type
	_set_tutorial_step(_get_step_for_slot_type(slot_type, expects_place))


func _get_step_for_slot_type(slot_type: int, expects_place: bool) -> int:
	if expects_place:
		match slot_type:
			SLOT_TYPE_BASE:
				return STEP_PLACE_BASE
			SLOT_TYPE_WHEELS:
				return STEP_PLACE_WHEELS
			SLOT_TYPE_MOTOR:
				return STEP_PLACE_MOTOR
			SLOT_TYPE_BATTERY:
				return STEP_PLACE_BATTERY
			SLOT_TYPE_TOOL:
				return STEP_PLACE_TOOL
	else:
		match slot_type:
			SLOT_TYPE_BASE:
				return STEP_SELECT_BASE
			SLOT_TYPE_WHEELS:
				return STEP_SELECT_WHEELS
			SLOT_TYPE_MOTOR:
				return STEP_SELECT_MOTOR
			SLOT_TYPE_BATTERY:
				return STEP_SELECT_BATTERY
			SLOT_TYPE_TOOL:
				return STEP_SELECT_TOOL
	return STEP_SELECT_BASE


func _clear_tutorial_highlights() -> void:
	if _tutorial_part_tween != null:
		_tutorial_part_tween.kill()
		_tutorial_part_tween = null
	if _tutorial_slot_tween != null:
		_tutorial_slot_tween.kill()
		_tutorial_slot_tween = null
	if _tutorial_pointer_move_tween != null:
		_tutorial_pointer_move_tween.kill()
		_tutorial_pointer_move_tween = null
	if is_instance_valid(_tutorial_pointer):
		_tutorial_pointer.visible = false


func _update_tutorial_highlights() -> void:
	_clear_tutorial_highlights()

	var target_part := _get_part_for_step(_tutorial_step)
	if is_instance_valid(target_part) and target_part is Node3D and not target_part.is_placed:
		var p3 := target_part as Node3D
		var base_scale := p3.scale
		_tutorial_part_tween = create_tween().set_loops()
		_tutorial_part_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tutorial_part_tween.tween_property(p3, "scale", base_scale * 1.05, 0.35)
		_tutorial_part_tween.tween_property(p3, "scale", base_scale, 0.35)
		_set_pointer_to_world(p3.global_position + Vector3(0, 0.55, 0))
		return

	var target_slot := _get_slot_for_step(_tutorial_step)
	if is_instance_valid(target_slot):
		var marker := target_slot.get_node_or_null("Marker") as Node3D
		if is_instance_valid(marker):
			var base_scale_s := marker.scale
			_tutorial_slot_tween = create_tween().set_loops()
			_tutorial_slot_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_tutorial_slot_tween.tween_property(marker, "scale", base_scale_s * 1.12, 0.4)
			_tutorial_slot_tween.tween_property(marker, "scale", base_scale_s, 0.4)
			_set_pointer_to_world(marker.global_position + Vector3(0, 0.35, 0))
			return


func _set_pointer_to_world(world_pos: Vector3) -> void:
	if not is_instance_valid(_tutorial_pointer):
		return
	_tutorial_pointer.visible = true
	if _tutorial_pointer_move_tween != null:
		_tutorial_pointer_move_tween.kill()
		_tutorial_pointer_move_tween = null
	if _tutorial_pointer.global_position.distance_to(world_pos) < 0.01:
		_tutorial_pointer.global_position = world_pos
		return
	_tutorial_pointer_move_tween = create_tween()
	_tutorial_pointer_move_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tutorial_pointer_move_tween.tween_property(_tutorial_pointer, "global_position", world_pos, 0.18)
	_tutorial_pointer.visible = true


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2.ONE
	)


func _get_part_for_step(step: int) -> Node:
	match step:
		STEP_SELECT_BASE:
			return $Parts/BasePart
		STEP_SELECT_WHEELS:
			return $Parts/WheelsPart
		STEP_SELECT_MOTOR:
			return $Parts/MotorPart
		STEP_SELECT_BATTERY:
			return $Parts/BatteryPart
		STEP_SELECT_TOOL:
			if _mission_state.current_mission_id == "carry_first_blocks":
				return $Parts/CargoBedPart
			return $Parts/ShovelPart
		_:
			return null


func _get_slot_for_step(step: int) -> Node:
	match step:
		STEP_PLACE_BASE:
			return $Slots/SlotBase
		STEP_PLACE_WHEELS:
			return $Slots/SlotWheels
		STEP_PLACE_MOTOR:
			return $Slots/SlotMotor
		STEP_PLACE_BATTERY:
			return $Slots/SlotBattery
		STEP_PLACE_TOOL:
			return $Slots/SlotTool
		_:
			return null


func _clear_selection_visual() -> void:
	if _selected_part != null and _selected_part.has_method("set_selected_visual"):
		_selected_part.set_selected_visual(false)
	_selected_part = null


func _on_part_clicked(part: Node) -> void:
	if DEBUG_LOGS:
		print("[IGOR workshop] part_selected -> ", part.name)
	if part.is_placed:
		return

	# Si la guía espera una pieza específica, avisamos si eligen otra.
	var expected_part := _get_part_for_step(_tutorial_step)
	if expected_part != null and expected_part != part:
		set_igor_message(_loc.t("WORKSHOP_WRONG_PART"))
		_update_tutorial_highlights()
		# Igual permitimos seleccionar, pero no avanzamos el tutorial.

	if _selected_part != null and _selected_part != part:
		if _selected_part.has_method("set_selected_visual"):
			_selected_part.set_selected_visual(false)
	_selected_part = part
	if part.has_method("set_selected_visual"):
		part.set_selected_visual(true)
	set_igor_message(_loc.t("WORKSHOP_PART_READY"))
	_sync_tutorial_step_from_slots()


func _on_slot_clicked(slot: Node) -> void:
	if DEBUG_LOGS:
		print("[IGOR workshop] slot_selected -> ", slot.name)
	if _selected_part == null:
		_sync_tutorial_step_from_slots()
		return

	if slot.placed_part != null:
		set_igor_message(_loc.t("WORKSHOP_SLOT_OCCUPIED"))
		return

	# Si el tutorial espera un hueco específico, y tocan otro, mostramos una pista extra.
	var expected_slot := _get_slot_for_step(_tutorial_step)
	if expected_slot != null and expected_slot != slot:
		set_igor_message(_loc.t("WORKSHOP_WRONG_SLOT"))
		_update_tutorial_highlights()

	if _selected_part.part_type != slot.slot_type:
		set_igor_message(_loc.t("WORKSHOP_WRONG_SLOT_PART"))
		if slot.has_method("flash_error"):
			slot.flash_error()
		return

	slot.placed_part = _selected_part
	_selected_part.is_placed = true
	_selected_part.current_slot = slot
	if _selected_part.has_method("set_selected_visual"):
		_selected_part.set_selected_visual(false)
	var part_node := _selected_part as Node3D
	_selected_part = null
	var from_global := part_node.global_position
	part_node.reparent(slot, true)
	part_node.global_position = from_global
	var target_global := (slot as Node3D).global_position + Vector3(0.0, 0.22, 0.0)
	if _placing_tween != null:
		_placing_tween.kill()
		_placing_tween = null
	_placing_tween = create_tween()
	_placing_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_placing_tween.tween_property(part_node, "global_position", target_global, 0.26)
	_placing_tween.tween_property(part_node, "rotation", Vector3.ZERO, 0.12)
	_placing_tween.tween_property(part_node, "scale", Vector3.ONE, 0.12)
	if slot.has_method("flash_success"):
		slot.flash_success()

	var placed_base: bool = int(slot.slot_type) == SLOT_TYPE_BASE
	if placed_base:
		var dock := get_node_or_null("MotorlingDock") as Node3D
		var motorling := get_node_or_null("MotorlingPlaceholder")
		if dock != null and motorling != null and motorling.has_method("move_to_dock"):
			motorling.move_to_dock(dock)
		set_igor_message(_loc.t("WORKSHOP_MOTORLING_FOUND_BASE"))
		_sync_tutorial_step_from_slots()
	else:
		if int(slot.slot_type) == SLOT_TYPE_TOOL and _mission_state.current_mission_id == "carry_first_blocks":
			set_igor_message(_loc.t("WORKSHOP_CARGO_PLACED"))
		else:
			set_igor_message(_loc.t("WORKSHOP_PART_PLACED"))
		_sync_tutorial_step_from_slots()


func _on_test_pressed() -> void:
	var msg: String = _igor_guide.validate_build(_validation_slots)
	var complete: bool = _igor_guide.is_build_complete(_validation_slots)
	set_igor_message(msg)
	if not complete:
		_sync_tutorial_step_from_slots()
		return
	if _test_zone_transition_scheduled:
		return
	_test_zone_transition_scheduled = true
	_build_state.set_from_workshop(_validation_slots)
	if DEBUG_LOGS:
		print("Workshop: test OK, mission=", _mission_state.current_mission_id, " tool_type=", _build_state.tool_type)
	if _mission_state.current_mission_id == "carry_first_blocks":
		_mission_state.mark_second_machine_built()
	else:
		_mission_state.mark_machine_built()
	var motorling := get_node_or_null("MotorlingPlaceholder")
	if motorling != null and motorling.has_method("success_pulse"):
		motorling.success_pulse()
	_pulse_placed_parts_happy()
	get_tree().create_timer(1.2).timeout.connect(_on_test_zone_delay_elapsed, CONNECT_ONE_SHOT)


func _on_test_zone_delay_elapsed() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_go_to_test_zone()


func _go_to_test_zone() -> void:
	_test_zone_transition_scheduled = false
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if not _igor_guide.is_build_complete(_validation_slots):
		var retry_msg: String = _igor_guide.validate_build(_validation_slots)
		set_igor_message(retry_msg)
		if DEBUG_LOGS:
			print("Workshop: deferred transition skipped — ", retry_msg)
		return
	var path := "res://scenes/test_zone_blocks.tscn" if _mission_state.current_mission_id == "carry_first_blocks" else "res://scenes/test_zone.tscn"
	if DEBUG_LOGS:
		print("Workshop: fade to ", path)
	if is_instance_valid(_scene_transition):
		_scene_transition.fade_to_scene(path)


func _pulse_placed_parts_happy() -> void:
	for slot_node: Node in _validation_slots:
		var p: Node = slot_node.placed_part
		if p == null:
			continue
		var n3 := p as Node3D
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(n3, "scale", Vector3(1.06, 1.06, 1.06), 0.11)
		tw.tween_property(n3, "scale", Vector3.ONE, 0.34)


func _on_reset_pressed() -> void:
	_test_zone_transition_scheduled = false
	_build_state.reset()
	set_igor_message(_loc.t("WORKSHOP_SELECT_BASE"))
	_apply_mission_tool_parts_visibility()
	_set_tutorial_step(STEP_SELECT_BASE)
	_clear_selection_visual()

	if _reset_tween != null:
		_reset_tween.kill()
		_reset_tween = null
	_reset_tween = create_tween()
	_reset_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	for slot: Node in _validation_slots:
		var p: Node = slot.placed_part
		if p != null:
			slot.placed_part = null
			p.is_placed = false
			p.current_slot = null
			var body := p as Node3D
			body.reparent($Parts)
	for part: Node in _part_initial_transform.keys():
		if part is Node3D:
			var n3 := part as Node3D
			var target_xf := _part_initial_transform[part] as Transform3D
			_reset_tween.tween_property(n3, "transform", target_xf, 0.32)
		if part.has_method("sync_idle_after_reset"):
			part.sync_idle_after_reset()
		if part.has_method("set_selected_visual"):
			part.set_selected_visual(false)
	var motorling := get_node_or_null("MotorlingPlaceholder")
	if motorling != null and motorling.has_method("reset_to_start"):
		motorling.reset_to_start()
	_set_tutorial_step(STEP_SELECT_BASE)
