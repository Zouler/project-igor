extends Node3D

## Prints a concise import audit for the raw GLB model in `igor_model_import_test.tscn`.
const DEBUG_LOGS := true
const APPLY_TEMP_PREVIEW_MATERIAL := false
const APPLY_BASIC_IGOR_TEST_MATERIALS := false
const APPLY_IGOR_YELLOW_TUNING := false
const APPLY_STRONG_YELLOW_OVERRIDE := false

@export var model_root_path: NodePath = NodePath("IgorModelRoot")
@export var auto_place_on_floor: bool = false
@export var floor_y: float = 0.0
@export var floor_clearance: float = 0.02


func _ready() -> void:
	if not DEBUG_LOGS:
		return
	call_deferred("_audit")


func _audit() -> void:
	var model_root := get_node_or_null(model_root_path) as Node3D
	if model_root == null:
		print("[IGOR GLB AUDIT] Model root NOT found at: ", model_root_path)
		return

	print("[IGOR GLB AUDIT] Model root found: ", model_root.name)
	if model_root.get_child_count() == 0:
		print("[IGOR GLB AUDIT] WARNING: Model root has no children (GLB not instanced?)")
		return

	var imported := model_root.get_child(0) as Node
	var imported_name := "(null)"
	if imported != null:
		imported_name = imported.name
	print("[IGOR GLB AUDIT] Imported node: ", imported_name)
	print("[IGOR GLB AUDIT] Top-level children under imported:")
	if imported != null:
		for c in imported.get_children():
			print("  - ", c.name)

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model_root, meshes)
	print("[IGOR GLB AUDIT] MeshInstance3D count: ", meshes.size())
	if meshes.is_empty():
		print("[IGOR GLB AUDIT] WARNING: No MeshInstance3D nodes found under model root.")
		return

	print("[IGOR GLB AUDIT] --- Runtime modes ---")
	print("  - auto_place_on_floor: ", auto_place_on_floor, " | floor_y=", floor_y, " | clearance=", floor_clearance)
	print("  - APPLY_IGOR_YELLOW_TUNING: ", APPLY_IGOR_YELLOW_TUNING)
	print("  - APPLY_STRONG_YELLOW_OVERRIDE: ", APPLY_STRONG_YELLOW_OVERRIDE)
	print("  - APPLY_TEMP_PREVIEW_MATERIAL: ", APPLY_TEMP_PREVIEW_MATERIAL)
	print("  - APPLY_BASIC_IGOR_TEST_MATERIALS: ", APPLY_BASIC_IGOR_TEST_MATERIALS)

	if auto_place_on_floor:
		_place_model_on_floor(model_root, meshes)

	_print_hierarchy(model_root)
	_print_classification_report(meshes)
	_warn_about_mesh_quality(meshes)

	if APPLY_STRONG_YELLOW_OVERRIDE:
		var r := _apply_strong_yellow_override(meshes)
		print("[IGOR GLB AUDIT] Strong yellow override applied. Meshes overridden: ", r.get("meshes_overridden", 0))
	elif APPLY_IGOR_YELLOW_TUNING:
		var r2 := _apply_igor_yellow_tuning(meshes)
		print("[IGOR GLB AUDIT] Yellow tuning applied (texture-preserving).")
		print("  - materials overridden: ", r2.get("materials_overridden", 0))
		print("  - surfaces tuned: ", r2.get("surfaces_tuned", 0))
		print("  - albedo textures found: ", r2.get("albedo_textures_found", 0))
		print("  - eye/dark parts preserved: ", r2.get("preserved_parts", 0))

	if APPLY_TEMP_PREVIEW_MATERIAL:
		_apply_preview_material(meshes)
	elif APPLY_BASIC_IGOR_TEST_MATERIALS:
		_apply_basic_igor_materials(meshes)

	var total_surfaces := 0
	var total_material_slots := 0
	var materials_found := 0
	var null_material_slots := 0
	var near_white_materials := 0
	var textures_found := 0
	var albedo_textures_found := 0

	var merged := AABB()
	var has_aabb := false

	for mi in meshes:
		if mi.mesh != null:
			var sc := mi.mesh.get_surface_count()
			total_surfaces += sc
			total_material_slots += sc
			var aabb := _aabb_in_global(mi)
			if not has_aabb:
				merged = aabb
				has_aabb = true
			else:
				merged = merged.merge(aabb)

	print("[IGOR GLB AUDIT] Total surfaces: ", total_surfaces)

	for mi in meshes:
		var mesh_name := "(null-mesh)"
		var sc := 0
		if mi.mesh != null:
			mesh_name = mi.mesh.resource_name
			sc = mi.mesh.get_surface_count()
		print("[IGOR GLB AUDIT] MeshInstance3D: ", mi.name, " | mesh=", mesh_name, " | surfaces=", sc)
		print("  - material_override: ", "YES" if mi.material_override != null else "NO")
		for i in range(sc):
			var mat := _get_material_for_surface(mi, i)
			if mat == null:
				null_material_slots += 1
				print("  - surface ", i, ": material = (null)")
				continue
			materials_found += 1
			var mat_path := _res_path(mat)
			print("  - surface ", i, ": material = ", mat.get_class(), " | path=", mat_path)

			if mat is BaseMaterial3D:
				var bm := mat as BaseMaterial3D
				var c: Color = bm.albedo_color
				print("    - albedo_color: ", c, " | metallic=", bm.metallic, " | roughness=", bm.roughness)
				if _is_near_white(c):
					near_white_materials += 1
				if bm.albedo_texture != null:
					albedo_textures_found += 1
				textures_found += _print_material_textures(bm)
			elif mat is ShaderMaterial:
				var sm := mat as ShaderMaterial
				print("    - shader: ", _res_path(sm.shader))

	print("[IGOR GLB AUDIT] Material slots total: ", total_material_slots)
	print("[IGOR GLB AUDIT] Materials found (non-null slots): ", materials_found)
	print("[IGOR GLB AUDIT] Null material slots: ", null_material_slots)
	print("[IGOR GLB AUDIT] Textures found (approx): ", textures_found)
	print("[IGOR GLB AUDIT] Albedo textures found (BaseMaterial3D): ", albedo_textures_found)
	print("[IGOR GLB AUDIT] Near-white materials (BaseMaterial3D): ", near_white_materials)

	if total_material_slots > 0:
		var null_ratio: float = float(null_material_slots) / float(total_material_slots)
		if null_ratio > 0.5:
			print("[IGOR GLB AUDIT] WARNING: Most material slots are NULL (ratio=", null_ratio, ").")
	if materials_found > 0:
		var white_ratio: float = float(near_white_materials) / float(materials_found)
		if white_ratio > 0.6:
			print("[IGOR GLB AUDIT] WARNING: Most materials are near-white (ratio=", white_ratio, ").")
	if textures_found == 0:
		print("[IGOR GLB AUDIT] WARNING: No textures found on BaseMaterial3D materials.")

	if has_aabb:
		var size := merged.size
		var center := merged.position + size * 0.5
		print("[IGOR GLB AUDIT] Approx bounds size: ", size)
		print("[IGOR GLB AUDIT] Approx bounds center: ", center)

		var origin_dist := center.length()
		if origin_dist > 10.0:
			print("[IGOR GLB AUDIT] WARNING: Model center far from origin (dist=", origin_dist, ").")

		var max_dim: float = max(size.x, max(size.y, size.z))
		if max_dim < 0.2:
			print("[IGOR GLB AUDIT] WARNING: Model appears extremely SMALL (max_dim=", max_dim, ").")
		elif max_dim > 10.0:
			print("[IGOR GLB AUDIT] WARNING: Model appears extremely LARGE (max_dim=", max_dim, ").")
	else:
		print("[IGOR GLB AUDIT] WARNING: Could not compute bounds (no meshes with AABB).")


