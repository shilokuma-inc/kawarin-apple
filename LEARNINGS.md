# LEARNINGS — kawarin-apple 固有の知見

このリポジトリだけで役立つ知見（ハマりどころ・API の癖・回避策）を書く。全リポジトリ共通の知見は書かない。

- 該当する見出しの末尾に 1 項目ずつ追記する。既存の行は書き換えない（`merge=union` で並行する追記が両方残る）
- PC 固有の値（ローカルパス・Simulator の UDID など）と秘密情報は書かない

## ビルド・テスト・CI

- Mac アプリ（KawarinMac）は `com.apple.developer.system-extension.install` と App Group の entitlement を持つため、アドホック署名（`CODE_SIGN_IDENTITY=-`、`CODE_SIGNING_REQUIRED=NO` を足しても）の `xcodebuild archive` は 「requires a provisioning profile」で失敗する。ビルドの確認だけなら `CODE_SIGNING_ALLOWED=NO`、Archive はプロファイルを使う署名にする
- 署名せずにビルドした Mac アプリは起動できず、カメラ拡張も有効にできない。画面の見た目だけを確かめるなら、`CODE_SIGN_ENTITLEMENTS=` を空にしてアドホック署名でビルドすると起動できる

## 仮想カメラ（CMIOExtension）

## トラッキング（ARKit・Vision）

## 通信

## モデルの読み込み（VRM・PMX）

## 描画（RealityKit・Metal）

## 物理（spring bone・Bullet）

## App Store・審査
