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

    public import Tagged_Primitives
    internal import Memory_Contiguous_Primitives
    public import String_Primitives

    // MARK: - Nested Type Aliases

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {
        /// Errors from path string conversion.
        public typealias ConversionError = Path.ConversionError

        /// String-to-path conversion namespace.
        public typealias String = Path.String

        /// Path resolution namespace.
        public typealias Resolution = Path.Resolution

        /// Path canonicalization namespace.
        public typealias Canonical = Path.Canonical
    }

    // MARK: - Static Members

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {
        /// Nested accessor for scoped string-to-path conversions.
        @inlinable
        public static var scope: Path.String.Scope { Path.String.Scope() }
    }

    // MARK: - Initialization

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {
        /// Creates a tagged path by adopting an existing allocation.
        ///
        /// Takes ownership of `pointer`. The caller must not deallocate it.
        @inlinable
        public init(adopting pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
            unsafe self.init(_unchecked: Path(adopting: pointer, count: count))
        }

        /// Creates a tagged path by copying from a borrowed string view.
        @inlinable
        public init(copying view: borrowing String_Primitives.String.Borrowed) {
            self.init(_unchecked: Path(copying: view))
        }

        /// Creates a tagged path by copying from a span of path bytes.
        ///
        /// Allocates new storage, copies the span's content, and appends a
        /// null terminator. The span is typically obtained from
        /// ``Path/Borrowed/span`` or ``Path/Protocol/parent`` — sub-views
        /// of an existing path that need to become owned for syscall use.
        @inlinable
        public init(_ span: Swift.Span<Path.Char>) {
            self.init(_unchecked: Path(span))
        }
    }

    // MARK: - Properties

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {
        /// The length of the path in code units, excluding the null terminator.
        @inlinable
        public var count: Int { underlying.count }

        // `view` (Path.Borrowed) and `content` (Swift.Span<Path.Char>) are
        // intentionally absent on Tagged<Tag, Path> — they would need to
        // chain a lifetime-dependent return through Tagged's `_read`-yielded
        // `underlying` accessor, which Swift 6.3.1's lifetime checker does
        // not currently support. Consumers borrow Path's APIs by accessing
        // the underlying directly via the Tagged.underlying yield in their
        // own scope. Restoring the convenience accessors here is in scope
        // for a follow-up that adds a borrow-returning Tagged accessor for
        // ~Copyable Underlying or refactors Path's `view`/`content` to
        // closure-based shapes.
    }

    // MARK: - Ownership Transfer

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {
        /// Transfers ownership of the underlying buffer to the caller.
        ///
        /// Returns the pointer and count. The caller is responsible for deallocation.
        /// This instance is consumed and will not deallocate the buffer.
        @unsafe
        @inlinable
        public consuming func take() -> (pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
            unsafe self.map { (p: consuming Path) in unsafe p.take() }.underlying
        }
    }

#endif
