# Gem Survivor Crystal Field v3

結晶迷宮を探索し、敵を倒してジェムを回収し、武器・Passive・進化・連携でビルドを完成させるGodot製サバイバー。

![Gameplay — Linux llvmpipe capture](docs/qa/evidence/gameplay.png)

**公開alphaです。人間実機の品質ゲートは未達です。** 全履歴を維持してGitHubへpushし、Fast CI・Balance・Performance・Windows/iOS Release buildを実行しています。実際のWindows ZIPとunsigned arm64 IPAを生成・検証済みです。

現在アクセス可能なPUBLIC repositoryは [jankendo/-gem-survivor-crystal-field-v3](https://github.com/jankendo/-gem-survivor-crystal-field-v3) です。先頭にハイフンがあります。指定されたハイフンなしURLは404で、認証済みintegrationによるrepository rename/createは403です。v2へwriteしていません。

探索 → 撃破 → ジェム → 成長 → Evolution / Combo → 危険報酬 → Boss。5/10/15分にボス、15分ボス撃破でCLEAR。その後終了またはEndlessを継続できます。

Windows: WASD / 矢印で移動、攻撃は自動。マウスで成長選択、Escでポーズ、1〜3で成長選択。UIボタンで倍速・ワープ・採掘。iOS: 左側の動的スティックで移動、全選択はタッチ。横画面・Safe Areaを基準とします。

v3は60Hz固定simulation、世代ID付き敵SoA、共有SpatialWorld、Status/Damage所有者、所持武器runtime、起動時GameDatabase、scene UI、v3 atomic saveを導入します。Ultraはworld解像度・装飾だけを変更します。v2由来の名称・アセット・レシピを保持していますが、特殊武器の追尾・反射・吸引・設置・採掘、20種類の名前付きOverclock、6イベント、17Questと購入条件を接続しました。詳細なv2との再設計差分はmigration資料を参照してください。

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

CI workflows separate fast, balance, performance and release. Release validators check real archives and generate SHA-256. 実行済みrunの証拠と制約は [completion gate](docs/qa/COMPLETION_GATE.md) に記録します。

See [architecture](docs/ARCHITECTURE.md), [design](docs/GAME_DESIGN.md), [balance](docs/BALANCE.md), [performance](docs/PERFORMANCE.md), [migration](docs/migration/V2_TO_V3.md) and [QA plan](docs/qa/TEST_PLAN.md). Windows runnerでEXE/PCKのheadless起動を検証しています。Human fun・physical iPhone/iPad・thermal/battery・interactive Windows play remain unverified. Source has no LICENSE; the rights notice does not invent reuse permission.
