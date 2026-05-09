extends Node3D

## Zona de prueba MVP: la máquina completa despeja piedras del camino (solo Tweens, sin física).

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _start_button: Button = %StartTestButton
@onready var _back_button: Button = %BackToWorkshopButton


func _ready() -> void:
	_setup_camera()
	_igor_label.text = "Probemos la nueva máquina."
	_start_button.pressed.connect(_on_start_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 50.0
	cam.position = Vector3(4.5, 3.2, 5.8)
	cam.look_at(Vector3(0.0, 0.2, 0.6), Vector3.UP)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/workshop.tscn")


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	_start_button.disabled = true
	_igor_label.text = "¡Mira! El motorcito está ayudando."
	await _run_clear_path_demo()
	_igor_label.text = "¡Camino despejado! Buen trabajo."


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
