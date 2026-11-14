import Foundation
@testable import Networking
import Testing

@Suite("Form encoding contracts")
struct FormEncoderTests {
    @Test("Encodes fields in order, preserves repeats, and escapes form delimiters")
    func orderedRepeatedFieldsAndEscaping() {
        let body = FormEncoder.encode([
            FormField(name: "parent", value: "123"),
            FormField(name: "goto", value: "item?id=1&a=b"),
            FormField(name: "text", value: "first line\nsecond + line"),
            FormField(name: "tag", value: "one"),
            FormField(name: "tag", value: "two")
        ])
        #expect(body == "parent=123&goto=item%3Fid%3D1%26a%3Db&text=first+line%0Asecond+%2B+line&tag=one&tag=two")
    }

    @Test("Encodes Unicode values as UTF-8 percent escapes")
    func unicodeEncoding() {
        #expect(FormEncoder.encodeValue("café 😀") == "caf%C3%A9+%F0%9F%98%80")
    }
}
