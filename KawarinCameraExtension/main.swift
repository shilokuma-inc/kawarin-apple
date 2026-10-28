import CoreMediaIO
import Foundation

// カメラ拡張の入口。会議アプリなどからの呼び出し（CMIO のコールバック）はすべて cameraExtensionQueue で受ける
let providerSource = CameraProviderSource(clientQueue: cameraExtensionQueue)
CMIOExtensionProvider.startService(provider: providerSource.provider)
CFRunLoopRun()
