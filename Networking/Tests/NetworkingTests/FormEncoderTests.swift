//
//  FormEncoderTests.swift
//  NetworkingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
@testable import Networking
import Testing

@Suite("FormEncoder")
struct FormEncoderTests {
    @Test("Encodes form delimiters and reserved characters", arguments: [
        ("hello world", "hello+world"),
        ("a+b", "a%2Bb"),
        ("a&b", "a%26b"),
        ("a=b", "a%3Db"),
        ("100%", "100%25"),
    ])
    func reservedCharacters(value: String, expected: String) {
        #expect(FormEncoder.encodeValue(value) == expected)
    }

    @Test("Encodes newlines and unicode", arguments: [
        ("line1\nline2", "line1%0Aline2"),
        ("line1\r\nline2", "line1%0D%0Aline2"),
        ("café", "caf%C3%A9"),
        ("😀", "%F0%9F%98%80"),
    ])
    func newlinesAndUnicode(value: String, expected: String) {
        #expect(FormEncoder.encodeValue(value) == expected)
    }

    @Test("Encodes empty values without noise")
    func emptyValues() {
        #expect(FormEncoder.encodeValue("") == "")
    }

    @Test("Unreserved characters pass through untouched")
    func unreservedCharacters() {
        #expect(FormEncoder.encodeValue("abcXYZ019-._*") == "abcXYZ019-._*")
    }

    @Test("Encodes ordered fields including repeats")
    func orderedFields() {
        let body = FormEncoder.encode([
            FormField(name: "parent", value: "123"),
            FormField(name: "goto", value: "item?id=1"),
            FormField(name: "hmac", value: "abc"),
            FormField(name: "text", value: "first line\nsecond + line"),
            FormField(name: "tag", value: "a"),
            FormField(name: "tag", value: "b"),
        ])

        #expect(body == "parent=123&goto=item%3Fid%3D1&hmac=abc&text=first+line%0Asecond+%2B+line&tag=a&tag=b")
    }
}
