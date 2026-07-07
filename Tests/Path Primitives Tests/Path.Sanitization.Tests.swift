// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-path-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-path-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Path_Primitives
import Testing

extension Path {
    @Suite
    struct Sanitization {
        @Suite struct Sanitized {}
    }
}

extension Path.Sanitization.Sanitized {
    @Test
    func `Alphanumerics are retained`() {
        #expect(Path.sanitized(from: "abcXYZ123") == "abcXYZ123")
    }

    @Test
    func `Underscore hyphen and dot are retained`() {
        #expect(Path.sanitized(from: "a_b-c.d") == "a_b-c.d")
    }

    @Test
    func `Slashes are replaced with underscores`() {
        #expect(
            Path.sanitized(from: "https://example.com/path/file.swift")
                == "https___example.com_path_file.swift"
        )
    }

    @Test
    func `Distinct URLs produce distinct sanitized forms`() {
        let urlA = "https://a.example.com/Lint.swift"
        let urlB = "https://b.example.com/Lint.swift"
        #expect(
            Path.sanitized(from: urlA)
                != Path.sanitized(from: urlB)
        )
    }

    @Test
    func `Empty input maps to empty output`() {
        #expect(Path.sanitized(from: "").isEmpty)
    }

    @Test
    func `All-unsafe input maps to all underscores`() {
        #expect(Path.sanitized(from: "/// !!!") == "_______")
    }

    @Test
    func `Leading dot is preserved`() {
        #expect(Path.sanitized(from: ".hidden") == ".hidden")
    }

    @Test
    func `Trailing whitespace becomes underscore`() {
        #expect(Path.sanitized(from: "name ") == "name_")
    }

    @Test
    func `NUL bytes are replaced with underscore`() {
        let withNUL = "before\0after"
        let result = Path.sanitized(from: withNUL)
        #expect(result == "before_after")
        #expect(!result.contains("\0"))
    }

    @Test
    func `Output is deterministic across multiple calls`() {
        let source = "https://example.com/some/path?query=value"
        let first = Path.sanitized(from: source)
        let second = Path.sanitized(from: source)
        #expect(first == second)
    }

    @Test
    func `Unicode letters are retained`() {
        // isLetter accepts Unicode letters per Character semantics.
        #expect(Path.sanitized(from: "café") == "café")
    }
}
