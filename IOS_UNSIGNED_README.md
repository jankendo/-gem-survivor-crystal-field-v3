# Gem Survivor Crystal Field v3 — unsigned iOS IPA

## 日本語

成果物名は `GemSurvivorCrystalField-v3-unsigned.ipa`。未署名ビルドであり、通常のiPhoneへそのままインストールできません。AltStore / Sideloadly / Xcode等で、利用者自身のAppleアカウントによる署名が必要です。App Store / TestFlight配布用ではありません。

Apple証明書、秘密鍵、Provisioning Profileはリポジトリに含めません。CIは `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM=""` でRelease/iphoneos/arm64をビルドします。

Godot 4.7はproject-only exportでもTeam IDが空だと拒否するため、presetには非秘密の仮値 `ABCDE12345` を置きます。Xcode buildでは空のDEVELOPMENT_TEAMを明示して署名を無効化します。実際のTeam Secretは不要です。

Bundle IDは既存作品と同じ `com.jankendo14.gemsurvivor`、表示名は `Gem Survivor Crystal Field v3`、versionは `3.0.0`。同一bundleのためv2との同時インストール用ではありません。

Linux上でXcode project生成は可能ですが、完成IPAにはmacOS/Xcodeが必要です。本作業環境ではGitHub repository作成権限が403で拒否され、Actionsを起動できません。実ビルド・実機署名・インストール成功は未検証です。

## English

`GemSurvivorCrystalField-v3-unsigned.ipa` is unsigned. It cannot be installed directly on a normal iPhone. Users must sign it themselves with AltStore, Sideloadly or Xcode and their own Apple account. It is not an App Store or TestFlight distribution build.

No Apple certificate, private key or provisioning profile belongs in this repository. The non-secret placeholder Team ID only satisfies Godot's project export validation; xcodebuild explicitly disables signing and clears DEVELOPMENT_TEAM. No Developer Team secret is requested.

The preserved bundle identifier is `com.jankendo14.gemsurvivor`. Actual unsigned app compilation, IPA validation and physical-device installation remain unverified without macOS execution access. A generated Xcode project is not a generated IPA.