func _print_hierarchy(model_root: Node3D) -> void:
	print("[IGOR GLB AUDIT] --- Node hierarchy (from IgorModelRoot) ---")
	_print_node_recursive(model_root, 0)


func _print_node_recursive(n: Node, depth: int) -> void:
	var indent := ""
	for _i in range(depth):
		indent += "  "
	var line := indent + n.name + " (" + n.get_class() + ")"
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var sc := 0
		var mesh_res := "(null)"
		if mi.mesh != null:
			sc = mi.mesh.get_surface_count()
			mesh_res = mi.mesh.resource_name
		line += " surfaces=" + str(sc) + " mesh=" + mesh_res
		line += " pos_l=" + str(mi.position) + " pos_g=" + str(mi.global_position)
		if mi.mesh != null:
			var aabb_l := mi.get_aabb()
			var aabb_g := _aabb_in_global(mi)
			line += " aabb_l=" + str(aabb_l.size) + " aabb_g=" + str(aabb_g.size)
	print(line)
	for c in n.get_children():
		_print_node_recursive(c, depth + 1)


func _print_classification_report(meshes: Array[MeshInstance3D]) -> void:
	var counts: Dictionary = {
		"head": 0,
		"body": 0,
		"eyes": 0,
		"antenna": 0,
		"arms": 0,
		"hands": 0,
		"legs": 0,
		"feet": 0,
		"joints": 0,
		"tag": 0,
		"unknown": 0,
	}
	for mi in meshes:
		var cat := _classify_mesh(mi.name)
		counts[cat] = int(counts.get(cat, 0)) + 1

	print("[IGOR GLB AUDIT] --- Potential part classification ---")
	for k in ["head", "eyes", "body", "antenna", "arms", "hands", "legs", "feet", "joints", "tag"]:
		print("  - ", k, ": ", "found" if int(counts[k]) > 0 else "not found", " (", counts[k], ")")
	print("  - unknown mesh count: ", counts["unknown"])


