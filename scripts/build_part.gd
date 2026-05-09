extends StaticBody3D

## Pieza colocable del taller. Click / toque para seleccionarla (si aún no está colocada).
## Orden del enum: BASE, WHEELS, MOTOR, BATTERY, TOOL (coincide con los slots en la escena).

const DEBUG_LOGS := false ## Logs de picking ([IGOR pick]); normalmente apagado.

const HIGHLIGHT_SCALE := 1.15
const BOB_AMPLITUDE := 0.055
const BOB_HALF_PERIOD := 0.38

@export_enum("BASE", "WHEELS", "MOTOR", "BATTERY", "TOOL") var part_type: int = 0
## Para piezas TOOL: "shovel", "cargo_bed", etc. Vacío en piezas que no son herramienta.
@export var tool_type: String = ""

signal part_clicked(part: Node)

var is_placed: bool = false
## Hueco donde quedó colocado (nodo StaticBody3D del slot).
var current_slot: Node = null

var _default_scale: Vector3 = Vector3.ONE
var _mesh_instances: Array[MeshInstance3D] = []
var _pos_when_selection_started: Vector3
var _bob_tween: Tween = null


func _ready() -> void:
	input_ray_pickable = true
	collision_layer = 1
	_default_scale = scale
	_pos_when_selection_started = position
	_collect_mesh_instances(self)
	_duplicate_surface_materials()


## Llamado desde workshop tras Reiniciar para alinear el origen del bob con la mesa.
func sync_idle_after_reset() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null
	_pos_when_selection_started = position


func _collect_mesh_instances(n: Node) -> void:
	if n is MeshInstance3D:
		_mesh_instances.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_mesh_instances(c)


## Copia materiales de override para poder encender emisión sin tocar recursos compartidos de la escena.
func _duplicate_surface_materials() -> void:
	for mi: MeshInstance3D in _mesh_instances:
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in range(mesh.get_surface_count()):
			var ov := mi.get_surface_override_material(s)
			if ov != null:
				mi.set_surface_override_material(s, ov.duplicate())


## Feedback visual al elegir la pieza (escala + brillo + bob suave).
func set_selected_visual(active: bool) -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null

	if active:
		_pos_when_selection_started = position
		scale = _default_scale * HIGHLIGHT_SCALE
		for mi: MeshInstance3D in _mesh_instances:
			var mesh := mi.mesh
			if mesh == null:
				continue
			for s in range(mesh.get_surface_count()):
				var m := mi.get_surface_override_material(s)
				if m is StandardMaterial3D:
					var sm := m as StandardMaterial3D
					sm.emission_enabled = true
					sm.emission = Color(0.92, 0.95, 1.0)
					sm.emission_energy_multiplier = 2.15
		_bob_tween = create_tween().set_loops()
		_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var up := _pos_when_selection_started + Vector3(0.0, BOB_AMPLITUDE, 0.0)
		_bob_tween.tween_property(self, "position", up, BOB_HALF_PERIOD)
		_bob_tween.tween_property(self, "position", _pos_when_selection_started, BOB_HALF_PERIOD)
	else:
		position = _pos_when_selection_started
		scale = _default_scale
		for mi: MeshInstance3D in _mesh_instances:
			var mesh := mi.mesh
			if mesh == null:
				continue
			for s in range(mesh.get_surface_count()):
				var m := mi.get_surface_override_material(s)
				if m is StandardMaterial3D:
					var sm := m as StandardMaterial3D
					sm.emission_enabled = false
					sm.emission = Color.BLACK
					sm.emission_energy_multiplier = 1.0


func _input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if is_placed:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if DEBUG_LOGS:
				print("[IGOR pick] Part clicked: ", name)
			part_clicked.emit(self)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if DEBUG_LOGS:
				print("[IGOR pick] Part clicked: ", name)
			part_clicked.emit(self)
