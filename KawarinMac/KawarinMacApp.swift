import SwiftUI

/// Mac 版の入口。アバターの描画と、仮想カメラ（カメラ拡張）への出力を担う（docs/DESIGN.md の「3. ターゲットと配布」）
@main
struct KawarinMacApp: App {
    @State private var cameraExtension = CameraExtensionActivator()

    var body: some Scene {
        WindowGroup {
            MacContentView(cameraExtension: cameraExtension)
        }
    }
}
