import CoreMediaIO
import CoreVideo
import Foundation
import IOKit.audio

/// 仮想カメラ 1 台。会議アプリが映像を読み始めたら、テスト映像を 30fps で送る。
///
/// Phase 0 で、Mac アプリが描いた映像を sink stream で受け取って送る形に置き換える（docs/DESIGN.md の「12. 仮想カメラ」）。
/// 状態は `cameraExtensionQueue` の上でだけ触る。
final class CameraDeviceSource: NSObject, CMIOExtensionDeviceSource, @unchecked Sendable {
    private(set) var device: CMIOExtensionDevice!
    private var streamSource: CameraStreamSource!
    private var videoDescription: CMFormatDescription!
    private var bufferPool: CVPixelBufferPool!
    private var timer: DispatchSourceTimer?
    /// 映像を読んでいるクライアントの数。0 になったら送るのを止める
    private var streamingCount = 0
    private var testPattern = TestPatternRenderer()

    init(localizedName: String) {
        super.init()
        device = CMIOExtensionDevice(
            localizedName: localizedName,
            deviceID: CameraConfiguration.deviceID,
            legacyDeviceID: nil,
            source: self
        )

        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: CameraConfiguration.pixelFormat,
            width: CameraConfiguration.width,
            height: CameraConfiguration.height,
            extensions: nil,
            formatDescriptionOut: &videoDescription
        )
        guard status == noErr, let videoDescription else {
            fatalError("映像の形式を作れませんでした: \(status)")
        }

        // 別プロセス（会議アプリ）に渡すため、IOSurface 付きのバッファにする
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferWidthKey: CameraConfiguration.width,
            kCVPixelBufferHeightKey: CameraConfiguration.height,
            kCVPixelBufferPixelFormatTypeKey: CameraConfiguration.pixelFormat,
            kCVPixelBufferIOSurfacePropertiesKey: [CFString: Any]()
        ]
        let poolStatus = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes as CFDictionary, &bufferPool)
        guard poolStatus == kCVReturnSuccess, bufferPool != nil else {
            fatalError("映像のバッファのプールを作れませんでした: \(poolStatus)")
        }

        let streamFormat = CMIOExtensionStreamFormat(
            formatDescription: videoDescription,
            maxFrameDuration: CameraConfiguration.frameDuration,
            minFrameDuration: CameraConfiguration.frameDuration,
            validFrameDurations: nil
        )
        streamSource = CameraStreamSource(
            localizedName: "\(localizedName).Video",
            streamID: CameraConfiguration.streamID,
            streamFormat: streamFormat,
            device: device
        )
        do {
            try device.addStream(streamSource.stream)
        } catch {
            fatalError("仮想カメラのストリームを追加できませんでした: \(error.localizedDescription)")
        }
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.deviceTransportType, .deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = Int(kIOAudioDeviceTransportTypeVirtual)
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = CameraConfiguration.model
        }
        return deviceProperties
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {}

    func startStreaming() {
        streamingCount += 1
        guard timer == nil else {
            return
        }
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: cameraExtensionQueue)
        timer.schedule(deadline: .now(), repeating: CameraConfiguration.frameDuration.seconds, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.sendFrame()
        }
        timer.resume()
        self.timer = timer
        cameraExtensionLogger.info("映像の送出を始めました")
    }

    func stopStreaming() {
        streamingCount = max(streamingCount - 1, 0)
        guard streamingCount == 0 else {
            return
        }
        timer?.cancel()
        timer = nil
        cameraExtensionLogger.info("映像の送出を止めました")
    }

    private func sendFrame() {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, bufferPool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            cameraExtensionLogger.error("映像のバッファが足りません: \(status)")
            return
        }
        testPattern.draw(into: pixelBuffer)

        var timing = CMSampleTimingInfo(
            duration: CameraConfiguration.frameDuration,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard sampleStatus == noErr, let sampleBuffer else {
            cameraExtensionLogger.error("映像のサンプルを作れませんでした: \(sampleStatus)")
            return
        }
        let hostTime = UInt64(timing.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
        streamSource.stream.send(sampleBuffer, discontinuity: [], hostTimeInNanoseconds: hostTime)
    }
}