func _classify_mesh(name_in: String) -> String:
	var n := name_in.to_lower()
	if n.find("head") != -1:
		return "head"
	if n.find("eye") != -1:
		return "eyes"
	if n.find("antenna") != -1:
		return "antenna"
	if n.find("arm") != -1:
		return "arms"
	if n.find("hand") != -1:
		return "hands"
	if n.find("leg") != -1:
		return "legs"
	if n.find("foot") != -1 or n.find("feet") != -1:
		return "feet"
	if n.find("joint") != -1 or n.find("spring") != -1 or n.find("bolt") != -1:
		return "joints"
	if n.find("tag") != -1 or n.find("name") != -1 or n.find("plate") != -1:
		return "tag"
	if n.find("body") != -1 or n.find("torso") != -1 or n.find("chest") != -1:
		return "body"
	return "unknown"


func _warn_about_mesh_quality(meshes: Array[MeshInstance3D]) -> void:
	if meshes.size() <= 1:
		print("[IGOR GLB AUDIT] WARNING: Model appears to be a single combined mesh. Per-part material assignment in Godot will be limited. Consider re-exporting from Meshy with separated parts or cleaning in Blender.")

	var generic := 0
	for mi in meshes:
		if _is_generic_name(mi.name):
			generic += 1
	if meshes.size() > 0:
		var r: float = float(generic) / float(meshes.size())
		if r > 0.5:
			print("[IGOR GLB AUDIT] WARNING: Mesh names are generic. Heuristic material assignment may be unreliable. (ratio=", r, ")")


func _is_generic_name(nm: String) -> bool:
	var n := nm.to_lower()
	if n == "object" or n == "mesh" or n == "node" or n == "default":
		return true
	if n.find("gltf") != -1 or n.find("generated") != -1:
		return true
	if n.begins_with("cube") or n.begins_with("cylinder") or n.begins_with("sphere"):
		return true
	return false

