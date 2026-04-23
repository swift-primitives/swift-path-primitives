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
internal import Memory_Primitives_Core
public import String_Primitives

// MARK: - Nested Type Aliases

extension Tagged where RawValue == Path, Tag: ~Copyable {
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

extension Tagged where RawValue == Path, Tag: ~Copyable {
    /// Nested accessor for scoped string-to-path conversions.
    @inlinable
    public static var scope: Path.String.Scope { Path.String.Scope() }
}

// MARK: - Initialization

extension Tagged where RawValue == Path, Tag: ~Copyable {
    /// Creates a tagged path by adopting an existing allocation.
    ///
    /// Takes ownership of `pointer`. The caller must not deallocate it.
    @inlinable
    public init(adopting pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
        unsafe self.init(__unchecked: (), Path(adopting: pointer, count: count))
    }

    /// Creates a tagged path by copying from a borrowed string view.
    @inlinable
    public init(copying view: borrowing String_Primitives.String.Borrowed) {
        self.init(__unchecked: (), Path(copying: view))
    }

    /// Creates a tagged path by copying from a span of path bytes.
    ///
    /// Allocates new storage, copies the span's content, and appends a
    /// null terminator. The span is typically obtained from
    /// ``Path/Borrowed/span`` or ``Path/Protocol/parent`` — sub-views
    /// of an existing path that need to become owned for syscall use.
    @inlinable
    public init(_ span: Span<Path.Char>) {
        self.init(__unchecked: (), Path(span))
    }
}

// MARK: - Properties

extension Tagged where RawValue == Path, Tag: ~Copyable {
    /// The length of the path in code units, excluding the null terminator.
    @inlinable
    public var count: Int { rawValue.count }

    /// Returns a borrowed view of this path.
    @inlinable
    public var view: Path.Borrowed {
        @_lifetime(borrow self) borrowing get {
            let v = rawValue.view
            return unsafe _overrideLifetime(v, borrowing: self)
        }
    }

    /// Returns a `Span` view of the path content, excluding the null terminator.
    ///
    /// Two-level `@_lifetime` chain:
    /// 1. `rawValue.content` borrows from `rawValue` (stored property)
    /// 2. `_overrideLifetime` re-parents the Span's lifetime to `self`
    @inlinable
    public var content: Span<Path.Char> {
        @_lifetime(borrow self) borrowing get {
            let s = rawValue.content
            return unsafe _overrideLifetime(s, borrowing: self)
        }
    }
}


// MARK: - Ownership Transfer

extension Tagged where RawValue == Path, Tag: ~Copyable {
    /// Transfers ownership of the underlying buffer to the caller.
    ///
    /// Returns the pointer and count. The caller is responsible for deallocation.
    /// This instance is consumed and will not deallocate the buffer.
    @unsafe
    @inlinable
    public consuming func take() -> (pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
        unsafe rawValue.take()
    }
}

#endif
