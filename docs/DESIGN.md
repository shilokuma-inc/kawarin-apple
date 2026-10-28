# かわりん -Kawarin- 設計

iPhone / iPad のカメラで顔・上半身・手を追い、Mac 上の 3D アバター（VRM / MMD）を動かして、
Mac の仮想カメラとして Zoom・Discord・ブラウザなどに出すアプリ。
「会議に代わりに出てくれる、かわいい子」がコンセプト。

この文書は設計の正本。決定事項を変えたら、ここと関係する Issue / Discussion を合わせて更新する。

## 1. 決定事項

| 項目 | 決定 |
| --- | --- |
| 対応プラットフォーム | iOS / iPadOS（トラッカー）、macOS（描画と仮想カメラ）。visionOS は将来追加する |
| 配布 | App Store。iOS と macOS を同じ Bundle ID（`jp.shilokuma.Kawarin`）で出す（Universal Purchase） |
| 価格 | 無料。今後の新機能を App 内課金にする。最初に無料で出した機能は後から有料にしない |
| 最低 OS | iOS 18 / iPadOS 18 / macOS 15 / visionOS 2 |
| 対応 Mac | Apple Silicon のみ（arm64 だけでビルドする） |
| 言語・配信地域 | なるべく多言語、全世界に配信する（「15. 多言語」） |
| 主な用途 | 会議。配信（OBS・VTuber 活動）にも使えるようにする |
| アバター | VRM 0.x / 1.0 と MMD（PMX）。MMD の揺れものは Bullet で再現する |
| トラッキング | MVP で顔・上半身・両手。iPhone / iPad の前面カメラ 1 台で取る |
| iOS 単体モード | 鏡のようにアバターを表示するだけ（録画・写真は入れない） |
| 描画 | RealityKit に統一する（visionOS と共通化するため） |
| CI | テスト・ビルドから TestFlight へのアップロードまで GitHub Actions。Xcode Cloud は使わない |
| サンプルアバター | VRoid の公式サンプル 7 体（β Ver AvatarSample の CC0 の 4 体と、AvatarSample_A〜C）を同梱する（[docs/SAMPLE_AVATARS.md](SAMPLE_AVATARS.md)） |

## 2. 全体構成

```
[iPhone / iPad: トラッカー]
  前面カメラ 1 台で
   ├ ARKit の顔トラッキング（60fps）: 表情 52 値・頭・視線
   └ 同じ映像に Vision（30fps）: 上半身の 3D 関節・両手の 21 点
  → 観測した値をそのまま送る（アバターへの当てはめはしない）
  （鏡モード: 共通エンジンで自分のアバターを表示）
        │  Network.framework（AWDL 可）・DTLS
        ▼
[Mac: 本体]                                  [Vision Pro: 将来]
  共通エンジン                                 共通エンジン（同じコード）
   受信 → 補間 → 当てはめ（表情・IK・指）       → RealityView で空間に表示
   → 物理（spring bone / Bullet）
   → 変形（Metal compute → LowLevelMesh）
   → RealityKit（RealityRenderer で画面外に描画）
   → CVPixelBuffer → sink stream
        │
        ▼
[Mac: カメラ拡張（CMIOExtension、別プロセス）]
  sink stream で受け取る → source stream で配信 → Zoom / Discord / ブラウザ
```

- トラッカーは観測値だけを送り、アバターの体格に合わせた当てはめは受け手で行う。受け手が Mac でも Vision Pro でも同じ処理を使える
- 描画は Mac で行う。iPhone は発熱と電池がもたず、映像のエンコード・デコードを挟まないほうが遅延も小さい

## 3. ターゲットと配布

| ターゲット | プラットフォーム | Bundle ID | 役割 |
| --- | --- | --- | --- |
| `Kawarin` | iOS / iPadOS | `jp.shilokuma.Kawarin` | トラッカーと鏡モード |
| `KawarinMac` | macOS | `jp.shilokuma.Kawarin` | 描画と仮想カメラへの出力（ネイティブの macOS アプリ。Mac Catalyst は使わない） |
| `KawarinCameraExtension` | macOS | `jp.shilokuma.Kawarin.CameraExtension` | カメラ拡張（System Extension） |
| （将来）visionOS | visionOS | `jp.shilokuma.Kawarin` | ビューアーなど。役割は後で決める |

