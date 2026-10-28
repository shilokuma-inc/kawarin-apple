import Foundation
@testable import SampleAvatars
import Testing

struct SampleAvatarTests {
    @Test func bundlesSevenUniqueAvatars() {
        let ids = SampleAvatar.all.map(\.id)
        #expect(ids.count == 7)
        #expect(Set(ids).count == 7)
    }

    @Test(arguments: SampleAvatar.all)
    func fileIsBundledAsBinaryGLTF(avatar: SampleAvatar) throws {
        let url = try #require(avatar.fileURL, "\(avatar.id).vrm がバンドルに無い")
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        // VRM は GLB（バイナリの glTF）で、先頭 4 バイトが "glTF"
        let magic = try handle.read(upToCount: 4)
        #expect(magic == Data("glTF".utf8))
    }

    @Test func vroidPresetsStayFree() {
        let freeOnly = SampleAvatar.all.filter(\.mustStayFree).map(\.id)
        #expect(freeOnly == ["avatar-sample-a", "avatar-sample-b", "avatar-sample-c"])
    }
}
