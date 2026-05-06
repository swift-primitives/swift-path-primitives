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

extension Path {
    /// A filesystem-safe form of `source`, suitable for embedding into
    /// a single path component.
    ///
    /// Retains alphanumerics, underscore, hyphen, and period; replaces
    /// every other character with `_`. Deterministic — same input
    /// produces the same output within and across processes.
    ///
    /// Distinct inputs MAY map to the same output (the sanitization
    /// is lossy). For collision-free deterministic temp paths, prefer
    /// keying on a stable cryptographic digest of the source rather
    /// than the source itself.
    public static func sanitized(from source: Swift.String) -> Swift.String {
        var sanitized = ""
        sanitized.reserveCapacity(source.count)
        for character in source {
            if character.isLetter || character.isNumber
                || character == "_" || character == "-" || character == "."
            {
                sanitized.append(character)
            } else {
                sanitized.append("_")
            }
        }
        return sanitized
    }
}
