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

    // MARK: - Path.Decomposition

    extension Path {
        /// The decomposition API for path views — zero-allocation sub-views over
        /// the path's bytes.
        ///
        /// Platform packages conform `Path.Borrowed` to this protocol with
        /// platform-specific separator logic (e.g., `/` for POSIX; `/` and
        /// `\` for Windows). The protocol extension provides instance-level
        /// defaults for consumer convenience.
        ///
        /// For owning-type appending (producing a new owned `Path` from two views),
        /// see `Path.Modification`.
        ///
        /// ## Design
        ///
        /// Static requirements per [IMPL-023] keep core logic callable from
        /// any layer without going through `self`. Protocol extension defaults
        /// provide the single-word instance API per [API-NAME-002]:
        ///
        /// ```swift
        /// path.view.parent     // Swift.Span<Char>?  — zero-alloc, NOT null-terminated
        /// path.view.component  // Swift.Span<Char>   — zero-alloc, IS null-terminated
        /// ```
        ///
        /// Binary decomposition: `parent` + `component` = path.
        ///
        /// ## Null-Termination Awareness
        ///
        /// Per [IMPL-081], return types reflect which invariants survive
        /// sub-slicing:
        ///
        /// - `parent` returns `Swift.Span<Char>?` because a prefix ending at the
        ///   last separator is NOT null-terminated — the separator byte at
        ///   the boundary is excluded. Callers construct `Path(span)` when
        ///   syscall use requires null termination.
        /// - `component` returns `Swift.Span<Char>` because the suffix from the
        ///   last separator to the end IS null-terminated — it shares the
        ///   original path's terminator.
        public protocol Decomposition: ~Copyable, ~Escapable {
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
            static func parent(of view: borrowing Self) -> Swift.Span<Char>?

            /// Returns the last component bytes as a sub-view of `view`.
            ///
            /// For paths without separators, returns the full view. For paths
            /// ending in a separator, the component is empty.
            ///
            /// The returned span IS null-terminated — it shares the original
            /// path's terminator byte.
            @_lifetime(copy view)
            static func component(of view: borrowing Self) -> Swift.Span<Char>
        }
    }

    // MARK: - Instance API (Decomposition Defaults)

    extension Path.Decomposition where Self: ~Copyable, Self: ~Escapable {
        /// The parent directory bytes.
        ///
        /// `nil` for roots and bare filenames. Zero-allocation sub-view. NOT null-terminated.
        @inlinable
        public var parent: Swift.Span<Char>? {
            @_lifetime(copy self)
            borrowing get { Self.parent(of: self) }
        }

        /// The last component bytes.
        ///
        /// Shares the terminator of the original path. Zero-allocation sub-view.
        /// IS null-terminated.
        @inlinable
        public var component: Swift.Span<Char> {
            @_lifetime(copy self)
            borrowing get { Self.component(of: self) }
        }
    }

#endif
