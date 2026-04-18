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

#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

// MARK: - Path.Scan

extension Path {
    /// Separator-parameterized path scanning primitives.
    ///
    /// The scanning algorithm is platform-agnostic; only the separator byte(s)
    /// vary by platform. These primitives are the shared building blocks used
    /// by:
    ///
    /// - L2 `Path.Protocol` conformances (POSIX, Windows), each supplying its
    ///   own separator constants.
    /// - L3 path types that own their storage and duplicate decomposition
    ///   directly on their bytes, rather than going through a `Path.View`.
    ///
    /// The higher-level branching (what to return for empty results, how to
    /// handle drive letters, whether a leading separator denotes a root) is
    /// not centralized here — it is inherently per-layer and per-platform
    /// policy. `Path.Scan` provides the byte scan itself.
    public enum Scan {}
}

extension Path.Scan {
    /// Returns the index of the last separator byte in `bytes`, or `nil` if absent.
    ///
    /// Scans linearly in reverse. If `alt` is provided, both `primary` and
    /// `alt` count as separators — this supports Windows's dual-separator
    /// vocabulary (`\` primary, `/` alt) without requiring a second pass.
    ///
    /// - Parameters:
    ///   - bytes: Content bytes to scan. Should exclude any NUL terminator.
    ///   - primary: The primary separator byte. POSIX `0x2F`; Windows `0x5C`.
    ///   - alt: An alternate separator byte. `nil` on POSIX; `0x2F` on Windows.
    /// - Returns: Index of the last-occurring separator byte, or `nil` if
    ///   neither separator appears in `bytes`.
    @inlinable
    public static func lastSeparatorIndex(
        in bytes: Span<Path.Char>,
        primary: Path.Char,
        alt: Path.Char? = nil
    ) -> Int? {
        var i = bytes.count - 1
        while i >= 0 {
            let b = bytes[i]
            if b == primary {
                return i
            }
            if let alt, b == alt {
                return i
            }
            i -= 1
        }
        return nil
    }
}

#endif
