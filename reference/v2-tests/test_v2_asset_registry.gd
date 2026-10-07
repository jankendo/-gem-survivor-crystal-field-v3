extends RefCounted

const V2AssetRegistryScript = preload("res://scripts/systems/V2AssetRegistry.gd")

func run(t) -> void:
	test_manifest_loads_known_asset(t)
	test_missing_v2_asset_falls_back_to_current_source(t)
	test_status_counts_are_available(t)

func test_manifest_loads_known_asset(t) -> void:
	var registry = V2AssetRegistryScript.new()
	t.assert_true(registry.has_asset("weapon.magic_bolt"), "manifest should contain default weapon asset")
	var entry := registry.asset_entry("weapon.magic_bolt")
	t.assert_eq(String(entry.get("category", "")), "weapon_icon", "weapon asset should have weapon_icon category")

func test_missing_v2_asset_falls_back_to_current_source(t) -> void:
	var registry = V2AssetRegistryScript.new()
	var path := registry.resolve_path("weapon.magic_bolt")
	t.assert_true(path.ends_with("magic_bolt.png"), "asset registry should prefer integrated v2 PNG when available")

func test_status_counts_are_available(t) -> void:
	var registry = V2AssetRegistryScript.new()
	var counts := registry.replacement_status_counts()
	t.assert_true(int(counts.get("integrated", 0)) >= 16, "manifest should report integrated P0 assets")
