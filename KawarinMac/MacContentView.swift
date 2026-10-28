import SwiftUI

/// Mac 版の最初の画面。今はカメラ拡張の有効化だけを置く（アバターのプレビューは Phase 1 で足す）
struct MacContentView: View {
    let cameraExtension: CameraExtensionActivator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kawarin Camera")
                .font(.title2.bold())
            Text("Turn on the camera extension to use Kawarin as a camera in video call apps.")
                .foregroundStyle(.secondary)
            HStack {
                Button("Turn On Camera Extension") {
                    cameraExtension.activate()
                }
                Button("Turn Off") {
                    cameraExtension.deactivate()
                }
            }
            .disabled(cameraExtension.isBusy)
            Text(statusMessage)
                .font(.callout)
        }
        .padding(24)
        .frame(minWidth: 420, alignment: .leading)
    }

    private var statusMessage: LocalizedStringKey {
        switch cameraExtension.status {
        case .idle:
            "The camera extension has not been turned on from this app yet."
        case .requesting:
            "Sending the request…"
        case .waitingForUserApproval:
            "Allow the extension in System Settings > General > Login Items & Extensions."
        case .activated:
            "The camera extension is on. Choose “Kawarin Camera” in your video call app."
        case .deactivated:
            "The camera extension is off."
        case .willCompleteAfterReboot:
            "The change will take effect after you restart your Mac."
        case .failed(let message):
            "Failed: \(message)"
        }
    }
}

#Preview {
    MacContentView(cameraExtension: CameraExtensionActivator())
}
