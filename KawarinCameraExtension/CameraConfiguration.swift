import CoreMedia
import Foundation

/// 仮想カメラの名前と映像の形式（docs/DESIGN.md の「12. 仮想カメラ」）
enum CameraConfiguration {
    /// 会議アプリのカメラ一覧に出る名前
    static let deviceName = "Kawarin Camera"
    static let manufacturer = "Shilokuma"
    static let model = "Kawarin Camera"

    /// 会議アプリが選んだカメラを覚えておけるよう、デバイスの ID は固定する
    static let deviceID: UUID = {
        guard let id = UUID(uuidString: "6B9C1E52-3F0A-4C1E-9D0B-7A2F5E8C4D11") else {
            fatalError("仮想カメラのデバイス ID の書式が不正です")
        }
        return id
    }()

    static let streamID: UUID = {
        guard let id = UUID(uuidString: "2E7A4B18-95C3-4F6D-8A1E-0C5B9D3F7A62") else {
            fatalError("仮想カメラのストリーム ID の書式が不正です")
        }
        return id
    }()

    /// 会議向けの既定（1280×720・30fps・BGRA）。配信向けの 1080p・60fps は Phase 0 以降で足す
    static let width: Int32 = 1280
    static let height: Int32 = 720
    static let framesPerSecond: Int32 = 30
    static let pixelFormat = kCVPixelFormatType_32BGRA

    static var frameDuration: CMTime {
        CMTime(value: 1, timescale: framesPerSecond)
    }
}
