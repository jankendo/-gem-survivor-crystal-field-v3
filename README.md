# Gem Survivor Crystal Field v3

結晶迷宮を探索し、敵を倒してジェムを回収し、武器・Passive・進化・連携でビルドを完成させるGodot製サバイバー。

![Gameplay — Linux llvmpipe capture](docs/qa/evidence/gameplay.png)

**作業中のalphaです。完成ゲート未達。** GitHub新規repo作成が認証済みjankendoへのHTTP403で拒否され、push/Actions/Releaseは実行できていません。Windows exportとiOS Xcode projectはローカル生成できますが、macOSでのunsigned app/IPAビルドは未実行です。

探索 → 撃破 → ジェム → 成長 → Evolution / Combo → 危険報酬 → Boss。5/10/15分にボス、15分ボス撃破でCLEAR。その後終了またはEndlessを継続できます。

Windows: WASD / 矢印で移動、攻撃は自動。マウスで成長選択、Escでポーズ、1〜3で成長選択。UIボタンで倍速・ワープ・採掘。iOS: 左側の動的スティックで移動、全選択はタッチ。横画面・Safe Areaを基準とします。

v3は60Hz固定simulation、世代ID付き敵SoA、共有SpatialWorld、Status/Damage所有者、所持武器runtime、起動時GameDatabase、scene UI、v3 atomic saveを導入します。Ultraはworld解像度・装飾だけを変更します。v2由来の名称・アセット・レシピを保持していますが、全特殊挙動・全コンテンツの互換性はまだ保証しません。

Godot **4.7 stable** / GDScript / **gl_compatibility**。完全無音。外部著作物は追加していません。

```sh
export GODOT=/path/to/Godot_v4.7-stable_linux.x86_64
python tools/validate_data.py
python tools/run_godot.py --headless --editor --path . --quit
python tools/run_godot.py --headless --path . --script res://tests/test_runner.gd
python tools/run_godot.py --headless --path . --script res://tests/test_runner.gd -- --category=deterministic
python tools/run_godot.py --headless --path . --script res://tests/benchmark.gd -- --mode=balance
python tools/run_godot.py --headless --path . --script res://tests/benchmark.gd -- --mode=performance
"$GODOT" --path .
```

Install matching Godot export templates, then export:

```sh
mkdir -p builds/windows builds/ios-export
"$GODOT" --headless --path . --export-release "Windows Desktop" builds/windows/GemSurvivorCrystalFieldV3.exe
"$GODOT" --headless --path . --export-release iOS builds/ios-export/GemSurvivor.ipa
```

Windows artifact: `GemSurvivorCrystalField-v3-Windows.zip` contains EXE with embedded PCK and README. iOS artifact: `GemSurvivorCrystalField-v3-unsigned.ipa` requires macOS/Xcode after project export. See [unsigned IPA instructions](IOS_UNSIGNED_README.md): it needs user signing and is not for direct normal-iPhone installation, App Store or TestFlight.

CI workflows separate fast, balance, performance and release. Release validators check real archives and generate SHA-256. Workflow existence is not evidence of successful Actions runs.

See [architecture](docs/ARCHITECTURE.md), [design](docs/GAME_DESIGN.md), [balance](docs/BALANCE.md), [performance](docs/PERFORMANCE.md), [migration](docs/migration/V2_TO_V3.md) and [QA plan](docs/qa/TEST_PLAN.md). Human fun/physical iPhone/thermal/battery/Windows execution remain unverified. Source has no LICENSE; the rights notice does not invent reuse permission.
