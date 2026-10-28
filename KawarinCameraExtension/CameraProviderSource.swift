import CoreMediaIO
import Foundation
import os

/// CMIO のコールバックと映像の送出を行う直列キュー。
///
/// プロバイダー・デバイス・ストリームの各ソースが持つ状態は、このキューの上でだけ読み書きする。
/// CMIO の型（`CMIOExtensionStream` など）は Sendable ではないため、各ソースは `@unchecked Sendable` にして、
/// 状態をこのキューに閉じ込めることで安全を保つ。
let cameraExtensionQueue = DispatchQueue(label: "jp.shilokuma.Kawarin.CameraExtension", qos: .userInteractive)

let cameraExtensionLogger = Logger(subsystem: "jp.shilokuma.Kawarin.CameraExtension", category: "camera")

/// カメラ拡張が提供する仮想カメラの一覧（今は Kawarin Camera の 1 台だけ）
final class CameraProviderSource: NSObject, CMIOExtensionProviderSource, @unchecked Sendable {
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: CameraDeviceSource!

    init(clientQueue: DispatchQueue) {
        super.init()
        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
        deviceSource = CameraDeviceSource(localizedName: CameraConfiguration.deviceName)
        do {
            try provider.addDevice(deviceSource.device)
        } catch {
            fatalError("仮想カメラのデバイスを追加できませんでした: \(error.localizedDescription)")
        }
    }

    func connect(to client: CMIOExtensionClient) throws {}

    func disconnect(from client: CMIOExtensionClient) {}

    var availableProperties: Set<CMIOExtensionProperty> {
        [.providerManufacturer]
    }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = CameraConfiguration.manufacturer
        }
        return providerProperties
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}
}
