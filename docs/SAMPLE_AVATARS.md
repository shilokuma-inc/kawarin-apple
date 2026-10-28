# 同梱のサンプルアバター

アプリに同梱している VRoid の公式サンプルアバターと、その利用条件の記録。
ファイルは `KawarinKit/Sources/SampleAvatars/Avatars/`、一覧のコードは `KawarinKit/Sources/SampleAvatars/SampleAvatar.swift`。

## 一覧

| ファイル | タイトル（メタ） | 作者（メタ） | 元の配布物 | 利用条件 | 頂点数 | 大きさ |
| --- | --- | --- | --- | --- | --: | --: |
| `sendagaya-shibu.vrm` | 千駄ヶ谷渋_WSU | VRoidプロジェクト | β Ver AvatarSample_1 | CC0 | 約 79 万 | 19.5MB |
| `victoria-rubin.vrm` | ヴィクトリア・ルービン | VRoidプロジェクト | β Ver AvatarSample_2〜4 のいずれか | CC0 | 約 78 万 | 15.3MB |
| `vita.vrm` | ヴィータ | VRoidプロジェクト | β Ver AvatarSample_2〜4 のいずれか | CC0 | 約 70 万 | 14.2MB |
| `bibi.vrm` | ビビ | VRoidプロジェクト | β Ver AvatarSample_2〜4 のいずれか | CC0 | 約 80 万 | 17.9MB |
| `avatar-sample-a.vrm` | AvatarSample_A | VRoid Project | VRoidPreset | VRoid のプリセットの利用条件 | 約 4 万 | 26.8MB |
| `avatar-sample-b.vrm` | AvatarSample_B | VRoid Project | VRoidPreset | VRoid のプリセットの利用条件 | 約 4.3 万 | 28.3MB |
| `avatar-sample-c.vrm` | AvatarSample_C | VRoid Project | VRoidPreset | VRoid のプリセットの利用条件 | 約 4 万 | 20.0MB |

- 取得元は VRoid Hub（ファイル名は Hub のモデルの ID だったものを、中身が分かる名前に変えた。中身は変えていない）
- 7 体とも VRM 0.x（β は UniVRM-0.44、A〜C は VRoid Studio 1.26.0 の書き出し）。パーフェクトシンクには対応していない
- 表情は neutral・a / i / u / e / o・blink / blink_l / blink_r・angry / fun / joy / sorrow と、custom の Surprised（β は Extra も）。lookAt は Bone、spring bone あり
- メタの利用条件は 7 体とも VRoid Hub の形式（`licenseName: Other`）で、誰でも利用可・法人の商用利用可・クレジット不要・改変可・再配布可

## 利用条件

### β Ver AvatarSample_1〜4（CC0）

- [VRoid のサンプルモデルの利用条件](https://vroid.pixiv.help/hc/en-us/articles/4402614652569)
- 各モデルの記事: [_1](https://vroid.pixiv.help/hc/ja/articles/360012381793)・[_2](https://vroid.pixiv.help/hc/en-us/articles/360014900273)・[_3](https://vroid.pixiv.help/hc/en-us/articles/360014900113)・[_4](https://vroid.pixiv.help/hc/en-us/articles/360014900233)

### AvatarSample_A〜C（VRoidPreset。CC0 ではない）

- [VRoidPreset_A - Z の利用条件](https://vroid.pixiv.help/hc/en-us/articles/4402394424089)
- できること: 商用利用、クレジット無しでの利用、無料での改変と再配布
- できないこと: 有料での再配布、利用条件を CC0 に書き換えて配ること、キャラクター作成サービスへの流用、pixiv が推奨しているように見せること
- 公式は「今後、条件を絞ることがある」としているので、リリースの前に利用条件のページを見直す

## 守ること

- VRM のメタの利用条件は書き換えない（A〜C を CC0 として配ることになるため）
- AvatarSample_A〜C は有料の機能（App 内課金）の対象に入れず、無料で使える範囲に置く。コードでは `SampleAvatar.mustStayFree` が `true` になっている
- App Store のスクリーンショット・掲載文・アプリの文言で、pixiv や VRoid が推奨・提携しているように見せる書き方をしない
- クレジットは不要だが、アプリの「ライセンス」画面には出典（VRoid の公式サンプルであること）を載せる（配信の準備で作る）

## 気をつけること

- 7 体とも VRM 0.x なので、Phase 1 で VRM 0.x の読み込み（1.0 相当への変換）が要る（docs/DESIGN.md の「17. 開発の進め方」）
- β の 4 体は 70〜80 万頂点ある（髪が多い）。iPhone の鏡モードと visionOS で性能を確かめる対象にし、重ければ頂点を減らした版に差し替える
- 合計で約 137MB あり、アプリの大きさに直接効く。テクスチャの縮小などの最適化は後で検討する
- ファイルは Git LFS を使わず、普通に git にコミットしている（LFS の帯域の無料枠を CI の clone で使わないため）。差し替えると履歴に古い版も残るので、差し替えは必要なときだけにする