- Universal Purchase: App Store Connect の 1 つのアプリに iOS と macOS のプラットフォームを登録する。価格と App 内課金は全プラットフォーム共通
- Universal Purchase にするため、Mac 版も Mac App Store で配る。カメラ拡張は Mac App Store で配布でき、App Sandbox が必須
- 審査はプラットフォームごと。単体で役に立たないと「最低限の機能（4.2）」「完成度（2.1）」で指摘されうるので、
  iOS 版は鏡モード、Mac 版は待機モーションと表情のショートカットキーだけでも使えるようにする。審査メモにデモ動画と接続手順を付ける
- App Store Connect の「iPhone と iPad の App を Apple Silicon Mac で配信」と「Apple Vision Pro で配信」は外す
  （iPad 版がそれぞれで互換アプリとして配信されないように。Vision Pro では ARKit の顔トラッキングが動かない）

## 4. パッケージ構成と依存のルール

ローカルの Swift Package（`KawarinKit`）に、プラットフォームに依存しないコードを置く。

| モジュール | 中身 | iOS | macOS | visionOS |
| --- | --- | :-: | :-: | :-: |
| `AvatarCore` | 共通モデル（骨格・メッシュ・モーフ・材質パラメータ）、姿勢計算（FK・付与・IK） | ✓ | ✓ | ✓ |
| `AvatarFormats` | VRM 0.x / 1.0 と PMX の読み込み、モデルの取り込み（ファイル・フォルダ・zip） | ✓ | ✓ | ✓ |
| `AvatarMotion` | 当てはめ（表情・上半身・腕の IK・指）、平滑化、待機モーション | ✓ | ✓ | ✓ |
| `AvatarPhysics` | VRM の spring bone（Swift）、MMD 物理（Bullet） | ✓ | ✓ | ✓ |
| `AvatarRendering` | 変形の compute シェーダー、RealityKit のエンティティ組み立て、ShaderGraph の材質 | ✓ | ✓ | ✓ |
| `TrackingProtocol` | 送受信の形式、発見・ペアリング・暗号化、VMC Protocol の受信 | ✓ | ✓ | ✓ |
| `TrackingCaptureIOS` | ARKit と Vision による観測 | ✓ | | |
| `VirtualCameraHost` | RealityRenderer → CVPixelBuffer → sink stream | | ✓ | |

- `AvatarCore` / `AvatarFormats` / `AvatarMotion` / `AvatarPhysics` は Swift と `simd` だけで書く。UIKit・AppKit・ARKit・RealityKit を import しない。
  Mac の単体テストで検証でき、描画の方式を後から変えても影響を受けない
- RealityKit を使うのは `AvatarRendering` だけ
- プラットフォーム固有の API（ARKit・CoreMediaIO など）はプロトコルの後ろに隠し、テストと Simulator では差し替える
- 依存ライブラリは SPM で入れられるものに限り、GPL のものは使わない

## 5. iPhone / iPad（トラッカー・鏡モード）

### 5.1 観測

| 対象 | 方法 | 頻度 |
| --- | --- | --- |
| 顔 | ARKit `ARFaceTrackingConfiguration`。表情 52 値（`blendShapes`）、頭の姿勢（カメラ基準に変換）、両目の向き | 60fps |
| 上半身 | `ARFrame.capturedImage` に `VNDetectHumanBodyPose3DRequest`（肩・肘・手首・背骨・頭の 3D 座標、メートル） | 30fps |
| 手 | 同じ映像に `VNDetectHumanHandPoseRequest`（片手 21 点の 2D と左右）。手首は上半身の 3D から取り、指は 2D と TrueDepth の深度（`capturedDepthData`）から 3D を推定する | 30fps |

- 手の推定は `HandPoseEstimator` プロトコルで差し替えられるようにする。Vision で指の精度が足りなければ MediaPipe Hand Landmarker と比べる（SPM で入れられるかも含めて）
- 発熱したら（`thermalState`）上半身・手の頻度から先に落とす（30 → 15fps）。顔は最後まで 60fps を保つ
- ARKit はバックグラウンドで止まるので前面に出しておく。スリープさせず（`isIdleTimerDisabled`）、画面を暗くするモードを用意する
- 対応端末は ARKit の顔トラッキングに対応する全機種。TrueDepth が無い機種では指の 3D 推定が弱くなることをアプリ内で知らせる

### 5.2 置き方とモード

