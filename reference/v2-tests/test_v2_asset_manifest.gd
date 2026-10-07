extends RefCounted

const V2AssetRegistryScript = preload("res://scripts/systems/V2AssetRegistry.gd")

var required_assets := [
	"character.noah",
	"enemy.slime",
	"enemy.bat",
	"enemy.golem",
	"boss.boss_5",
	"weapon.magic_bolt",
	"weapon.ice_orbit",
	"passive.move_speed",
	"passive.magnet",
	"evolution.starbreaker_bolt",
	"biome.star_plain",
	"ui.title_key_visual",
	"ui.primary_crystal_panel",
	"ui.reward_card_frame",
	"ui.momentum_badge",
	"ui.boss_alert_frame"
]

func run(t) -> void:
	test_p0_manifest_entries_resolve_to_integrated_assets(t)
	test_manifest_fields_are_complete(t)

func test_p0_manifest_entries_resolve_to_integrated_assets(t) -> void:
	var registry = V2AssetRegistryScript.new()
	for asset_id in required_assets:
		t.assert_true(registry.has_asset(asset_id), "manifest should contain P0 asset %s" % asset_id)
		var entry := registry.asset_entry(asset_id)
		t.assert_eq(String(entry.get("replacement_status", "")), "integrated", "P0 asset should be integrated: %s" % asset_id)
		var path := registry.resolve_path(asset_id)
		t.assert_true(path.begins_with("res://assets/v2/"), "P0 asset should resolve to v2 preferred path: %s -> %s" % [asset_id, path])
		t.assert_true(ResourceLoader.exists(path) or FileAccess.file_exists(path), "resolved P0 asset should exist: %s" % path)

func test_manifest_fields_are_complete(t) -> void:
	var registry = V2AssetRegistryScript.new()
	for asset_id in required_assets:
		var entry := registry.asset_entry(asset_id)
		for key in ["asset_id", "category", "display_name", "preferred_path", "fallback_path", "target_resolution", "aspect_ratio", "transparent", "usage", "priority", "replacement_status", "style_profile", "prompt_document", "checksum_optional"]:
			t.assert_true(entry.has(key), "manifest entry should include %s for %s" % [key, asset_id])
