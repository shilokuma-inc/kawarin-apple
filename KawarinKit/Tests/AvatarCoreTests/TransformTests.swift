import simd
import Testing
@testable import AvatarCore

struct TransformTests {
    @Test func identityIsIdentityMatrix() {
        #expect(Transform.identity.matrix == matrix_identity_float4x4)
    }

    @Test func composingAppliesParentRotationToChildTranslation() {
        // 親は x 方向に 1 進み、Y 軸まわりに 90° 回っている。子は親から見て +Z に 1 の位置
        let parent = Transform(
            translation: [1, 0, 0],
            rotation: simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        )
        let child = Transform(translation: [0, 0, 1])

        let world = parent * child

        // Y 軸まわりの +90° で +Z は +X に向くので、親の位置からさらに x に 1 進む
        #expect(isNearlyEqual(world.translation, [2, 0, 0]))
    }

    @Test func composedMatrixMatchesMatrixProduct() {
        let parent = Transform(
            translation: [0.2, 1.4, -0.3],
            rotation: simd_quatf(angle: 0.7, axis: simd_normalize([1, 2, 0.5])),
            scale: [1.5, 1.5, 1.5]
        )
        let child = Transform(
            translation: [0, 0.1, 0.05],
            rotation: simd_quatf(angle: -0.4, axis: [0, 0, 1])
        )

        let composed = (parent * child).matrix
        let product = parent.matrix * child.matrix

        for column in 0..<4 {
            #expect(isNearlyEqual(composed[column], product[column]))
        }
    }

    private func isNearlyEqual<Vector: SIMD>(_ lhs: Vector, _ rhs: Vector) -> Bool where Vector.Scalar == Float {
        (0..<lhs.scalarCount).allSatisfy { abs(lhs[$0] - rhs[$0]) < 1e-5 }
    }
}