- 「顔のみ」と「上半身＋手」を切り替えられる。顔のみなら iPhone を近くに置けて表情の精度が上がる
- 上半身＋手は、横向きでスタンドに立てて 60〜80cm 前に置く。カメラ映像に骨格を重ね、頭・肩・手が入っているかを示す

### 5.3 キャリブレーション

- 正面を向いた無表情を記録し、頭の向きと表情の基準値を差し引く（`(v - base) / (1 - base)` で 0〜1 に戻す）
- 両腕を横に広げた姿勢を記録し、本人の肩幅と腕の長さを測る

### 5.4 鏡モード

- 共通エンジンを iPhone 上で動かし、`RealityView` に左右反転で表示する（visionOS 版の描画の先行検証も兼ねる）
- 30fps。Mac に送っている間は止める
- モデルは「ファイル」アプリから取り込む（「9. モデルの読み込み」）。Mac からモデルを送る機能は後回し

## 6. 通信

### 6.1 発見・接続

- Mac が `NWListener` で Bonjour のサービス（`_kawarin._udp`）を公開し、iPhone が `NWBrowser` で見つける
- `includePeerToPeer` を有効にする。Apple 端末どうしの直接通信（AWDL）で、同じ Wi-Fi にいなくても、社内 Wi-Fi で端末どうしの通信が止められていてもつながる
- USB 接続は扱わない（Mac App Store のサンドボックスから usbmuxd を使えない見込みのため）

### 6.2 ペアリングと暗号化

- 目的は 2 つ。同じネットワークの他人の iPhone から自分のカメラを動かされないこと、顔のデータを平文で流さないこと
- 初回のペアリングは、Mac で「iPhone を追加」を押してから 2 分間だけ受け付ける
- iPhone と Mac で X25519 の鍵交換を行い、交換した内容から計算した 6 桁の確認コードを両方の画面に出す。
  利用者が一致を確かめて **Mac で「許可」を押したときだけ** ペアリングが成立する（Bluetooth の数字比較と同じ考え方）
- 拒否・コードの不一致・時間切れが 3 回続いたら受け付けを締め切る。もう一度「iPhone を追加」を押すまで受け付けない
- 成立したら、鍵交換から導いた 32 バイトの鍵を両方のキーチェーンに保存する。以降はこの鍵を事前共有鍵にした DTLS で自動接続する。
  Mac の設定画面でペアリングした端末を一覧し、取り消せるようにする
- 6 桁のコードそのものを事前共有鍵にはしない。通信を記録されると、手元で 100 万通りを総当たりして鍵を割り出せてしまうため
- OS 標準の暗号だけを使うので、輸出規制は免除の扱い（`ITSAppUsesNonExemptEncryption = NO`）

### 6.3 パケット

すべてリトルエンディアンの固定長。1 パケットは 1,200 バイト以内（IP のフラグメントを避ける）。

| 種類 | 頻度 | 中身 | 大きさ |
| --- | --- | --- | --- |
| 顔 | 60Hz | magic / version、sequence、timestamp（`ARFrame.timestamp`）、flags、頭の回転（クォータニオン）と位置、両目の回転、表情 52 値（Float16、並びはアプリ側の固定の表） | 約 200 バイト |
| 体 | 30Hz | 共通ヘッダー、上半身の関節（約 10 点 × 3D × 信頼度）、両手（21 点 × 3D × 信頼度、左右） | 約 400 バイト |

- 座標はカメラから見た座標。将来 Vision Pro の手（27 関節）を送るときも 21 点に変換すれば同じ処理で扱える
- 受け手は時刻付きでためて 1 フレームほど遅らせて補間する。古い sequence は捨てる。0.5 秒途切れたらトラッキングなしとして扱う
- 受け取った値は信用しない入力として扱う（長さ・範囲・NaN を確かめる）
- 既存の iPhone アプリ（Waidayo など）でも試せるよう、Mac は VMC Protocol（OSC）も受けられるようにする

## 7. 当てはめ（`AvatarMotion`）

### 7.1 表情

| モデル | 割り当て |
| --- | --- |
| パーフェクトシンク対応の VRM（ARKit と同名の表情を持つ） | 52 値をそのまま 1:1 |
| 通常の VRM | プリセットへ変換（例: `eyeBlinkLeft`→`blinkLeft`、`jawOpen`→`aa`、`mouthFunnel`→`oh`、`mouthPucker`→`ou`、`mouthSmile`→`happy`） |
| MMD | モーフ名の既定の表（まばたき・あ・い・う・え・お・笑い など）。モデルごとに UI で調整する |

