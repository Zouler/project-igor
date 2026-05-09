extends Node3D

## Escena principal 3D del taller: selección de pieza + click en slot, validación con «Probar».

const BuildStateScript := preload("res://scripts/build_state.gd")

const DBG_WORKSHOP := false ## Poné en true para ver señales (prefijo [IGOR workshop]).

## Coincide con el primer valor de @export_enum en build_slot.gd (BASE).
const SLOT_TYPE_BASE := 0

const IgorGuideScript := preload("res://scripts/igor_guide.gd")

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _title_label: Label = %TitleLabel
@onready var _test_button: Button = %TestButton
@onready var _reset_button: Button = %ResetButton

var _selected_part: Node = null
var _validation_slots: Array = []
var _igor_guide: RefCounted
var _build_state: BuildStateScript
## Transform local inicial de cada pieza respecto a Parts (para Reiniciar).
var _part_initial_transform: Dictionary = {}
## Evita programar varias veces el cambio a la zona de prueba si se aprieta Probar repetidamente.
var _test_zone_transition_scheduled: bool = false


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_igor_guide = IgorGuideScript.new()
	_setup_camera()
	_title_label.text = "Taller I.G.O.R."
	set_igor_message("Este motorcito necesita un cuerpo. Elegí una pieza para empezar.")

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


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	# Encuadre más amplio: mesa, huecos y piezas visibles sin que la UI tape el centro.
	cam.fov = 52.0
	cam.position = Vector3(0.15, 3.45, 8.35)
	cam.look_at(Vector3(0.0, 0.12, -0.08), Vector3.UP)


func set_igor_message(text: String) -> void:
	_igor_label.text = text


func _clear_selection_visual() -> void:
	if _selected_part != null and _selected_part.has_method("set_selected_visual"):
		_selected_part.set_selected_visual(false)
	_selected_part = null


func _on_part_clicked(part: Node) -> void:
	if DBG_WORKSHOP:
		print("[IGOR workshop] part_selected -> ", part.name)
	if part.is_placed:
		return
	if _selected_part != null and _selected_part != part:
		if _selected_part.has_method("set_selected_visual"):
			_selected_part.set_selected_visual(false)
	_selected_part = part
	if part.has_method("set_selected_visual"):
		part.set_selected_visual(true)
	set_igor_message("Pieza lista. Ahora elegí su hueco.")


func _on_slot_clicked(slot: Node) -> void:
	if DBG_WORKSHOP:
		print("[IGOR workshop] slot_selected -> ", slot.name)
	if _selected_part == null:
		set_igor_message("Este motorcito necesita un cuerpo. Elegí una pieza para empezar.")
		return

	if slot.placed_part != null:
		set_igor_message("Ese lugar ya tiene una pieza.")
		return

	if _selected_part.part_type != slot.slot_type:
		set_igor_message("Esa pieza va en otro hueco.")
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
	part_node.reparent(slot)
	part_node.position = Vector3(0.0, 0.22, 0.0)
	part_node.rotation = Vector3.ZERO
	part_node.scale = Vector3.ONE
	if slot.has_method("flash_success"):
		slot.flash_success()

	var placed_base: bool = int(slot.slot_type) == SLOT_TYPE_BASE
	if placed_base:
		var dock := get_node_or_null("MotorlingDock") as Node3D
		var motorling := get_node_or_null("MotorlingPlaceholder")
		if dock != null and motorling != null and motorling.has_method("move_to_dock"):
			motorling.move_to_dock(dock)
		set_igor_message("El motorcito encontró una base.")
	else:
		set_igor_message("¡Muy bien! Esa pieza encajó.")


func _on_test_pressed() -> void:
	var msg: String = _igor_guide.validate_build(_validation_slots)
	set_igor_message(msg)
	if not _igor_guide.is_build_complete(_validation_slots):
		return
	if _test_zone_transition_scheduled:
		return
	_test_zone_transition_scheduled = true
	_build_state.set_from_workshop(_validation_slots)
	var motorling := get_node_or_null("MotorlingPlaceholder")
	if motorling != null and motorling.has_method("success_pulse"):
		motorling.success_pulse()
	_pulse_placed_parts_happy()
	get_tree().create_timer(1.2).timeout.connect(_go_to_test_zone)


func _go_to_test_zone() -> void:
	_test_zone_transition_scheduled = false
	if not is_inside_tree():
		return
	if not _igor_guide.is_build_complete(_validation_slots):
		return
	get_tree().change_scene_to_file("res://scenes/test_zone.tscn")


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
	_clear_selection_visual()
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
			n3.transform = _part_initial_transform[part] as Transform3D
		if part.has_method("sync_idle_after_reset"):
			part.sync_idle_after_reset()
		if part.has_method("set_selected_visual"):
			part.set_selected_visual(false)
	var motorling := get_node_or_null("MotorlingPlaceholder")
	if motorling != null and motorling.has_method("reset_to_start"):
		motorling.reset_to_start()
	set_igor_message("Volvamos a intentarlo.")
