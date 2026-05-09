extends RefCounted

## Mensajes de I.G.O.R. para validación de la máquina (orden del MVP).

const LocalizationScript := preload("res://scripts/localization.gd")
const MissionStateScript := preload("res://scripts/mission_state.gd")


func _localization_from_tree() -> LocalizationScript:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("Localization") as LocalizationScript


func _t(key: String) -> String:
	var loc := _localization_from_tree()
	if loc != null:
		return loc.t(key)
	return key


func _mission_state_from_tree() -> MissionStateScript:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("MissionState") as MissionStateScript


func _current_mission_id() -> String:
	var ms := _mission_state_from_tree()
	if ms == null:
		return "clear_first_path"
	return str(ms.current_mission_id)


func _expected_tool_type() -> String:
	if _current_mission_id() == "carry_first_blocks":
		return "cargo_bed"
	return "shovel"


func _tool_part_tool_type(placed_part: Node) -> String:
	if placed_part == null:
		return ""
	if "tool_type" in placed_part:
		return str(placed_part.tool_type)
	return ""


func is_build_complete(slots_in_order: Array) -> bool:
	if slots_in_order.size() < 5:
		return false
	for i in range(5):
		if not slots_in_order[i].placed_part:
			return false
	var tt := _tool_part_tool_type(slots_in_order[4].placed_part)
	return tt == _expected_tool_type()


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
	var tool_slot = slots_in_order[4]
	if not tool_slot.placed_part:
		if _expected_tool_type() == "cargo_bed":
			return _t("WORKSHOP_SLOT_CARGO_MISSING")
		return _t("WORKSHOP_SLOT_TOOL_MISSING")

	var placed_tool_tt := _tool_part_tool_type(tool_slot.placed_part)
	if placed_tool_tt != _expected_tool_type():
		return _t("WORKSHOP_WRONG_SLOT_PART")

	if _current_mission_id() == "carry_first_blocks":
		return _t("MISSION_2_SUCCESS")
	return _t("WORKSHOP_SUCCESS")