- 割り当てごとにゲイン・オフセット・上限を持ち、モデルファイルのハッシュごとに保存する
- ARKit の Left は本人の左。鏡写しの設定に合わせて左右を入れ替える
- 視線: VRM は `lookAt`（bone 型は目の骨、expression 型は `lookUp` などの表情。rangeMap で制限）、MMD は「両目」（無ければ左目・右目）

### 7.2 体

- 基本姿勢が違う（VRM は T ポーズ、MMD はおおむね A ポーズ）ので、回転を写さず、骨の向きをワールド空間で目標に合わせる
- 頭: 回転を首 40%・頭 60% に分ける
- 背骨・胸: 肩を結ぶ線の傾きと頭の位置から求め、背骨・胸・上胸（MMD は上半身・上半身2）に分ける
- 腕: 手首の目標を「肩からの相対位置 × アバターの腕の長さ / 本人の腕の長さ」で求め、2 ボーンの IK で解く。肘の向きは観測した肘を使う。ひねりは MMD の腕捩・手捩に分ける
- 手首: 手のひらの面（手首・人差し指の付け根・小指の付け根）から求める
- 指: 関節ごとの曲げ角度を求め、可動範囲に制限して VRM の humanoid の指ボーンと MMD の指ボーン（親指０〜２・人指１〜３ など）に当てる
- めり込み防止: 肘と手首の目標を胴体のカプセルの外に押し出す

### 7.3 平滑化と見失ったとき

- 頭と関節は One Euro Filter。まばたきは平滑化を弱くする
- 部位ごとに信頼度で重みを付ける。見失ったら 0.2 秒は直前の姿勢を保ち、0.3〜0.5 秒かけて待機姿勢に戻す。画面の端に近い手は重みを下げる
- トラッキングが途切れたら、無表情に戻して自動のまばたきと呼吸（上半身の小さな上下）を足す

## 8. 共通モデルと座標系（`AvatarCore`）

- 右手系・Y 軸が上・メートル単位（glTF・RealityKit と同じ）
- VRM 1.0 は +Z、VRM 0.x は -Z が正面。0.x は Y 軸まわりに 180° 回して揃える
- MMD は左手系で 1 単位がおよそ 8cm。読み込み時に Z を反転して 0.08 倍し、面の巻き順も反転する
- 人型の骨は VRM の humanoid の名前を共通名にし、MMD は骨の名前（頭・首・上半身2・両目 など）から対応付ける

## 9. モデルの読み込み（`AvatarFormats`）

### 9.1 VRM

| VRM 1.0 | VRM 0.x | 用途 |
| --- | --- | --- |
| `VRMC_vrm` | `VRM`（humanoid・blendShapeMaster・meta） | 骨・表情・視線・利用条件 |
| `VRMC_springBone` | `VRM.secondaryAnimation` | 揺れもの |
| `VRMC_materials_mtoon` | `VRM.materialProperties` | トゥーン材質 |

- GLB は自前で読み、拡張の JSON は `Codable` で読む
- 0.x は読み込み時に 1.0 相当へ変換する（表情名 `A`→`aa`、`Joy`→`happy`、MToon の旧パラメータ）。three-vrm の移行処理を参考にする
- 表情は「モーフの組み合わせ ＋ 材質の色・UV の変化」。`isBinary` と `overrideBlink` / `overrideLookAt` / `overrideMouth` も実装する

### 9.2 MMD（PMX）

- PMX 2.0 / 2.1（PMD は後回し）。文字コード（UTF-16LE / UTF-8）と、1・2・4 バイトの可変長インデックスに対応する
- 骨: 付与（付与親の回転・移動）は必須（左目・右目が「両目」から付与で動くモデルが多い）。IK と「物理後変形」にも対応する
- モーフ: 頂点・グループ・材質（頬染めなど）を先に、ボーン・UV を後に
- 材質: 拡散色・反射色・環境色、テクスチャ、スフィアマップ（乗算・加算）、トゥーン（共有 toon01〜10 か個別）、輪郭線、両面描画。描画順は材質の並び順
- 共有トゥーンテクスチャは MMD 本体の同梱物なので同梱しない。同じ役割の画像を自作する

### 9.3 取り込み

