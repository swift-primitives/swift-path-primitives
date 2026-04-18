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

// MARK: - Path.Modification

extension Path {
    /// The construction API for path views — produces an owned `Path` by
    /// joining two views with a separator.
    ///
    /// Separate from `Path.Decomposition` (which returns zero-allocation
    /// sub-views) because the return shape is fundamentally different:
    /// appending produces a newly-allocated owned path, whereas parent /
    /// component produce borrowed sub-views.
    ///
    /// ## Design
    ///
    /// Static requirement per [IMPL-023] keeps core logic callable from any
    /// layer without going through `self`. The protocol extension default
    /// provides the single-word instance API per [API-NAME-002]:
    ///
    /// ```swift
    /// path.view.appending(other)  // Path — one allocation
    /// ```
    public protocol Modification: ~Copyable, ~Escapable {
        /// Creates a new owned path: `view` + separator + `other` + NUL.
        ///
        /// One allocation. If `view` already ends with a separator, no
        /// additional separator is inserted.
        static func appending(_ view: borrowing Self, _ other: borrowing Self) -> Path
    }
}

// MARK: - Instance API (Modification Defaults)

extension Path.Modification where Self: ~Copyable, Self: ~Escapable {
    /// Creates a new owned path by joining with `other`.
    ///
    /// One allocation. Handles trailing separator deduplication.
    @inlinable
    public borrowing func appending(_ other: borrowing Self) -> Path {
        Self.appending(self, other)
    }
}

#endif
