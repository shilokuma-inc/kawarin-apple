import simd

/// 骨やエンティティの、親に対する姿勢（移動・回転・拡大縮小）。
///
/// 座標系は右手系・Y 軸が上・メートル単位（docs/DESIGN.md の「8. 共通モデルと座標系」）。
/// VRM 0.x や MMD のモデルは、読み込むときにこの座標系へ変換してから扱う。
public struct Transform: Sendable, Equatable {
    public var translation: SIMD3<Float>
    public var rotation: simd_quatf
    public var scale: SIMD3<Float>

    public static let identity = Transform()

    public init(
        translation: SIMD3<Float> = .zero,
        rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
        scale: SIMD3<Float> = .one
    ) {
        self.translation = translation
        self.rotation = rotation
        self.scale = scale
    }

    /// 4x4 の行列。拡大縮小 → 回転 → 移動の順に掛けたもの
    public var matrix: simd_float4x4 {
        let rotationMatrix = simd_float4x4(rotation)
        return simd_float4x4(columns: (
            rotationMatrix.columns.0 * scale.x,
            rotationMatrix.columns.1 * scale.y,
            rotationMatrix.columns.2 * scale.z,
            SIMD4<Float>(translation, 1)
        ))
    }

    /// 親の姿勢に子の姿勢を重ねる（親から見た子の姿勢を、親の親から見た姿勢にする）。
    ///
    /// 拡大縮小は軸ごとの掛け算として扱い、回転と組み合わさって生じるせん断は扱わない。
    /// アバターの骨は拡大縮小しないか一様なので、これで足りる
    public static func * (parent: Transform, child: Transform) -> Transform {
        Transform(
            translation: parent.translation + parent.rotation.act(parent.scale * child.translation),
            rotation: parent.rotation * child.rotation,
            scale: parent.scale * child.scale
        )
    }
}
