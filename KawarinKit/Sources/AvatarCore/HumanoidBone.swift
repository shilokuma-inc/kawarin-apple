/// 人型の骨の共通名。VRM 1.0 の humanoid の名前（55 個）をそのまま使う。
///
/// VRM 0.x は親指の名前が違う（`leftThumbProximal` / `Intermediate` / `Distal`）ため、読み込むときに 1.0 の名前へ変換する。
/// MMD は骨の名前（頭・首・上半身2・両目 など）から対応付ける（docs/DESIGN.md の「8. 共通モデルと座標系」）。
public enum HumanoidBone: String, CaseIterable, Sendable {
    // 胴体
    case hips
    case spine
    case chest
    case upperChest
    case neck

    // 頭
    case head
    case leftEye
    case rightEye
    case jaw

    // 脚
    case leftUpperLeg
    case leftLowerLeg
    case leftFoot
    case leftToes
    case rightUpperLeg
    case rightLowerLeg
    case rightFoot
    case rightToes

    // 腕
    case leftShoulder
    case leftUpperArm
    case leftLowerArm
    case leftHand
    case rightShoulder
    case rightUpperArm
    case rightLowerArm
    case rightHand

    // 左手の指
    case leftThumbMetacarpal
    case leftThumbProximal
    case leftThumbDistal
    case leftIndexProximal
    case leftIndexIntermediate
    case leftIndexDistal
    case leftMiddleProximal
    case leftMiddleIntermediate
    case leftMiddleDistal
    case leftRingProximal
    case leftRingIntermediate
    case leftRingDistal
    case leftLittleProximal
    case leftLittleIntermediate
    case leftLittleDistal

    // 右手の指
    case rightThumbMetacarpal
    case rightThumbProximal
    case rightThumbDistal
    case rightIndexProximal
    case rightIndexIntermediate
    case rightIndexDistal
    case rightMiddleProximal
    case rightMiddleIntermediate
    case rightMiddleDistal
    case rightRingProximal
    case rightRingIntermediate
    case rightRingDistal
    case rightLittleProximal
    case rightLittleIntermediate
    case rightLittleDistal

    /// VRM 1.0 で必ず存在する骨。読み込むときに、これが欠けたモデルを人型として扱わない
    public static let required: Set<HumanoidBone> = [
        .hips, .spine, .head,
        .leftUpperLeg, .leftLowerLeg, .leftFoot,
        .rightUpperLeg, .rightLowerLeg, .rightFoot,
        .leftUpperArm, .leftLowerArm, .leftHand,
        .rightUpperArm, .rightLowerArm, .rightHand
    ]
}
