extends Node3D

## Motorling / Spark Core: idle, traslado al dock (base colocada), reset y pulso de éxito al completar.

@export var bob_amplitude: float = 0.028
@export var bob_half_period: float = 1.35

@export var pulse_energy_low: float = 0.9
@export var pulse_energy_high: float = 2.05
@export var pulse_half_period: float = 0.75

@export var dock_move_duration: float = 0.95
@export var reset_move_duration: float = 0.75

@export var success_glow_peak: float = 3.35

var _start_position: Vector3
var _base_position: Vector3
var _bob_tween: Tween
var _move_tween: Tween
var _pulse_tween: Tween
var _success_tween: Tween
var _spark_material: StandardMaterial3D


func _ready() -> void:
	_start_position = position
	_base_position = position
	_setup_spark_material()
	_start_bob_loop()
	_start_spark_pulse_loop()


func _setup_spark_material() -> void:
	var spark := get_node_or_null("SparkGlow") as MeshInstance3D
	if spark == null:
		return
	var src: Material = spark.get_surface_override_material(0)
	if src == null:
		return
	if src is StandardMaterial3D:
		_spark_material = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
		spark.set_surface_override_material(0, _spark_material)


func _kill_bob() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null


func _kill_move() -> void:
	if _move_tween != null:
		_move_tween.kill()
		_move_tween = null


func _kill_spark_loop() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null


func _kill_success_tween() -> void:
	if _success_tween != null:
		_success_tween.kill()
		_success_tween = null


func _start_bob_loop() -> void:
	_kill_bob()
	_bob_tween = create_tween().set_loops()
	_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var up := _base_position + Vector3(0.0, bob_amplitude, 0.0)
	_bob_tween.tween_property(self, "position", up, bob_half_period)
	_bob_tween.tween_property(self, "position", _base_position, bob_half_period)


func _start_spark_pulse_loop() -> void:
	if _spark_material == null:
		return
	_kill_spark_loop()
	_spark_material.emission_enabled = true
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(
		_spark_material,
		"emission_energy_multiplier",
		pulse_energy_high,
		pulse_half_period
	)
	_pulse_tween.tween_property(
		_spark_material,
		"emission_energy_multiplier",
		pulse_energy_low,
		pulse_half_period
	)


func move_to_dock(dock: Node3D) -> void:
	if dock == null:
		return
	_kill_move()
	_kill_bob()
	var target: Vector3 = dock.position
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target, dock_move_duration)
	_move_tween.finished.connect(_on_dock_move_finished, CONNECT_ONE_SHOT)


func _on_dock_move_finished() -> void:
	_base_position = position
	_start_bob_loop()


func reset_to_start() -> void:
	_kill_move()
	_kill_bob()
	_kill_success_tween()
	scale = Vector3.ONE
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", _start_position, reset_move_duration)
	_move_tween.finished.connect(_on_reset_move_finished, CONNECT_ONE_SHOT)


func _on_reset_move_finished() -> void:
	position = _start_position
	_base_position = _start_position
	_kill_spark_loop()
	_start_spark_pulse_loop()
	_start_bob_loop()


func success_pulse() -> void:
	if _spark_material == null:
		_setup_spark_material()
	if _spark_material == null:
		return
	_kill_spark_loop()
	_kill_success_tween()
	_success_tween = create_tween()
	_success_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_success_tween.set_parallel(true)
	_success_tween.tween_property(self, "scale", Vector3(1.09, 1.09, 1.09), 0.15)
	_success_tween.tween_property(_spark_material, "emission_energy_multiplier", success_glow_peak, 0.18)
	_success_tween.chain().set_parallel(true)
	_success_tween.tween_property(self, "scale", Vector3.ONE, 0.4)
	_success_tween.tween_property(_spark_material, "emission_energy_multiplier", pulse_energy_low, 0.42)
	_success_tween.finished.connect(_start_spark_pulse_loop, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	_kill_bob()
	_kill_move()
	_kill_spark_loop()
	_kill_success_tween()
