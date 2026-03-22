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

internal import String_Primitives
public import Memory_Primitives_Core
public import Identity_Primitives

// MARK: - Viewable Conformance

extension Path: Viewable {}

// MARK: - View

extension Path {
    /// Non-escapable view of a null-terminated path.
    ///
    /// Does not own storage. Valid only for the duration of the borrowing scope.
    /// The referenced memory must remain valid and unmodified while borrowed.
    ///
    /// `~Escapable` enforces at compile time that this value cannot escape
    /// the scope where it was created — preventing use-after-free bugs.
    ///
    /// Invariant: Points to a null-terminated sequence.
    @safe
    public struct View: ~Copyable, ~Escapable {
        /// The underlying pointer to the null-terminated sequence.
        public let pointer: UnsafePointer<Char>

        /// The length in code units, excluding the null terminator.
        public let count: Int

        /// Creates a view from a pointer and count.
        ///
        /// The lifetime of this `View` value is tied to the lifetime of `pointer`.
        ///
        /// - Precondition: `pointer` must point to a null-terminated sequence.
        @inlinable
        @_lifetime(borrow pointer)
        public init(_ pointer: UnsafePointer<Path.Char>, count: Int) {
            #if DEBUG
            unsafe Self.debugValidateTermination(pointer)
            #endif
            unsafe (self.pointer = pointer)
            self.count = count
        }
    }
}

// MARK: - Debug Validation

#if DEBUG
extension Path.View {
    /// Maximum bytes to scan when validating termination in debug builds.
    @usableFromInline
    internal static let maxDebugScanLength = 16 * 1024 * 1024 // 16 MiB

    @unsafe
    @usableFromInline
    internal static func debugValidateTermination(_ pointer: UnsafePointer<Path.Char>) {
        var current = unsafe pointer
        var scanned = 0
        while scanned < maxDebugScanLength {
            if unsafe current.pointee == 0 {
                return // Valid: found terminator
            }
            unsafe (current = current.successor())
            scanned += 1
        }
        assertionFailure("Path.View: pointer does not appear to be null-terminated within \(maxDebugScanLength) code units")
    }
}
#endif

// MARK: - Access

extension Path.View {
    /// Executes a closure with the underlying pointer.
    @unsafe
    @inlinable
    public borrowing func withUnsafePointer<R: ~Copyable, E: Swift.Error>(
        _ body: (UnsafePointer<Path.Char>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe body(pointer)
    }

    /// Returns a `Span` view of the path content, excluding the null terminator.
    @inlinable
    public var span: Span<Path.Char> {
        @_lifetime(copy self) borrowing get {
            let span = unsafe Span(_unsafeStart: pointer, count: count)
            return unsafe _overrideLifetime(span, copying: self)
        }
    }
}

// MARK: - View Property

extension Path {
    /// Returns a view of this path.
    ///
    /// The lifetime of the returned `View` is tied to `self`.
    @inlinable
    public var view: View {
        @_lifetime(borrow self) borrowing get {
            let view = unsafe View(_storage.unsafeBaseAddress, count: _storage.count)
            return unsafe _overrideLifetime(view, borrowing: self)
        }
    }
}

#endif
