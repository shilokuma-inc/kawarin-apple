import CoreVideo
import Darwin

/// 仮想カメラが映っていることを確かめるためのテスト映像。ピンクの背景に、白い帯が上下に往復する。
///
/// Mac アプリから映像を受け取れないとき（アプリが動いていないときなど）の代わりの映像にも使う。
struct TestPatternRenderer {
    /// BGRA の順に並べた 1 ピクセル（#FFD6E8 のピンク）
    private static let background: UInt32 = Self.bgra(red: 0xFF, green: 0xD6, blue: 0xE8)
    private static let stripe: UInt32 = Self.bgra(red: 0xFF, green: 0xFF, blue: 0xFF)
    private static let stripeHeight = 24
    /// 1 フレームで帯が動く行数
    private static let stripeStep = 6

    private var stripeTop = 0
    private var isMovingDown = true

    mutating func draw(into pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let stripeRows = stripeTop..<(stripeTop + Self.stripeHeight)

        for row in 0..<height {
            var pixel = stripeRows.contains(row) ? Self.stripe : Self.background
            memset_pattern4(baseAddress + row * bytesPerRow, &pixel, bytesPerRow)
        }
        advanceStripe(height: height)
    }

    private mutating func advanceStripe(height: Int) {
        let lastTop = max(height - Self.stripeHeight, 0)
        stripeTop += isMovingDown ? Self.stripeStep : -Self.stripeStep
        if stripeTop >= lastTop {
            stripeTop = lastTop
            isMovingDown = false
        } else if stripeTop <= 0 {
            stripeTop = 0
            isMovingDown = true
        }
    }

    private static func bgra(red: UInt32, green: UInt32, blue: UInt32) -> UInt32 {
        // リトルエンディアンでメモリに B, G, R, A の順に並ぶ
        blue | green << 8 | red << 16 | 0xFF << 24
    }
}
