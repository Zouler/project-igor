extends StaticBody3D

## Pieza colocable del taller. Click / toque para seleccionarla (si aún no está colocada).
## Orden del enum: BASE, WHEELS, MOTOR, BATTERY, TOOL (coincide con los slots en la escena).

const HIGHLIGHT_SCALE := 1.1

@export_enum("BASE", "WHEELS", "MOTOR", "BATTERY", "TOOL") var part_type: int = 0

signal part_clicked(part: Node)

var is_placed: bool = false
## Hueco donde quedó colocado (nodo StaticBody3D del slot).
var current_slot: Node = null

var _default_scale: Vector3 = Vector3.ONE
var _mesh_instances: Array[MeshInstance3D] = []


func _ready() -> void:
	input_ray_pickable = true
	collision_layer = 1
	_default_scale = scale
	_collect_mesh_instances(self)
	_duplicate_surface_materials()


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


## Feedback visual al elegir la pieza (escala + brillo suave).
func set_selected_visual(active: bool) -> void:
	scale = _default_scale * (HIGHLIGHT_SCALE if active else 1.0)
	for mi: MeshInstance3D in _mesh_instances:
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in range(mesh.get_surface_count()):
			var m := mi.get_surface_override_material(s)
			if m is StandardMaterial3D:
				var sm := m as StandardMaterial3D
				sm.emission_enabled = active
				if active:
					sm.emission = Color(0.95, 0.95, 1.0)
					sm.emission_energy_multiplier = 1.4


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
			print("Part clicked: ", name)
			part_clicked.emit(self)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			print("Part clicked: ", name)
			part_clicked.emit(self)
