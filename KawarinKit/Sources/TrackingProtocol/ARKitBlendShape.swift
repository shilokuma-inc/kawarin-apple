/// iPhone / iPad から送る表情の 52 種類。
///
/// **宣言の順番がパケットの中の並び順になる**（docs/DESIGN.md の「6.3 パケット」）。
/// 順番を変える・途中に足すと、古いアプリとの送受信が壊れるので、変えるときはパケットの version を上げる。
///
/// `rawValue` はパーフェクトシンク対応の VRM が使う表情名（ARKit の Swift の名前と同じ）。
/// ARKit の `ARFaceAnchor.BlendShapeLocation.rawValue`（`eyeBlink_L` など）とは違うので、iOS 側で対応付ける。
public enum ARKitBlendShape: String, CaseIterable, Sendable {
    // 左目
    case eyeBlinkLeft
    case eyeLookDownLeft
    case eyeLookInLeft
    case eyeLookOutLeft
    case eyeLookUpLeft
    case eyeSquintLeft
    case eyeWideLeft

    // 右目
    case eyeBlinkRight
    case eyeLookDownRight
    case eyeLookInRight
    case eyeLookOutRight
    case eyeLookUpRight
    case eyeSquintRight
    case eyeWideRight

    // あご
    case jawForward
    case jawLeft
    case jawRight
    case jawOpen

    // 口
    case mouthClose
    case mouthFunnel
    case mouthPucker
    case mouthLeft
    case mouthRight
    case mouthSmileLeft
    case mouthSmileRight
    case mouthFrownLeft
    case mouthFrownRight
    case mouthDimpleLeft
    case mouthDimpleRight
    case mouthStretchLeft
    case mouthStretchRight
    case mouthRollLower
    case mouthRollUpper
    case mouthShrugLower
    case mouthShrugUpper
    case mouthPressLeft
    case mouthPressRight
    case mouthLowerDownLeft
    case mouthLowerDownRight
    case mouthUpperUpLeft
    case mouthUpperUpRight

    // 眉
    case browDownLeft
    case browDownRight
    case browInnerUp
    case browOuterUpLeft
    case browOuterUpRight

    // 頬・鼻・舌
    case cheekPuff
    case cheekSquintLeft
    case cheekSquintRight
    case noseSneerLeft
    case noseSneerRight
    case tongueOut
}