func _place_model_on_floor(model_root: Node3D, meshes: Array[MeshInstance3D]) -> void:
	var aabb := _combined_global_aabb(meshes)
	if aabb.size == Vector3.ZERO:
		print("[IGOR GLB AUDIT] WARNING: Could not compute combined bounds for floor placement.")
		return
	var min_y := aabb.position.y
	var max_y := aabb.position.y + aabb.size.y
	var needed_raise := (floor_y + floor_clearance) - min_y
	print("[IGOR GLB AUDIT] --- Floor placement ---")
	print("  - bounds min_y=", min_y, " max_y=", max_y, " size=", aabb.size)
	if min_y < floor_y - 0.001:
		print("[IGOR GLB AUDIT] WARNING: Model is below floor. Raise IgorModelRoot by approximately ", needed_raise)
	if abs(needed_raise) > 0.0005:
		var gp := model_root.global_position
		model_root.global_position = Vector3(gp.x, gp.y + needed_raise, gp.z)
		print("[IGOR GLB AUDIT] Applied model_root global Y offset: ", needed_raise)
	else:
		print("[IGOR GLB AUDIT] No placement adjustment needed.")


func _combined_global_aabb(meshes: Array[MeshInstance3D]) -> AABB:
	var merged := AABB()
	var has := false
	for mi in meshes:
		if mi.mesh == null:
			continue
		var a := _aabb_in_global(mi)
		if not has:
			merged = a
			has = true
		else:
			merged = merged.merge(a)
	return merged if has else AABB()


func _apply_igor_yellow_tuning(meshes: Array[MeshInstance3D]) -> Dictionary:
	# Target “painted ochre” tint. This multiplies albedo textures when present.
	var tint := Color(1.0, 0.74, 0.22, 1.0)
	var tuned_surfaces := 0
	var overridden_mats := 0
	var albedo_tex_found := 0
	var preserved := 0
	var is_single_mesh := meshes.size() <= 1

	for mi in meshes:
		if mi.mesh == null:
			continue
		var sc := mi.mesh.get_surface_count()
		for i in range(sc):
			var mat := _get_material_for_surface(mi, i)
			if mat == null:
				continue
			var part := _classify_mesh(mi.name)
			# Preserve eyes only if we actually have multiple meshes to distinguish.
			if (not is_single_mesh) and part == "eyes":
				preserved += 1
				continue

			if mat is BaseMaterial3D:
				var bm := mat as BaseMaterial3D
				var dup := bm.duplicate(true) as BaseMaterial3D

				# Make the tint clearly visible. If texture exists, this multiplies it (safe, test-only).
				dup.albedo_color = tint
				dup.metallic = clamp(bm.metallic * 0.35, 0.12, 0.2)
				dup.roughness = clamp(max(bm.roughness, 0.78), 0.7, 0.92)
				if dup.get("specular") != null:
					dup.set("specular", clamp(float(dup.get("specular")), 0.35, 0.6))

				if bm.albedo_texture != null:
					albedo_tex_found += 1

				if DEBUG_LOGS:
					print("[IGOR GLB AUDIT] TUNE surface ", i, " on ", mi.name, " | part=", part, " | albedo_color ", bm.albedo_color, " -> ", dup.albedo_color)

				mi.set_surface_override_material(i, dup)
				overridden_mats += 1
				tuned_surfaces += 1
			else:
				# Fallback: if imported material isn't a BaseMaterial3D (e.g. ShaderMaterial),
				# apply a simple painted yellow material so the mode has visible effect.
				var fallback := StandardMaterial3D.new()
				fallback.albedo_color = tint
				fallback.roughness = 0.82
				fallback.metallic = 0.15
				if DEBUG_LOGS:
					print("[IGOR GLB AUDIT] TUNE fallback surface ", i, " on ", mi.name, " | mat_class=", mat.get_class())
				mi.set_surface_override_material(i, fallback)
				overridden_mats += 1
				tuned_surfaces += 1

	return {
		"materials_overridden": overridden_mats,
		"surfaces_tuned": tuned_surfaces,
		"albedo_textures_found": albedo_tex_found,
		"preserved_parts": preserved,
	}