- VRM ファイル、PMX の入ったフォルダ、zip を取り込める。zip は ZIPFoundation などで展開し、Shift_JIS のファイル名が文字化けしないようにする
- テクスチャのパスは区切り文字 `\` と大文字・小文字の違いを吸収する
- モデルファイルは信用しない入力として扱う（巨大なファイル・範囲外のインデックス・zip の外を指すパス）
- 取り込んだモデルはアプリのコンテナに写す。`fileImporter` と security-scoped bookmark を使う（3 プラットフォーム共通）

### 9.4 利用条件

- VRM の meta（利用条件）と PMX のコメント欄を読み込み時に表示し、同意してから使う
- 禁止の条件があっても止めずに警告にする（作者本人かどうかをアプリでは判断できないため）

## 10. 物理（`AvatarPhysics`）

### 10.1 VRM

- VRM 1.0 の spring bone の仕様どおり（Verlet 積分、stiffness・drag・gravity、球とカプセルの当たり判定）。0.x の secondaryAnimation も同じ処理に変換する

### 10.2 MMD（Bullet）

- Bullet の `LinearMath` / `BulletCollision` / `BulletDynamics` を SPM の C++ ターゲットにする（zlib ライセンス）
- Swift からは薄い C の API（`extern "C"`）で呼ぶ。C++ 相互運用の設定が依存するモジュールすべてに波及するのを避ける
- PMX の剛体（球・箱・カプセル、質量・減衰・反発・摩擦、16 の衝突グループ）とジョイント（`btGeneric6DofSpringConstraint`）をそのまま写す。
  モード 0（ボーン追従）はキネマティック、1（物理演算）と 2（物理演算＋ボーン位置合わせ）は動的
- MMD の単位のまま計算し、結果の骨の姿勢だけを共通の座標系に変換する（作者が MMD で調整した揺れ方を再現するため）。three.js の MMDPhysics を参考にする
- 1 フレームの順番: FK → 物理より前の付与・IK → ボーン追従の剛体を骨に合わせる → 物理を進める（1/60 秒の固定ステップ）→ 動的な剛体を骨に戻す → 物理後変形の骨 → スキニング行列
- 物理のリセット（剛体を骨の位置に戻して速度 0）: 読み込み時（その後 30 ステップ空回し）、頭が 1 フレームで大きく動いたとき、トラッキングの復帰時

## 11. 描画（`AvatarRendering`）

- 描画は RealityKit に統一する。visionOS では `CustomMaterial` が使えず ShaderGraph しか使えないため
- 変形: Metal の compute シェーダーでモーフ（頂点・UV。重みが 0 でないものだけ）とスキニング（BDEF1/2/4・SDEF。QDEF は BDEF4 で近似）を計算し、
  `LowLevelMesh` の頂点バッファに直接書く。RealityKit の骨格・ブレンドシェイプは使わない
- テスト用に CPU 版の参照実装も持つ（CI の仮想マシンで GPU が使えない場合がある）
- 材質は Reality Composer Pro の ShaderGraph で作る

| 材質 | 作り方 |
| --- | --- |
| MToon | Unlit Surface をもとに自前のトゥーンライティング（光の向きと色を材質のパラメータで渡す）。影色・影の境界・リム・matcap・発光。tone map をかけない |
| MMD | 拡散色・環境色・反射色、トゥーンテクスチャ、スフィアマップ（視点から見た法線を使う） |
| 輪郭線 | 変形済みのメッシュを別エンティティで共有し、法線方向に膨らませて表面を省いて描く（`faceCulling = .front`） |

- 表情による材質の変化は毎フレーム材質のパラメータを更新する。MMD の描画順は `ModelSortGroupComponent` で再現する
- 出力: Mac は `RealityRenderer` でテクスチャに描いて CVPixelBuffer にする。iOS / visionOS は `RealityView`
- ShaderGraph で MToon を再現しきれない・`RealityRenderer` が安定しないときは、Mac だけ Metal で描く（変形済みのバッファはそのまま使う）。
  visionOS 27 の `LowLevelRenderer` も候補

## 12. 仮想カメラ（`KawarinCameraExtension`・`VirtualCameraHost`）

| ストリーム | 向き | 用途 |
| --- | --- | --- |
| source | 出力 | Zoom などが読む |
| sink | 入力 | Mac アプリが描いた映像を書き込む |

- 既定は 1280×720・30fps・BGRA（会議向け）。配信向けに 1920×1080 と 60fps を選べる
- 受け渡し: Mac アプリが CoreMediaIO の C API で自分のデバイスを UID で探し、sink stream のキュー（`CMIOStreamCopyBufferQueue`）に CMSampleBuffer を入れる。
  拡張は `consumeSampleBuffer(from:)` で受け取り、source stream の `send(_:discontinuity:hostTimeInNanoseconds:)` で配信する
- 描画先は IOSurface 付きの `CVPixelBufferPool`。`CVMetalTextureCache` でテクスチャにして CPU へのコピーをしない
- Mac アプリが動いていないときは、拡張が「アプリを起動してください」の静止画を出す（黒い画面にしない）
- source stream を誰も見ていないときは、拡張がカスタムプロパティで知らせ、Mac アプリは描画を止める
- 映像は左右反転しない（Zoom などは自分の画面だけを反転して表示するため）
- 背景は単色・画像・グリーンバック（配信で OBS が抜く用）。透過は会議アプリが受け取れないので出さない
- 画角はバストアップを既定にし、配信向けに全身も選べる
- 有効化: `OSSystemExtensionRequest.activationRequest` → ユーザーがシステム設定で許可。アプリが /Applications にある必要がある
- 開発時は拡張の `CFBundleVersion` を上げないと入れ替わらない。`systemextensionsctl list` で状態を確かめ、ログは `os_log` → Console.app
- Mac アプリはメニューバーに常駐し、ログイン時の起動を選べる（`SMAppService`）。会議中にウィンドウを閉じても映像を止めない

## 13. 権限・署名・プライバシー

| 対象 | 必要なもの |
| --- | --- |
| `Kawarin`（iOS） | カメラ（`NSCameraUsageDescription`）、ローカルネットワーク（`NSLocalNetworkUsageDescription`・`NSBonjourServices`） |
| `KawarinMac` | `com.apple.developer.system-extension.install`、App Sandbox、App Group、ローカルネットワーク（macOS 15 以降は許可のダイアログが出る） |
| `KawarinCameraExtension` | App Sandbox、App Group（`CMIOExtensionMachServiceName` と合わせる） |

- 署名は自動署名と App Store Connect API キー（`-allowProvisioningUpdates`）。アプリ本体とカメラ拡張のプロファイルも Xcode が作る
- 顔・体のデータは端末内とローカルネットワーク（自分の Mac）でだけ扱い、保存しない・開発者に送らない・ログに値を出さない
- ARKit の顔データは広告などに使えない決まりがあるので、プライバシーポリシーに顔データの扱いを明記する。置き場所は `https://shilokuma.jp/privacy/kawarin/` の予定（まだ公開していない。配信の準備で shilokuma-web の `privacy/apps.json` に足して公開する）
- 解析・広告・クラッシュ収集の SDK は入れない。App のプライバシーは「データの収集なし」で申告する見込み
- 各ターゲットに `PrivacyInfo.xcprivacy` を置く

