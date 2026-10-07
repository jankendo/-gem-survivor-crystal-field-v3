extends RefCounted

const JaText = preload("res://scripts/ui/JaText.gd")

const FORBIDDEN = [
	"マージサバイバー防衛線",
	"6×6",
	"6x6",
	"ブロック配置",
	"次ユニット",
	"防衛ライン",
	"砲台",
	"氷結塔",
	"発電塔",
	"防壁"
]

func run(t) -> void:
	test_title_and_help(t)
	test_result_labels(t)

func test_title_and_help(t) -> void:
	var samples = [JaText.TITLE, JaText.SUBTITLE, JaText.HELP_BODY, JaText.CONTROLS]
	for text in samples:
		_assert_no_forbidden(t, String(text), "visible text")
	t.assert_eq(JaText.TITLE, "ジェムサバイバー：クリスタルフィールド", "title should be new")
	t.assert_true(JaText.HELP_BODY.find("ジェムを吸収") >= 0, "help should explain gems")

func test_result_labels(t) -> void:
	var result: ResultView = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	result.show_summary({
		"score": 128450,
		"best_score": 131200,
		"best_delta": 2750,
		"survival_time": 522.0,
		"kills": 1284,
		"level": 18,
		"max_weapon": "星砕きの魔弾",
		"evolved_weapon_count": 1,
		"gems_collected": 932,
		"gem_exp_collected": 1280,
		"max_combo": 52,
		"crystals_destroyed": 4,
		"chests_opened": 2,
		"max_damage": 41,
		"reason": "スライムに囲まれました"
	})
	t.assert_true(_tree_has_text(result, "生存時間：08:42"), "result should show survival time")
	t.assert_true(_tree_has_text(result, "最大武器：星砕きの魔弾"), "result should show max weapon")
	_assert_tree_no_forbidden(t, result, "result")
	result.free()

func _assert_tree_no_forbidden(t, node: Node, context: String) -> void:
	if node is Label:
		_assert_no_forbidden(t, (node as Label).text, context)
	elif node is Button:
		_assert_no_forbidden(t, (node as Button).text, context)
	for child in node.get_children():
		_assert_tree_no_forbidden(t, child, context)

func _assert_no_forbidden(t, text: String, context: String) -> void:
	for word in FORBIDDEN:
		t.assert_true(text.find(word) < 0, "%s should not contain old visible term '%s': %s" % [context, word, text])

func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.find(expected) >= 0:
		return true
	if node is Button and (node as Button).text.find(expected) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false
