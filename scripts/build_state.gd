extends Node

## Resumen global del armado completado en el taller (MVP; sin inventario complejo).
## Registrado como Autoload «BuildState» en project.godot.

const DEBUG_LOGS := false

var has_base: bool = false
var has_wheels: bool = false
var has_motor: bool = false
var has_battery: bool = false
var tool_type: String = ""


func reset() -> void:
	has_base = false
	has_wheels = false
	has_motor = false
	has_battery = false
	tool_type = ""


func is_complete() -> bool:
	return has_base and has_wheels and has_motor and has_battery and tool_type != ""


func set_from_workshop(slots: Array) -> void:
	reset()

	for slot in slots:
		if slot == null:
			continue

		var slot_type: int = int(slot.slot_type)
		var has_part: bool = slot.placed_part != null

		if not has_part:
			continue

		match slot_type:
			0:
				has_base = true
			1:
				has_wheels = true
			2:
				has_motor = true
			3:
				has_battery = true
			4:
				var placed: Node = slot.placed_part
				if placed != null and "tool_type" in placed:
					tool_type = str(placed.tool_type)

	if DEBUG_LOGS:
		print("BuildState set: ", has_base, has_wheels, has_motor, has_battery, tool_type)
