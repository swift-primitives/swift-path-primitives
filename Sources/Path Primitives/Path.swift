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

public import String_Primitives
public import Memory_Primitives_Core

/// An owned, lifetime-safe path wrapper for syscall use.
///
/// Owns a null-terminated contiguous memory region and
/// deallocates it on destruction. Storage is backed by
/// `Memory.Contiguous<Char>` for O(1) count/span access.
///
/// - All raw pointer access is through scoped closures that prevent escape
/// - The type is `~Copyable` to prevent implicit duplication
///
/// ## Platform Notes
///
/// - On POSIX: Uses narrow strings (`UInt8`/UTF-8)
/// - On Windows: Uses wide strings (`UInt16`/UTF-16)
///
/// ## Sendability
///
/// This type is `@unchecked Sendable` because:
/// - The buffer is uniquely owned by this value (`~Copyable` prevents aliasing)
/// - The buffer is immutable after initialization
@safe
public struct Path: ~Copyable, @unchecked Sendable {
    /// Internal storage for the null-terminated contiguous memory region.
    @usableFromInline
    internal let _storage: Memory_Primitives_Core.Memory.Contiguous<String_Primitives.String.Char>
}

// MARK: - Platform Character Type

extension Path {
    /// Platform-native path character type.
    ///
    /// Aliases `String_Primitives.String.Char`:
    /// - POSIX (macOS, Linux): `UInt8` (UTF-8 code units)
    /// - Windows: `UInt16` (UTF-16 code units)
    public typealias Char = String_Primitives.String.Char
}

// MARK: - Initialization

extension Path {
    /// Creates an owned path by adopting an existing allocation.
    ///
    /// Takes ownership of `pointer`. The caller must not deallocate it.
    ///
    /// - Parameters:
    ///   - pointer: A pointer to a null-terminated sequence. Ownership is transferred.
    ///   - count: The length in code units, excluding the null terminator.
    ///
    /// - Precondition: `pointer` must point to at least `count + 1` allocated code units.
    /// - Precondition: `pointer[count]` must be the null terminator.
    @inlinable
    public init(adopting pointer: UnsafeMutablePointer<Char>, count: Int) {
        #if DEBUG
        precondition(unsafe pointer[count] == String_Primitives.String.terminator, "Path: adopted buffer must be null-terminated")
        #endif
        unsafe self._storage = Memory_Primitives_Core.Memory.Contiguous(adopting: pointer, count: count)
    }

    /// Creates an owned path by copying from a string view.
    ///
    /// Allocates new storage and copies the content.
    ///
    /// - Parameter view: A view into a null-terminated string to copy from.
    @inlinable
    public init(copying view: borrowing String_Primitives.String.View) {
        let length = view.length
        let buffer = UnsafeMutablePointer<Char>.allocate(capacity: length + 1)
        unsafe buffer.initialize(from: view.pointer, count: length)
        (unsafe buffer)[length] = String_Primitives.String.terminator
        unsafe self._storage = Memory.Contiguous(adopting: buffer, count: length)
    }
}

// MARK: - Properties

extension Path {
    /// The length of the path in code units, excluding the null terminator.
    ///
    /// O(1) complexity.
    @inlinable
    public var count: Int { _storage.count }

    /// Returns a `Span` view of the path content, excluding the null terminator.
    ///
    /// O(1) complexity. The span's lifetime is tied to this path.
    @inlinable
    public var bytes: Span<Char> {
        @_lifetime(borrow self) borrowing get {
            let s = _storage.span
            return unsafe _overrideLifetime(s, borrowing: self)
        }
    }
}

// MARK: - Scoped Pointer Access

extension Path {
    /// Executes a closure with the underlying C string pointer.
    ///
    /// The closure-based API ensures the pointer cannot escape beyond the call site.
    @inlinable
    @unsafe
    public borrowing func withUnsafeCString<R: ~Copyable, E: Swift.Error>(
        _ body: (UnsafePointer<Char>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe body(_storage.unsafeBaseAddress)
    }
}

// MARK: - Ownership Transfer

extension Path {
    /// Transfers ownership of the underlying buffer to the caller.
    ///
    /// Returns the pointer and count. The caller is responsible for deallocation.
    /// This instance is consumed and will not deallocate the buffer.
    @unsafe
    @inlinable
    public consuming func take() -> (pointer: UnsafeMutablePointer<Char>, count: Int) {
        unsafe _storage.take()
    }
}

// MARK: - Conversion Errors

extension Path {
    /// Errors that can occur during path string conversion.
    public enum ConversionError: Swift.Error, Sendable, Equatable {
        /// The string contains an interior NUL byte, which would truncate the path.
        case interiorNUL
    }
}

#endif
