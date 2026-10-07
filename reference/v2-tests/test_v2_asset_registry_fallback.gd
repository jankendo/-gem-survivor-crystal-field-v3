extends RefCounted

const V2AssetRegistryScript = preload("res://scripts/systems/V2AssetRegistry.gd")

func run(t) -> void:
	test_missing_preferred_uses_fallback(t)
	test_texture_resolution_is_cached(t)

func test_missing_preferred_uses_fallback(t) -> void:
	var manifest := {
		"assets": [
			{
				"asset_id": "test.weapon",
				"category": "weapon_icon",
				"preferred_path": "res://assets/v2/missing/not_here.png",
				"fallback_path": "res://assets/generated/weapons/magic_bolt.svg",
				"replacement_status": "integrated"
			}
		]
	}
	var path := "user://v2_asset_registry_fallback.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest))
	file = null
	var registry = V2AssetRegistryScript.new(path)
	t.assert_true(registry.resolve_path("test.weapon").ends_with("magic_bolt.svg"), "registry should use fallback when preferred is missing")

func test_texture_resolution_is_cached(t) -> void:
	var registry = V2AssetRegistryScript.new()
	var first = registry.resolve_texture("ui.momentum_badge")
	var second = registry.resolve_texture("ui.momentum_badge")
	t.assert_true(first != null, "registry should load a texture for integrated UI asset")
	t.assert_eq(registry.texture_cache.size(), 1, "registry should cache texture by resolved path")
	t.assert_true(first == second, "registry should return cached texture")
