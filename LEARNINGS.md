# LEARNINGS — kawarin-apple 固有の知見

このリポジトリだけで役立つ知見（ハマりどころ・API の癖・回避策）を書く。全リポジトリ共通の知見は書かない。

- 該当する見出しの末尾に 1 項目ずつ追記する。既存の行は書き換えない（`merge=union` で並行する追記が両方残る）
- PC 固有の値（ローカルパス・Simulator の UDID など）と秘密情報は書かない

## ビルド・テスト・CI

- Mac アプリ（KawarinMac）は `com.apple.developer.system-extension.install` と App Group の entitlement を持つため、アドホック署名（`CODE_SIGN_IDENTITY=-`、`CODE_SIGNING_REQUIRED=NO` を足しても）の `xcodebuild archive` は 「requires a provisioning profile」で失敗する。ビルドの確認だけなら `CODE_SIGNING_ALLOWED=NO`、Archive はプロファイルを使う署名にする
- 署名せずにビルドした Mac アプリは起動できず、カメラ拡張も有効にできない。画面の見た目だけを確かめるなら、`CODE_SIGN_ENTITLEMENTS=` を空にしてアドホック署名でビルドすると起動できる
- CI の macOS の Archive は、App Store Connect API キーの自動署名（`-allowProvisioningUpdates` と `-authenticationKey…`）で通る。Export した pkg は 3rd Party Mac Developer Installer、アプリと拡張は Apple Distribution で署名され、アプリには Mac Team Store のプロファイルが入る。カメラ拡張にはプロファイルが入らない（entitlement が Sandbox と Team ID で始まる App Group だけのため）
- テンプレートの Archive（archive.yml）は一度も動いていないと GitHub に登録されず、`gh workflow run` が 404 になる。ブランチで試すときは、一時的にそのブランチの push を on に足して動かし、試したら消す

## 仮想カメラ（CMIOExtension）

- カメラ拡張の製品の参照（pbxproj の `….CameraExtension.systemextension`）はパスが固定でも、`Configs/Project.xcconfig` の `APP_BUNDLE_IDENTIFIER` を変えれば新しい名前の拡張が埋め込まれる。ただし `xcodebuild … APP_BUNDLE_IDENTIFIER=…` のコマンドラインの上書きには追従せず、「no such file」で失敗する。System Extension はバンドル名を Bundle ID と同じにする必要があるので、製品名は `$(PRODUCT_BUNDLE_IDENTIFIER)` のままにする

## トラッキング（ARKit・Vision）

## 通信

## モデルの読み込み（VRM・PMX）

## 描画（RealityKit・Metal）

## 物理（spring bone・Bullet）

## App Store・審査
