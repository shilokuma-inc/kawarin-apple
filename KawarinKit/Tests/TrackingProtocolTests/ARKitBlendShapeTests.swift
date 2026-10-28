import Testing
@testable import TrackingProtocol

struct ARKitBlendShapeTests {
    /// パケットの中の並び順。宣言の順番を変えるとこのテストが落ちる（送受信の形式が壊れるため、変えるならパケットの version を上げる）
    @Test func wireOrderIsFixed() {
        let expected = [
            "eyeBlinkLeft", "eyeLookDownLeft", "eyeLookInLeft", "eyeLookOutLeft", "eyeLookUpLeft", "eyeSquintLeft", "eyeWideLeft",
            "eyeBlinkRight", "eyeLookDownRight", "eyeLookInRight", "eyeLookOutRight", "eyeLookUpRight", "eyeSquintRight", "eyeWideRight",
            "jawForward", "jawLeft", "jawRight", "jawOpen",
            "mouthClose", "mouthFunnel", "mouthPucker", "mouthLeft", "mouthRight",
            "mouthSmileLeft", "mouthSmileRight", "mouthFrownLeft", "mouthFrownRight",
            "mouthDimpleLeft", "mouthDimpleRight", "mouthStretchLeft", "mouthStretchRight",
            "mouthRollLower", "mouthRollUpper", "mouthShrugLower", "mouthShrugUpper",
            "mouthPressLeft", "mouthPressRight", "mouthLowerDownLeft", "mouthLowerDownRight",
            "mouthUpperUpLeft", "mouthUpperUpRight",
            "browDownLeft", "browDownRight", "browInnerUp", "browOuterUpLeft", "browOuterUpRight",
            "cheekPuff", "cheekSquintLeft", "cheekSquintRight",
            "noseSneerLeft", "noseSneerRight",
            "tongueOut"
        ]

        #expect(ARKitBlendShape.allCases.map(\.rawValue) == expected)
    }

    @Test func hasFiftyTwoUniqueShapes() {
        let names = ARKitBlendShape.allCases.map(\.rawValue)
        #expect(names.count == 52)
        #expect(Set(names).count == 52)
    }
}