## 14. 課金（将来）

- MVP の機能はすべて無料。機能を使えるかを判断する小さな層（`FeatureAccess`）だけをアプリ側に用意し、今はすべて「使える」を返す
- 同梱の AvatarSample_A〜C は有料での再配布ができないので、課金の対象に入れない（`SampleAvatar.mustStayFree`。docs/SAMPLE_AVATARS.md）
- 課金を足すときに StoreKit 2 をつなぐ。Universal Purchase なので App 内課金も全プラットフォーム共通（`Transaction.currentEntitlements`）
- 必要になるもの: 有料 App 契約（銀行口座・税務情報）、購入の復元ボタン、最初の課金アイテムはアプリの新しいバージョンと一緒に審査に出す

## 15. 多言語

- 文言は最初から String Catalog（`Localizable.xcstrings`）で管理する。日本語と英語を正本にする。コードに書く元の文言は英語にし（`sourceLanguage` は `en`）、日本語は String Catalog の翻訳として持つ
- 追加する言語の候補: 簡体字中国語・繁体字中国語・韓国語・スペイン語・フランス語・ドイツ語・イタリア語・ポルトガル語（ブラジル）・タイ語・インドネシア語・ベトナム語
- 訳文の品質はビルドやテストで確かめられないので、ループでは訳を作るまでにして、確認は人が行う（ralph-kit の「ループに向かないタスク」）
- App Store の掲載情報は `AppStore/languages.json` と `AppStore/metadata/<言語>.json` に足す。審査メモとデモ動画は英語

