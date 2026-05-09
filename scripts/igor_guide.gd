extends RefCounted

## Mensajes de I.G.O.R. para validación de la máquina (orden del MVP).


func validate_build(slots_in_order: Array) -> String:
	if slots_in_order.size() < 5:
		return "Faltan espacios en la mesa de trabajo."

	if not slots_in_order[0].placed_part:
		return "Primero necesitamos una base."
	if not slots_in_order[1].placed_part:
		return "La máquina necesita ruedas para moverse."
	if not slots_in_order[2].placed_part:
		return "La máquina necesita un motor para tener fuerza."
	if not slots_in_order[3].placed_part:
		return "La máquina necesita energía."
	if not slots_in_order[4].placed_part:
		return "Agreguemos una herramienta para trabajar."

	return "¡Excelente! Tu máquina puede empujar piedras."
