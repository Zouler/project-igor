extends Node3D

## Escena principal 3D del taller: selección de pieza + click en slot, validación con «Probar».

const IgorGuideScript := preload("res://scripts/igor_guide.gd")

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _title_label: Label = %TitleLabel
@onready var _test_button: Button = %TestButton
@onready var _reset_button: Button = %ResetButton

var _selected_part: Node = null
var _validation_slots: Array = []
var _igor_guide: RefCounted
## Transform local inicial de cada pieza respecto a Parts (para Reiniciar).
var _part_initial_transform: Dictionary = {}


func _ready() -> void:
	_igor_guide = IgorGuideScript.new()
	_setup_camera()
	_title_label.text = "Taller I.G.O.R."
	set_igor_message("Elegí una pieza para empezar.")

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
	cam.position = Vector3(0.0, 3.6, 7.2)
	cam.look_at(Vector3(0.0, 0.2, 0.0), Vector3.UP)


func set_igor_message(text: String) -> void:
	_igor_label.text = text


func _clear_selection_visual() -> void:
	if _selected_part != null and _selected_part.has_method("set_selected_visual"):
		_selected_part.set_selected_visual(false)
	_selected_part = null


func _on_part_clicked(part: Node) -> void:
	print("Workshop: part_selected signal -> ", part.name)
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
	print("Workshop: slot_selected signal -> ", slot.name)
	if _selected_part == null:
		set_igor_message("Elegí una pieza para empezar.")
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
	set_igor_message("¡Muy bien! Esa pieza encajó.")


func _on_test_pressed() -> void:
	var msg: String = _igor_guide.validate_build(_validation_slots)
	set_igor_message(msg)


func _on_reset_pressed() -> void:
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
		if part.has_method("set_selected_visual"):
			part.set_selected_visual(false)
	set_igor_message("Volvamos a intentarlo.")
