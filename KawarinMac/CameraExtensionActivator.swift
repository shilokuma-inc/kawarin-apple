import Foundation
import Observation
import SystemExtensions

/// カメラ拡張（KawarinCameraExtension）の有効化・無効化を System Extensions の仕組みに頼む。
///
/// 有効にするとユーザーにシステム設定での許可を求める。アプリが /Applications に無いと有効にできない
/// （docs/DESIGN.md の「12. 仮想カメラ」）。
@Observable
final class CameraExtensionActivator: NSObject {
    enum Status: Equatable {
        case idle
        case requesting
        case waitingForUserApproval
        case activated
        case deactivated
        case willCompleteAfterReboot
        case failed(String)
    }

    private enum Action {
        case activate
        case deactivate
    }

    private(set) var status: Status = .idle

    /// 結果を待っているリクエストの種類。delegate には有効化と無効化の区別が渡されないため、出した側で覚えておく
    private var pendingAction: Action?

    /// カメラ拡張の Bundle ID。アプリ本体の Bundle ID に `.CameraExtension` を付けたもの
    private var extensionIdentifier: String? {
        Bundle.main.bundleIdentifier.map { "\($0).CameraExtension" }
    }

    var isBusy: Bool {
        pendingAction != nil
    }

    func activate() {
        submit(.activate)
    }

    func deactivate() {
        submit(.deactivate)
    }

    private func submit(_ action: Action) {
        guard pendingAction == nil else {
            return
        }
        guard let extensionIdentifier else {
            status = .failed(String(localized: "The app's bundle identifier could not be read."))
            return
        }
        let request = switch action {
        case .activate:
            OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        case .deactivate:
            OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        }
        request.delegate = self
        pendingAction = action
        status = .requesting
        OSSystemExtensionManager.shared.submitRequest(request)
    }
}

// リクエストは queue: .main で出しているので、delegate はメインスレッドで呼ばれる
extension CameraExtensionActivator: @preconcurrency OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        // 開発中は同じ版のまま入れ替えたいことがあるので、常に新しいほうに置き換える
        .replace
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        status = .waitingForUserApproval
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        defer { pendingAction = nil }
        switch result {
        case .completed:
            status = pendingAction == .deactivate ? .deactivated : .activated
        case .willCompleteAfterReboot:
            status = .willCompleteAfterReboot
        @unknown default:
            status = .failed(String(localized: "The request finished with an unknown result."))
        }
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: any Error) {
        pendingAction = nil
        status = .failed(error.localizedDescription)
    }
}
