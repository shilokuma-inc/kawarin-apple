// swift-tools-version: 6.0
import PackageDescription

// iOS・macOS・visionOS のアプリで共有するコード（docs/DESIGN.md の「4. パッケージ構成と依存のルール」）。
// アプリはプラットフォームごとのプロダクトを 1 つだけリンクする（iPhone / iPad は KawarinKitIOS、Mac は KawarinKitMac）。
// モジュールを足すときはプロダクトの targets に加えるだけでよく、pbxproj を変えなくてよい。
let package = Package(
    name: "KawarinKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "KawarinKitIOS", targets: ["AvatarCore", "TrackingProtocol"]),
        .library(name: "KawarinKitMac", targets: ["AvatarCore", "TrackingProtocol"]),
    ],
    targets: [
        // 共通モデルと姿勢計算。Swift と simd だけで書き、UIKit・AppKit・ARKit・RealityKit を import しない
        .target(name: "AvatarCore"),
        // iPhone / iPad と Mac の間の送受信の形式。こちらも UI やセンサーの API に依存しない
        .target(name: "TrackingProtocol"),
        .testTarget(name: "AvatarCoreTests", dependencies: ["AvatarCore"]),
        .testTarget(name: "TrackingProtocolTests", dependencies: ["TrackingProtocol"]),
    ]
)