## 16. CI / 配信

- テンプレートの GitHub Actions（Build・Archive・Upload・App Store の掲載情報）を使い、macOS のアプリとカメラ拡張を足す（ask-hub-apple の macOS の Upload を参考にする）
- ビルド番号は Upload のときに App Store Connect の最新から自動で増やす（テンプレートの `manageAppVersionAndBuildNumber`）。カメラ拡張もアプリ本体と同じ番号にする
- シミュレーターでは ARKit が動かないので、トラッキングの記録と再生を作る。iPhone で取った観測値をファイルに保存し、テストで再生する。Mac アプリの開発や審査用のデモにも使う
- 物理のテストは値の完全一致ではなく「NaN にならない」「一定時間で落ち着く」を確かめる

## 17. 開発の進め方

| Phase | 内容 | 進め方 |
| --- | --- | --- |
| 土台 | 設計書、ターゲット構成（iOS・macOS・カメラ拡張）、`KawarinKit` の雛形、最低 OS、CI の macOS 対応 | 人の PR（ターゲットの追加と pbxproj・CI の変更はループに向かない） |
| 0 検証 | (a) カメラ拡張と sink stream で Zoom・Discord に映す（サンドボックス内のアプリから送れるか、カメラの許可が要るかも確認） (b) `RealityRenderer` で描いて CVPixelBuffer にする (c) ShaderGraph で MToon の影・リム・輪郭線を出し、色が変わらないことを確かめる (d) iPhone で顔＋上半身＋手を同時に動かし、fps・発熱・指の精度を測る (e) Bullet を 3 プラットフォームでビルドする | 実機での確認は `needs-verify` の Issue にする |
| 1 | 共通コア（共通モデル・VRM 0.x / 1.0・FK）、変形の compute、RealityKit の簡易な材質、顔の送受信。同梱のサンプルアバターが VRM 0.x なので、0.x の読み込み（1.0 相当への変換）もここで行う | ゴールの Discussion からループ |
| 2 | 上半身・手（送信、キャリブレーション、IK、指） | 同上 |
| 3 | MToon の本実装、輪郭線、spring bone。同梱の β の 4 体（70〜80 万頂点）で iPhone の鏡モードの性能を確かめる | 同上 |
| 4 | PMX、MMD の材質、モーフ割り当ての UI、Bullet | 同上 |
| 5 | 配布の準備（Universal Purchase、互換モードを外す、審査用のデモ、プライバシー、多言語、ライセンス画面に同梱アバターの出典） | 人とループ |
| 将来 | visionOS（ビューアー・トラッカー）、App 内課金の新機能 | 役割を決めてから |

## 18. 未決事項・要確認

- 検証に使う端末（iPhone / iPad の機種、Mac の機種、Vision Pro の有無）
- 追加する言語（「15. 多言語」の候補から、配信の準備のときに確定する）
- プライバシーポリシーの公開（`https://shilokuma.jp/privacy/kawarin/`。顔データの扱いを書く。審査に出す前に必要）
- visionOS 版の役割（ビューアー / トラッカー / 両方）
- 「Phase 0 検証」の結果で変わりうるもの: 描画の方式（RealityKit のままか、Mac だけ Metal か）、手の推定（Vision か MediaPipe か）

## 参考

| 名前 | 参考になる点 | ライセンス |
| --- | --- | --- |
| [vrm-c/vrm-specification](https://github.com/vrm-c/vrm-specification) | VRM 0.x / 1.0 の仕様 | — |
| [pixiv/three-vrm](https://github.com/pixiv/three-vrm) | MToon、spring bone、0.x から 1.0 への変換 | MIT |
| [vrm-c/UniVRM](https://github.com/vrm-c/UniVRM) | 公式の Unity 実装 | MIT |
| [tattn/VRMKit](https://github.com/tattn/VRMKit) | Swift の VRM ローダー | MIT |
| [bulletphysics/bullet3](https://github.com/bulletphysics/bullet3) | MMD の剛体物理 | zlib |
| three.js の MMDPhysics | PMX の剛体・ジョイントの Bullet への写し方 | MIT |
| WWDC22「Create camera extensions with Core Media IO」 | カメラ拡張と sink stream | — |
| OBS Studio の mac-virtualcam | sink stream を使う実例 | GPL（読むだけにする） |
