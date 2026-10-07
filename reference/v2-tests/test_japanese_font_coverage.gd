extends RefCounted

func run(t) -> void:
	var sample := "ひらがな カタカナ 常用漢字 三点リーダ… 長音ー × ％ ＋ －"
	t.assert_true(sample.length() > 0, "Japanese coverage sample should be nonempty")
	t.assert_true(sample.find("×") >= 0 and sample.find("…") >= 0, "coverage sample should include required full-width symbols")
