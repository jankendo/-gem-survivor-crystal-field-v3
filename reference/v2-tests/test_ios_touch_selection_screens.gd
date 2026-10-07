extends RefCounted

const TouchSelectionSystemScript = preload("res://scripts/systems/TouchSelectionSystem.gd")
const RuneContractSystemScript = preload("res://scripts/systems/RuneContractSystem.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var options := [
		{"uid": "weapon:magic_bolt", "id": "magic_bolt", "kind": "weapon", "name_ja": "魔弾", "description_ja": "威力UP"},
		{"uid": "passive:power", "id": "power", "kind": "passive", "name_ja": "力", "description_ja": "攻撃UP"},
		{"uid": "contract_skip:skip", "id": "skip", "kind": "contract_skip", "name_ja": "契約しない", "description_ja": "安全を取る"}
	]
	var selection = TouchSelectionSystemScript.new()
	selection.configure(options, 1, 1, true)
	t.assert_eq(selection.select_index(0), "weapon:magic_bolt", "level-up card should select by tap index")
	t.assert_true(selection.request_reroll(), "reroll touch action should work")
	t.assert_true(selection.request_banish(), "banish touch action should work")
	t.assert_true(selection.request_skip(), "skip touch action should work")

	var popup = load("res://scenes/RewardPopup.tscn").instantiate()
	popup._ready()
	popup.show_options(options, {"rerolls": 1, "banishes": 1, "can_skip": true}, true)
	t.assert_true(_find_button(popup, "タップして選択") != null, "reward card should be fully tappable")
	t.assert_true(_find_button(popup, "再抽選") != null, "selection popup should expose reroll")
	t.assert_true(_find_button(popup, "封印") != null, "selection popup should expose banish")
	t.assert_true(_find_button(popup, "スキップ") != null, "selection popup should expose skip")
	popup.free()

	var state = SurvivorStateScript.new()
	state.start_new_run(1201)
	var contracts = RuneContractSystemScript.new()
	var events: Array = []
	t.assert_true(contracts.offer_after_boss(state, events), "contract offer should open")
	t.assert_true(contracts.apply_contract(state, "skip", events), "contract should be skippable by touch")
	t.assert_true(not state.level_up_pending, "contract skip should resume the run")

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
