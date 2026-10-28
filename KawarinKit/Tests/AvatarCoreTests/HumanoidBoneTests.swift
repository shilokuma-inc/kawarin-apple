@testable import AvatarCore
import Testing

struct HumanoidBoneTests {
    @Test func hasAllVRM1Bones() {
        // VRM 1.0 の humanoid は 55 個の骨を定義している
        #expect(HumanoidBone.allCases.count == 55)
    }

    @Test func requiredBonesAreTheFifteenFromVRM1() {
        #expect(HumanoidBone.required.count == 15)
        #expect(HumanoidBone.required.contains(.hips))
        #expect(!HumanoidBone.required.contains(.chest))
    }
}
