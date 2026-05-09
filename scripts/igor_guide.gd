extends RefCounted

## Mensajes de I.G.O.R. para validación de la máquina (orden del MVP).

const LocalizationScript := preload("res://scripts/localization.gd")


func _t(key: String) -> String:
	# RefCounted no tiene acceso directo al árbol: usamos el autoload global si existe.
	if Engine.has_singleton("Localization"):
		var loc := Engine.get_singleton("Localization") as LocalizationScript
		if loc != null:
			return loc.t(key)
	return key


func is_build_complete(slots_in_order: Array) -> bool:
	if slots_in_order.size() < 5:
		return false
	for i in range(5):
		if not slots_in_order[i].placed_part:
			return false
	return true


func validate_build(slots_in_order: Array) -> String:
	if slots_in_order.size() < 5:
		return _t("WORKSHOP_SLOTS_MISSING")

	if not slots_in_order[0].placed_part:
		return _t("WORKSHOP_SLOT_BASE_MISSING")
	if not slots_in_order[1].placed_part:
		return _t("WORKSHOP_SLOT_WHEELS_MISSING")
	if not slots_in_order[2].placed_part:
		return _t("WORKSHOP_SLOT_MOTOR_MISSING")
	if not slots_in_order[3].placed_part:
		return _t("WORKSHOP_SLOT_BATTERY_MISSING")
	if not slots_in_order[4].placed_part:
		return _t("WORKSHOP_SLOT_TOOL_MISSING")

	return _t("WORKSHOP_SUCCESS")
