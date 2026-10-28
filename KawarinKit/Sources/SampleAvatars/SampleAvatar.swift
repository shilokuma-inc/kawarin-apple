import Foundation

/// アプリに同梱するサンプルアバター（VRoid の公式サンプル 7 体。どれも VRM 0.x）。
///
/// 利用条件と出典は docs/SAMPLE_AVATARS.md。VRM のメタに書かれた利用条件は書き換えない。
public struct SampleAvatar: Identifiable, Hashable, Sendable {
    /// 同梱の元になった配布物ごとの利用条件
    public enum License: Hashable, Sendable {
        /// VRoid の β Ver AvatarSample（CC0）
        case cc0
        /// VRoid のプリセット（VRoidPreset_A - Z）の利用条件。CC0 ではなく、有料での再配布ができない
        case vroidPreset
    }

    /// 同梱しているファイルの名前（拡張子なし）
    public let id: String
    /// VRM のメタのタイトル
    public let title: String
    public let license: License

    /// 有料の機能（App 内課金）の対象に入れてはいけないか。
    /// VRoid のプリセットは有料での再配布ができないため、無料で使える範囲に置き続ける
    public var mustStayFree: Bool {
        license == .vroidPreset
    }

    /// アプリの中のファイルの場所
    public var fileURL: URL? {
        Bundle.module.url(forResource: id, withExtension: "vrm", subdirectory: "Avatars")
    }

    public static let all: [SampleAvatar] = [
        SampleAvatar(id: "avatar-sample-a", title: "AvatarSample_A", license: .vroidPreset),
        SampleAvatar(id: "avatar-sample-b", title: "AvatarSample_B", license: .vroidPreset),
        SampleAvatar(id: "avatar-sample-c", title: "AvatarSample_C", license: .vroidPreset),
        SampleAvatar(id: "sendagaya-shibu", title: "千駄ヶ谷渋_WSU", license: .cc0),
        SampleAvatar(id: "victoria-rubin", title: "ヴィクトリア・ルービン", license: .cc0),
        SampleAvatar(id: "vita", title: "ヴィータ", license: .cc0),
        SampleAvatar(id: "bibi", title: "ビビ", license: .cc0)
    ]
}