func _apply_strong_yellow_override(meshes: Array[MeshInstance3D]) -> Dictionary:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.7, 0.22, 1)
	mat.roughness = 0.75
	mat.metallic = 0.15
	var count := 0
	for mi in meshes:
		mi.material_override = mat
		if mi.mesh != null:
			var sc := mi.mesh.get_surface_count()
			for i in range(sc):
				mi.set_surface_override_material(i, mat)
		count += 1
	return {"meshes_overridden": count}

func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_meshes(c, out)


func _get_material_for_surface(mi: MeshInstance3D, surface_idx: int) -> Material:
	# Priority: per-surface override -> node material_override -> mesh surface material
	var ov := mi.get_surface_override_material(surface_idx)
	if ov != null:
		return ov
	if mi.material_override != null:
		return mi.material_override
	if mi.mesh != null:
		return mi.mesh.surface_get_material(surface_idx)
	return null


func _print_material_textures(bm: BaseMaterial3D) -> int:
	var count := 0
	count += _print_tex("albedo_texture", bm.albedo_texture)
	count += _print_tex("normal_texture", bm.normal_texture)
	# These may be unused depending on export; still helpful to report.
	count += _print_tex("roughness_texture", bm.roughness_texture)
	count += _print_tex("metallic_texture", bm.metallic_texture)
	# Godot also supports an ORM texture depending on material type; access defensively.
	var orm: Variant = bm.get("orm_texture")
	count += _print_tex("orm_texture", orm)
	return count


func _print_tex(label: String, tex_v: Variant) -> int:
	if tex_v == null:
		return 0
	if tex_v is Texture2D:
		var t := tex_v as Texture2D
		print("    - ", label, ": ", _res_path(t))
		return 1
	return 0


func _res_path(r: Variant) -> String:
	if r == null:
		return ""
	if r is Resource:
		var rr := r as Resource
		return rr.resource_path
	return ""


func _is_near_white(c: Color) -> bool:
	return (c.r > 0.92 and c.g > 0.92 and c.b > 0.92)


func _apply_preview_material(meshes: Array[MeshInstance3D]) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.71, 0.3, 1)
	mat.roughness = 0.6
	mat.metallic = 0.2
	for mi in meshes:
		mi.material_override = mat


func _apply_basic_igor_materials(meshes: Array[MeshInstance3D]) -> void:
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(0.86, 0.71, 0.3, 1)
	yellow.roughness = 0.58
	yellow.metallic = 0.18

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.16, 1)
	dark.roughness = 0.35
	dark.metallic = 0.1

	var joint := StandardMaterial3D.new()
	joint.albedo_color = Color(0.22, 0.2, 0.18, 1)
	joint.roughness = 0.55
	joint.metallic = 0.42

	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.88, 0.48, 0.22, 1)
	bronze.roughness = 0.48
	bronze.metallic = 0.28

	for mi in meshes:
		var n := mi.name.to_lower()
		if n.find("eye") != -1:
			mi.material_override = dark
		elif n.find("antenna") != -1:
			mi.material_override = bronze
		elif n.find("joint") != -1 or n.find("spring") != -1 or n.find("bolt") != -1:
			mi.material_override = joint
		else:
			mi.material_override = yellow

func _aabb_in_global(mi: MeshInstance3D) -> AABB:
	var local := mi.get_aabb()
	var corners := _aabb_corners(local)
	var min_v: Vector3 = Vector3(1e20, 1e20, 1e20)
	var max_v: Vector3 = Vector3(-1e20, -1e20, -1e20)
	for p in corners:
		var g := mi.global_transform * p
		min_v = Vector3(min(min_v.x, g.x), min(min_v.y, g.y), min(min_v.z, g.z))
		max_v = Vector3(max(max_v.x, g.x), max(max_v.y, g.y), max(max_v.z, g.z))
	return AABB(min_v, max_v - min_v)


func _aabb_corners(a: AABB) -> Array[Vector3]:
	var p := a.position
	var s := a.size
	return [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(0, s.y, s.z),
		p + s,
	]

