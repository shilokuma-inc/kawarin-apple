# LEARNINGS — kawarin-apple 固有の知見

このリポジトリだけで役立つ知見（ハマりどころ・API の癖・回避策）を書く。全リポジトリ共通の知見は書かない。

- 該当する見出しの末尾に 1 項目ずつ追記する。既存の行は書き換えない（`merge=union` で並行する追記が両方残る）
- PC 固有の値（ローカルパス・Simulator の UDID など）と秘密情報は書かない

## ビルド・テスト・CI

## 仮想カメラ（CMIOExtension）

- カメラ拡張の製品の参照（pbxproj の `….CameraExtension.systemextension`）はパスが固定でも、`Configs/Project.xcconfig` の `APP_BUNDLE_IDENTIFIER` を変えれば新しい名前の拡張が埋め込まれる。ただし `xcodebuild … APP_BUNDLE_IDENTIFIER=…` のコマンドラインの上書きには追従せず、「no such file」で失敗する。System Extension はバンドル名を Bundle ID と同じにする必要があるので、製品名は `$(PRODUCT_BUNDLE_IDENTIFIER)` のままにする

## トラッキング（ARKit・Vision）

## 通信

## モデルの読み込み（VRM・PMX）

## 描画（RealityKit・Metal）

## 物理（spring bone・Bullet）

## App Store・審査
