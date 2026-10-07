extends RefCounted

const MANIFEST_PATH = "res://tools/asset_generation_manifest.json"

func run(t) -> void:
	var manifest = JSON.parse_string(FileAccess.open(MANIFEST_PATH, FileAccess.READ).get_as_text())
	t.assert_true(manifest is Dictionary, "asset generation manifest should load")
	t.assert_eq(String(manifest.get("source", "")), "procedural_svg_only_no_external_assets", "assets should be locally generated")
	for category in manifest.get("categories", {}).keys():
		_check_category(t, String(category), manifest["categories"][category])

func _check_category(t, category: String, spec: Dictionary) -> void:
	var data_path = "res://%s" % String(spec.get("data", ""))
	var data = JSON.parse_string(FileAccess.open(data_path, FileAccess.READ).get_as_text())
	t.assert_true(data is Dictionary, "asset data should load: %s" % category)
	var field = String(spec.get("field", "generated_icon"))
	var checked = 0
	if spec.has("array_key"):
		for item in data.get(String(spec.get("array_key", "")), []):
			if item is Dictionary and String(item.get("id", "")) != "":
				_assert_asset(t, category, String(item.get("id", "")), item, field)
				checked += 1
	else:
		var skip: Array = spec.get("skip_keys", [])
		for id in data.keys():
			if skip.has(String(id)) or not (data[id] is Dictionary):
				continue
			_assert_asset(t, category, String(id), data[id], field)
			checked += 1
	t.assert_true(checked > 0, "generated asset category should not be empty: %s" % category)

func _assert_asset(t, category: String, id: String, item: Dictionary, field: String) -> void:
	var path = String(item.get(field, ""))
	t.assert_true(path.begins_with("res://assets/generated/%s/" % category), "generated asset path should be namespaced: %s:%s" % [category, id])
	t.assert_true(FileAccess.file_exists(path), "generated asset should exist: %s" % path)
	if FileAccess.file_exists(path):
		var text = FileAccess.open(path, FileAccess.READ).get_as_text()
		t.assert_true(text.find("<svg") >= 0 and text.find("</svg>") >= 0, "generated asset should be SVG: %s" % path)
