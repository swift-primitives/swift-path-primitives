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

// MARK: - Path.Protocol

extension Path {
    /// The decomposition and construction API for path views.
    ///
    /// Platform packages conform `Path.View` to this protocol with
    /// platform-specific separator logic (e.g., `/` for POSIX; `/` and
    /// `\` for Windows). The protocol extension provides instance-level
    /// defaults for consumer convenience.
    ///
    /// ## Design
    ///
    /// Static requirements per [IMPL-023] keep core logic callable from
    /// any layer without going through `self`. Protocol extension defaults
    /// provide the single-word instance API per [API-NAME-002]:
    ///
    /// ```swift
    /// path.view.parent           // Span<Char>?  — zero-alloc, NOT null-terminated
    /// path.view.component        // Span<Char>   — zero-alloc, IS null-terminated
    /// path.view.appending(other) // Path         — one allocation
    /// ```
    ///
    /// Binary decomposition: `parent` + `component` = path.
    ///
    /// ## Null-Termination Awareness
    ///
    /// Per [IMPL-081], return types reflect which invariants survive
    /// sub-slicing:
    ///
    /// - `parent` returns `Span<Char>?` because a prefix ending at the
    ///   last separator is NOT null-terminated — the separator byte at
    ///   the boundary is excluded. Callers construct `Path(span)` when
    ///   syscall use requires null termination.
    /// - `component` returns `Span<Char>` because the suffix from the
    ///   last separator to the end IS null-terminated — it shares the
    ///   original path's terminator.
    public protocol `Protocol`: ~Copyable, ~Escapable {
        /// The path character type.
        ///
        /// - POSIX: `UInt8` (UTF-8 code units)
        /// - Windows: `UInt16` (UTF-16 code units)
        associatedtype Char

        /// Returns the parent directory bytes as a sub-view of `view`.
        ///
        /// Returns `nil` for roots and bare filenames (no separator present
        /// before the last component).
        ///
        /// The returned span is NOT null-terminated — the separator byte
        /// at the boundary is excluded.
        @_lifetime(copy view)
        static func parent(of view: borrowing Self) -> Span<Char>?

        /// Returns the last component bytes as a sub-view of `view`.
        ///
        /// For paths without separators, returns the full view. For paths
        /// ending in a separator, the component is empty.
        ///
        /// The returned span IS null-terminated — it shares the original
        /// path's terminator byte.
        @_lifetime(copy view)
        static func component(of view: borrowing Self) -> Span<Char>

        /// Creates a new owned path: `view` + separator + `other` + NUL.
        ///
        /// One allocation. If `view` already ends with a separator, no
        /// additional separator is inserted.
        static func appending(_ view: borrowing Self, _ other: borrowing Self) -> Path
    }
}

// MARK: - Instance API (Protocol Extension Defaults)

extension Path.`Protocol` where Self: ~Copyable, Self: ~Escapable {
    /// The parent directory bytes. `nil` for roots and bare filenames.
    ///
    /// Zero-allocation sub-view. NOT null-terminated.
    @inlinable
    public var parent: Span<Char>? {
        @_lifetime(copy self)
        borrowing get { Self.parent(of: self) }
    }

    /// The last component bytes. Shares the original path's terminator.
    ///
    /// Zero-allocation sub-view. IS null-terminated.
    @inlinable
    public var component: Span<Char> {
        @_lifetime(copy self)
        borrowing get { Self.component(of: self) }
    }

    /// Creates a new owned path by joining with `other`.
    ///
    /// One allocation. Handles trailing separator deduplication.
    @inlinable
    public borrowing func appending(_ other: borrowing Self) -> Path {
        Self.appending(self, other)
    }
}

#endif
