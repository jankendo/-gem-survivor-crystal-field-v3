# Gem Survivor Crystal Field v3 — alpha.3

前回の42件の修正と今回のGameplay UX・図鑑検索／Quest・装備詳細・進化タイミング・重要視覚の修正を含む新しいpreviewです。旧alpha.1のタグ／成果物は変更していません。

このReleaseのWindows／unsigned IPAはRELEASE_MANIFEST.jsonの同一source_commitからビルドされます。公開前に同一main SHAのFast CI／Balance／Performance／Windows／iOS成功を照合し、ZIP・app metadata・arm64・PCK・icons・署名状態とSHAを検査します。

IPAはunsigned / arm64 / Releaseです。通常のiPhoneへ直接インストールできません。利用者自身によるAltStore / Sideloadly / Xcode等の署名が必要です。App Store / TestFlight用ではありません。証明書やprovisioning profileは含みません。

実機の入力感触、VoiceOver／Narrator、持続的GPU性能、thermal、電池、人間の楽しさ・繰り返し遊びたさは **NOT YET VERIFIED ON REAL DEVICE**。自動プレイ・Linux画像・加速負荷は人間／実iPhone測定の代用ではありません。詳細と実行した検証はdocs/qaを参照してください。

English: A new preview built from the immutable source SHA in RELEASE_MANIFEST.json, with validated Windows and unsigned arm64 IPA assets. Your own signing is required; it is not an App Store/TestFlight package. Physical device behavior and human enjoyment are explicitly unverified. No online telemetry or audio was added.

alpha.2の未公開試行はdraft検索APIの不整合で停止しました。空draftだけを取り除き、alpha.2タグは移動していません。draftをRelease IDで取得・検証・公開する修正を含め、alpha.3の同一最終SHAからCIとWindows/iOSを再ビルドします。
