# Gem Survivor Crystal Field v3 — alpha.1

固定60Hz simulation、敵SoA、共有spatial query、central status/damage、所持武器runtimeとv3 saveへ再構築した探索サバイバーのalphaです。特殊武器、名前付きOverclock、6イベント、Quest/Shop条件を接続し、Windowsとunsigned arm64 IPAを実ビルドしました。

Release作成前に同一main SHAのFast CI・Balance・Performance・Windows/iOS build成功を検証し、添付ZIP/IPAを再検証します。SHA256SUMS.txtで添付ファイルを確認できます。

unsigned IPAは通常のiPhoneへ直接installできません。利用者自身がAltStore / Sideloadly / Xcodeなどで署名してください。App Store / TestFlight用ではありません。証明書・provisioning profileは含みません。

**NOT YET VERIFIED ON REAL DEVICE**: 人間プレイの面白さ、interactive Windows、実iPhone/iPadへのinstall、touch latency、15/30分thermal、Low Power Mode、battery。Headless CPUの性能をiPhone性能とは扱いません。

公開先repository名の先頭にハイフンがあります。指定されたハイフンなしrepositoryは404で、integrationのrename/createは403です。v2 sourceは読み取り専用、baseline b9b70807492b673a6836eb6beafe8823f71e6672。完全な品質ゲートと制約はdocs/qaを参照してください。

English: This is an alpha preview with successful immutable-main CI and validated Windows/unsigned arm64 iOS binaries. The IPA requires your own signing and is not for direct iPhone installation, App Store or TestFlight. Human enjoyment, interactive desktop play and sustained real iPhone/iPad behavior have not been verified. Linux headless timings are not iPhone measurements. The public repository currently has a leading hyphen; renaming is blocked by integration permissions. Source v2 is unchanged.
