extends Node3D

## Placeholder visual Motorling / Spark Core: idle suave sin física ni interacción.

@export var bob_amplitude: float = 0.028
@export var bob_half_period: float = 1.35

@export var pulse_energy_low: float = 0.9
@export var pulse_energy_high: float = 2.05
@export var pulse_half_period: float = 0.75

var _base_position: Vector3
var _bob_tween: Tween
var _pulse_tween: Tween
var _spark_material: StandardMaterial3D


func _ready() -> void:
	_base_position = position
	_start_bob()
	_start_spark_pulse()


func _start_bob() -> void:
	_bob_tween = create_tween().set_loops()
	_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var up := _base_position + Vector3(0.0, bob_amplitude, 0.0)
	_bob_tween.tween_property(self, "position", up, bob_half_period)
	_bob_tween.tween_property(self, "position", _base_position, bob_half_period)


func _start_spark_pulse() -> void:
	var spark := get_node_or_null("SparkGlow") as MeshInstance3D
	if spark == null:
		return
	var src: Material = spark.get_surface_override_material(0)
	if src == null:
		return
	if src is StandardMaterial3D:
		_spark_material = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
		spark.set_surface_override_material(0, _spark_material)
	else:
		return
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


func _exit_tree() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
	if _pulse_tween != null:
		_pulse_tween.kill()
