extends StaticBody3D

## Hueco en la plataforma. Click / toque después de elegir una pieza para intentar colocarla.

const DEBUG_LOGS := false ## Logs de picking ([IGOR pick]); normalmente apagado.

@export_enum("BASE", "WHEELS", "MOTOR", "BATTERY", "TOOL") var slot_type: int = 0

signal slot_clicked(slot: Node)

## Pieza colocada aquí, o null.
var placed_part: Node = null

var _marker_mat: StandardMaterial3D = null
var _idle_marker_color: Color = Color(0.35, 0.75, 0.55, 0.35)


func _ready() -> void:
	input_ray_pickable = true
	collision_layer = 1
	var marker := get_node_or_null("Marker") as MeshInstance3D
	if marker != null:
		var src := marker.get_surface_override_material(0)
		if src is StandardMaterial3D:
			_marker_mat = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			_idle_marker_color = _marker_mat.albedo_color
			marker.set_surface_override_material(0, _marker_mat)


## Parpadeo breve en rojo cuando la pieza no corresponde a este hueco.
func flash_error() -> void:
	if _marker_mat == null:
		return
	var red := Color(0.95, 0.18, 0.18, maxf(_idle_marker_color.a, 0.5))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_loops(4)
	tween.tween_property(_marker_mat, "albedo_color", red, 0.08)
	tween.tween_property(_marker_mat, "albedo_color", _idle_marker_color, 0.08)


## Pulso verde suave cuando la pieza encaja bien.
func flash_success() -> void:
	if _marker_mat == null:
		return
	var green := Color(0.25, 0.92, 0.45, maxf(_idle_marker_color.a, 0.55))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_loops(3)
	tween.tween_property(_marker_mat, "albedo_color", green, 0.12)
	tween.tween_property(_marker_mat, "albedo_color", _idle_marker_color, 0.18)


func _input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if DEBUG_LOGS:
				print("[IGOR pick] Slot clicked: ", name)
			slot_clicked.emit(self)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if DEBUG_LOGS:
				print("[IGOR pick] Slot clicked: ", name)
			slot_clicked.emit(self)
