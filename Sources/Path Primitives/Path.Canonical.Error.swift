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

public import Error_Primitives

extension Path.Canonical {
    /// Errors from path canonicalization operations.
    public enum Error: Swift.Error, Sendable {
        /// Path resolution error (not found, loop, etc.).
        case path(Path.Resolution.Error)

        /// Platform-specific error.
        ///
        /// Permission-denied errors surface as `.platform(...)` with the
        /// underlying errno (e.g., `EACCES`, `EPERM` on POSIX). Consumers
        /// that need to distinguish permission errors can pattern-match
        /// on the platform code.
        case platform(Error_Primitives.Error)
    }
}

// MARK: - Equatable

extension Path.Canonical.Error: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.path(let l), .path(let r)): return l == r
        case (.platform(let l), .platform(let r)): return l == r
        default: return false
        }
    }
}

// MARK: - CustomStringConvertible

extension Path.Canonical.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .path(let e): return "path canonicalization: \(e)"
        case .platform(let e): return "path canonicalization: \(e)"
        }
    }
}

#endif
