extends Node

signal locale_changed

## Localización simple (MVP 1.4): diccionarios en memoria, sin archivos externos aún.

const DEBUG_LOGS := false

var current_locale: String = "en"

var translations := {
	"en": {
		"LANGUAGE_LABEL": "Language",
		"LANGUAGE_ENGLISH": "English",
		"LANGUAGE_SPANISH": "Spanish",
		"START_TITLE": "Project I.G.O.R.",
		"START_SUBTITLE": "Inventive Guide Operating Robot",
		"START_BUTTON_NEW": "Start",
		"START_BUTTON_CONTINUE": "Continue",
		"START_BUTTON_RESET": "Reset demo",
		"START_BUTTON_SETTINGS": "Settings",
		"START_FOOTER": "Build machines. Help the planet.",
		"START_DEMO_RESET": "Demo reset.",
		"START_NO_PROGRESS": "No saved progress yet.",
		"SETTINGS_TITLE": "Settings",
		"SETTINGS_CLOSE": "Close",

		"WORKSHOP_TITLE": "Project I.G.O.R. - Workshop",
		"WORKSHOP_MISSION_LABEL": "Mission: Clear the first path",
		"WORKSHOP_MOTORLING_INTRO": "This little motor needs a body. Choose a part to begin.",
		"WORKSHOP_SELECT_BASE": "First, choose the base.",
		"WORKSHOP_PLACE_BASE": "Now place it in the Base slot.",
		"WORKSHOP_SELECT_WHEELS": "Now choose the wheels.",
		"WORKSHOP_PLACE_WHEELS": "Place them in the Wheels slot.",
		"WORKSHOP_SELECT_MOTOR": "Choose the motor.",
		"WORKSHOP_PLACE_MOTOR": "Place it in the Motor slot.",
		"WORKSHOP_SELECT_BATTERY": "Choose the battery.",
		"WORKSHOP_PLACE_BATTERY": "Place it in the Battery slot.",
		"WORKSHOP_SELECT_TOOL": "Choose the shovel.",
		"WORKSHOP_PLACE_TOOL": "Place it in the Tool slot.",
		"WORKSHOP_PRESS_TEST": "Great! Now press Test.",
		"WORKSHOP_DONE": "The machine is ready!",
		"WORKSHOP_WRONG_PART": "We will use that part later.",
		"WORKSHOP_WRONG_SLOT": "Let's try the correct slot.",
		"WORKSHOP_PART_READY": "Part ready. Now choose its slot.",
		"WORKSHOP_PART_PLACED": "Good job! That part fits.",
		"WORKSHOP_SLOT_BASE_MISSING": "First, we need a base.",
		"WORKSHOP_SLOT_WHEELS_MISSING": "The machine needs wheels to move.",
		"WORKSHOP_SLOT_MOTOR_MISSING": "The machine needs a motor for power.",
		"WORKSHOP_SLOT_BATTERY_MISSING": "The machine needs energy.",
		"WORKSHOP_SLOT_TOOL_MISSING": "Let's add a tool to work.",
		"WORKSHOP_MOTORLING_FOUND_BASE": "The little motor found a base.",
		"WORKSHOP_SUCCESS": "You did it! The little motor has a body to help.",
		"WORKSHOP_RESET": "Let's try again.",
		"WORKSHOP_BUTTON_TEST": "Test",
		"WORKSHOP_BUTTON_RESET": "Reset",
		"WORKSHOP_SLOT_OCCUPIED": "That spot already has a part.",
		"WORKSHOP_WRONG_SLOT_PART": "That part goes in a different slot.",
		"WORKSHOP_SLOTS_MISSING": "The workbench is missing slots.",
		"WORKSHOP_HINT": "Parts: tap a part, then tap the matching green slot (base, wheels, motor, battery, tool).",

		"PART_BASE": "Base",
		"PART_WHEELS": "Wheels",
		"PART_MOTOR": "Motor",
		"PART_BATTERY": "Battery",
		"PART_SHOVEL": "Shovel",
		"SLOT_BASE": "Base",
		"SLOT_WHEELS": "Wheels",
		"SLOT_MOTOR": "Motor",
		"SLOT_BATTERY": "Battery",
		"SLOT_TOOL": "Tool",
		"MOTORLING_LABEL": "Little Motor",

		"MISSION_CLEAR_FIRST_PATH_TITLE": "Clear the first path",
		"MISSION_CLEAR_FIRST_PATH_DESCRIPTION": "Build a machine with a shovel to move the rocks.",
		"MISSION_STEP_BUILD": "Step 1: Build a machine.",
		"MISSION_STEP_TEST": "Step 2: Test the machine.",
		"MISSION_STEP_COMMUNITY": "Step 3: See how the planet improves.",
		"MISSION_COMPLETED_FIRST": "First mission completed.",

		"MISSION_SELECT_TITLE": "Missions",
		"MISSION_SELECT_MESSAGE": "Choose how to help the planet.",
		"MISSION_1_TITLE": "Clear the first path",
		"MISSION_1_DESCRIPTION": "Build a shovel machine to move the rocks.",
		"MISSION_1_STATUS_AVAILABLE": "Available",
		"MISSION_1_STATUS_COMPLETED": "Completed",
		"MISSION_1_BUTTON": "Start mission",
		"MISSION_2_TITLE": "Carry the first blocks",
		"MISSION_2_DESCRIPTION": "A new helper machine will be needed soon.",
		"MISSION_2_STATUS_LOCKED": "Coming soon",
		"MISSION_2_BUTTON_LOCKED": "Locked",
		"MISSION_2_STATUS_AVAILABLE": "Available",
		"MISSION_2_BUTTON_AVAILABLE": "Start mission",
		"MISSION_2_NOT_READY_MESSAGE": "This mission is unlocked, but its machine is not ready yet.",
		"MISSION_SELECT_BACK": "Back",
		"MISSION_LOCKED_MESSAGE": "This mission is not ready yet.",

		"TEST_TITLE": "Test Zone",
		"TEST_INITIAL_MESSAGE": "Let's test the new machine.",
		"TEST_START_MESSAGE": "Look! The little motor is helping.",
		"TEST_SUCCESS_MESSAGE": "Path cleared! The planet is starting to wake up.",
		"TEST_SIGN_READY": "Path ready",
		"TEST_BUTTON_START": "Start test",
		"TEST_BUTTON_BACK": "Back",
		"TEST_BUTTON_CONTINUE": "Continue",
		"TEST_MACHINE_LABEL": "Helper Motorling",
		"TEST_HINT": "Tap “Start test” to see how the helper pushes the rocks.",

		"COMMUNITY_TITLE": "Community",
		"COMMUNITY_MESSAGE": "A part of the planet started moving again.",
		"COMMUNITY_PROGRESS": "Planet progress: 1%",
		"COMMUNITY_MISSION_COMPLETED": "First mission completed",
		"COMMUNITY_BUTTON_BACK": "Back to workshop",
		"COMMUNITY_BUTTON_NEXT": "Next mission",
		"COMMUNITY_NEXT_MESSAGE": "Soon we will build something new.",
		"COMMUNITY_HINT": "Each machine we test wakes up a little more of the mechanical planet.",
		"STORY_NEXT": "Next",
		"STORY_SKIP": "Skip",
		"STORY_START_MISSION": "Start mission",
		"STORY_STEP_1": "A young inventor built a spaceship with his own hands.",
		"STORY_STEP_2": "He was so tired that he fell asleep on the control panel.",
		"STORY_STEP_3": "By accident, the ship launched and traveled very, very far.",
		"STORY_STEP_4": "When he woke up, the ship was landing on a small silent planet.",
		"STORY_STEP_5": "Near the ship, something half-buried caught his attention.",
		"STORY_STEP_6": "With a toy shovel, he uncovered I.G.O.R.",
		"STORY_STEP_7": "I.G.O.R. was old, curious, and kind. He only wanted to help.",
		"STORY_STEP_8": "The ship was broken, and the planet was broken too.",
		"STORY_STEP_9": "To get back home, he would build machines and wake the planet."
	},
	"es": {
		"LANGUAGE_LABEL": "Idioma",
		"LANGUAGE_ENGLISH": "Inglés",
		"LANGUAGE_SPANISH": "Español",
		"START_TITLE": "Proyecto I.G.O.R.",
		"START_SUBTITLE": "Inventive Guide Operating Robot",
		"START_BUTTON_NEW": "Empezar",
		"START_BUTTON_CONTINUE": "Continuar",
		"START_BUTTON_RESET": "Reiniciar demo",
		"START_BUTTON_SETTINGS": "Opciones",
		"START_FOOTER": "Construí máquinas. Ayudá al planeta.",
		"START_DEMO_RESET": "Demo reiniciada.",
		"START_NO_PROGRESS": "Todavía no hay progreso guardado.",
		"SETTINGS_TITLE": "Opciones",
		"SETTINGS_CLOSE": "Cerrar",

		"WORKSHOP_TITLE": "Proyecto I.G.O.R. - Taller",
		"WORKSHOP_MISSION_LABEL": "Misión: Despejar el primer camino",
		"WORKSHOP_MOTORLING_INTRO": "Este motorcito necesita un cuerpo. Elegí una pieza para empezar.",
		"WORKSHOP_SELECT_BASE": "Primero elegí la base.",
		"WORKSHOP_PLACE_BASE": "Ahora ponela en el hueco de Base.",
		"WORKSHOP_SELECT_WHEELS": "Ahora elegí las ruedas.",
		"WORKSHOP_PLACE_WHEELS": "Ponelas en el hueco de Ruedas.",
		"WORKSHOP_SELECT_MOTOR": "Elegí el motor.",
		"WORKSHOP_PLACE_MOTOR": "Ponelo en el hueco de Motor.",
		"WORKSHOP_SELECT_BATTERY": "Elegí la batería.",
		"WORKSHOP_PLACE_BATTERY": "Ponela en el hueco de Batería.",
		"WORKSHOP_SELECT_TOOL": "Elegí la pala.",
		"WORKSHOP_PLACE_TOOL": "Ponela en el hueco de Herramienta.",
		"WORKSHOP_PRESS_TEST": "¡Listo! Ahora toquemos Probar.",
		"WORKSHOP_DONE": "¡La máquina está lista!",
		"WORKSHOP_WRONG_PART": "Esa pieza la usamos después.",
		"WORKSHOP_WRONG_SLOT": "Probemos en el hueco correcto.",
		"WORKSHOP_PART_READY": "Pieza lista. Ahora elegí su hueco.",
		"WORKSHOP_PART_PLACED": "¡Muy bien! Esa pieza encajó.",
		"WORKSHOP_SLOT_BASE_MISSING": "Primero necesitamos una base.",
		"WORKSHOP_SLOT_WHEELS_MISSING": "La máquina necesita ruedas para moverse.",
		"WORKSHOP_SLOT_MOTOR_MISSING": "La máquina necesita un motor para tener fuerza.",
		"WORKSHOP_SLOT_BATTERY_MISSING": "La máquina necesita energía.",
		"WORKSHOP_SLOT_TOOL_MISSING": "Agreguemos una herramienta para trabajar.",
		"WORKSHOP_MOTORLING_FOUND_BASE": "El motorcito encontró una base.",
		"WORKSHOP_SUCCESS": "¡Lo lograste! El motorcito ya tiene un cuerpo para ayudar.",
		"WORKSHOP_RESET": "Volvamos a intentarlo.",
		"WORKSHOP_BUTTON_TEST": "Probar",
		"WORKSHOP_BUTTON_RESET": "Reiniciar",
		"WORKSHOP_SLOT_OCCUPIED": "Ese lugar ya tiene una pieza.",
		"WORKSHOP_WRONG_SLOT_PART": "Esa pieza va en otro hueco.",
		"WORKSHOP_SLOTS_MISSING": "Faltan espacios en la mesa de trabajo.",
		"WORKSHOP_HINT": "Piezas: toca una pieza en la mesa y luego el hueco verde que le corresponde (base, ruedas, motor, batería, herramienta).",

		"PART_BASE": "Base",
		"PART_WHEELS": "Ruedas",
		"PART_MOTOR": "Motor",
		"PART_BATTERY": "Batería",
		"PART_SHOVEL": "Pala",
		"SLOT_BASE": "Base",
		"SLOT_WHEELS": "Ruedas",
		"SLOT_MOTOR": "Motor",
		"SLOT_BATTERY": "Batería",
		"SLOT_TOOL": "Herramienta",
		"MOTORLING_LABEL": "Motorcito",

		"MISSION_CLEAR_FIRST_PATH_TITLE": "Despejar el primer camino",
		"MISSION_CLEAR_FIRST_PATH_DESCRIPTION": "Construí una máquina con pala para mover las piedras.",
		"MISSION_STEP_BUILD": "Paso 1: Construí una máquina.",
		"MISSION_STEP_TEST": "Paso 2: Probá la máquina.",
		"MISSION_STEP_COMMUNITY": "Paso 3: Mirá cómo mejora el planeta.",
		"MISSION_COMPLETED_FIRST": "Primera misión completada.",

		"MISSION_SELECT_TITLE": "Misiones",
		"MISSION_SELECT_MESSAGE": "Elegí cómo ayudar al planeta.",
		"MISSION_1_TITLE": "Despejar el primer camino",
		"MISSION_1_DESCRIPTION": "Construí una máquina con pala para mover las piedras.",
		"MISSION_1_STATUS_AVAILABLE": "Disponible",
		"MISSION_1_STATUS_COMPLETED": "Completada",
		"MISSION_1_BUTTON": "Empezar misión",
		"MISSION_2_TITLE": "Transportar los primeros bloques",
		"MISSION_2_DESCRIPTION": "Pronto hará falta una nueva máquina ayudante.",
		"MISSION_2_STATUS_LOCKED": "Próximamente",
		"MISSION_2_BUTTON_LOCKED": "Bloqueada",
		"MISSION_2_STATUS_AVAILABLE": "Disponible",
		"MISSION_2_BUTTON_AVAILABLE": "Empezar misión",
		"MISSION_2_NOT_READY_MESSAGE": "Esta misión está desbloqueada, pero su máquina todavía no está lista.",
		"MISSION_SELECT_BACK": "Volver",
		"MISSION_LOCKED_MESSAGE": "Esta misión todavía no está lista.",

		"TEST_TITLE": "Zona de prueba",
		"TEST_INITIAL_MESSAGE": "Probemos la nueva máquina.",
		"TEST_START_MESSAGE": "¡Mira! El motorcito está ayudando.",
		"TEST_SUCCESS_MESSAGE": "¡Camino despejado! El planeta empieza a despertar.",
		"TEST_SIGN_READY": "Camino listo",
		"TEST_BUTTON_START": "Iniciar prueba",
		"TEST_BUTTON_BACK": "Volver",
		"TEST_BUTTON_CONTINUE": "Continuar",
		"TEST_MACHINE_LABEL": "Motorcito Ayudante",
		"TEST_HINT": "Tocá «Iniciar prueba» para ver cómo el motorcito empuja las piedras.",

		"COMMUNITY_TITLE": "Comunidad",
		"COMMUNITY_MESSAGE": "Una parte del planeta volvió a moverse.",
		"COMMUNITY_PROGRESS": "Progreso del planeta: 1%",
		"COMMUNITY_MISSION_COMPLETED": "Primera misión completada",
		"COMMUNITY_BUTTON_BACK": "Volver al taller",
		"COMMUNITY_BUTTON_NEXT": "Siguiente misión",
		"COMMUNITY_NEXT_MESSAGE": "Pronto construiremos algo nuevo.",
		"COMMUNITY_HINT": "Cada máquina que probamos despierta un poquito más al planeta mecánico.",
		"STORY_NEXT": "Siguiente",
		"STORY_SKIP": "Saltar",
		"STORY_START_MISSION": "Empezar misión",
		"STORY_STEP_1": "Un pequeño inventor construyó una nave con sus propias manos.",
		"STORY_STEP_2": "Estaba tan cansado que se quedó dormido sobre el panel de control.",
		"STORY_STEP_3": "Sin querer, la nave despegó y viajó muy, muy lejos.",
		"STORY_STEP_4": "Al despertar, estaba bajando hacia un planeta pequeño y silencioso.",
		"STORY_STEP_5": "Cerca de la nave encontró algo medio enterrado.",
		"STORY_STEP_6": "Con su pala de juguete, descubrió a I.G.O.R.",
		"STORY_STEP_7": "I.G.O.R. era viejo, curioso y amable. Solo quería ayudar.",
		"STORY_STEP_8": "La nave estaba rota, y el planeta también.",
		"STORY_STEP_9": "Para volver a casa, tendrán que construir máquinas y despertar al planeta."
	}
}


func set_locale(locale: String) -> void:
	if not translations.has(locale):
		return
	if current_locale == locale:
		return
	current_locale = locale
	emit_signal("locale_changed")
	if DEBUG_LOGS:
		print("Localization locale set: ", locale)
	# Guardar locale si existe SaveManager.
	if Engine.has_singleton("SaveManager"):
		var sm := Engine.get_singleton("SaveManager")
		if sm != null and sm.has_method("save_game"):
			sm.call("save_game")


func get_locale() -> String:
	return current_locale


func t(key: String) -> String:
	if translations.has(current_locale) and (translations[current_locale] as Dictionary).has(key):
		return (translations[current_locale] as Dictionary)[key]
	if translations.has("en") and (translations["en"] as Dictionary).has(key):
		return (translations["en"] as Dictionary)[key]
	return key

