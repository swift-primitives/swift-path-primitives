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

// MARK: - String Namespace

extension Path {
    /// Namespace for string-to-path conversion operations.
    public enum String {
        /// Namespace for conversion operations.
        public enum Conversion {
            /// Errors that can occur during string-to-path conversion.
            public enum Error: Swift.Error, Sendable, Equatable {
                /// The string contains an interior NUL byte at the given index.
                ///
                /// Paths must not contain NUL bytes except as the terminator. An interior
                /// NUL would cause the path to be silently truncated when passed to syscalls.
                ///
                /// - Parameter index: For multi-path operations, indicates which argument
                ///   (0-based) contained the interior NUL. For single-path operations, always 0.
                case interiorNUL(index: Int)
            }
        }

        /// Typed error wrapper for string-to-path operations.
        ///
        /// This error type composes conversion failures with body failures,
        /// enabling 100% typed throws without existentials.
        ///
        /// ## Design
        /// - Conversion errors (interior NUL, encoding issues) are wrapped in `.conversion`.
        /// - Body errors are wrapped in `.body(E)`.
        /// - This is the only place where both failure domains exist in the public API.
        public enum Error<Body: Swift.Error>: Swift.Error {
            /// String-to-path conversion failed.
            case conversion(Conversion.Error)

            /// The body closure threw an error.
            case body(Body)
        }
    }
}

// MARK: - Error Conveniences

extension Path.String.Error: Sendable where Body: Sendable {}

extension Path.String.Error: Equatable where Body: Equatable {}

extension Path.String.Error {
    /// Returns the body error if this is a `.body` case, otherwise `nil`.
    @inlinable
    public var body: Body? {
        if case .body(let e) = self { return e }
        return nil
    }

    /// Returns the conversion error if this is a `.conversion` case, otherwise `nil`.
    @inlinable
    public var conversion: Path.String.Conversion.Error? {
        if case .conversion(let e) = self { return e }
        return nil
    }

    /// Maps the body case to a different error type.
    ///
    /// The `.conversion` case is preserved as-is.
    @inlinable
    public func mapBody<NewBody: Swift.Error>(
        _ transform: (Body) -> NewBody
    ) -> Path.String.Error<NewBody> {
        switch self {
        case .conversion(let e): return .conversion(e)
        case .body(let e): return .body(transform(e))
        }
    }
}

// MARK: - Scope Accessor

extension Path {
    /// Nested accessor for scoped string-to-path conversions.
    ///
    /// Operations use nested accessors for path and array handling:
    ///
    /// ```swift
    /// // Single path
    /// try Path.scope("/tmp/file.txt") { path in
    ///     try someOperation(path: path)
    /// }
    ///
    /// // Two paths
    /// try Path.scope("/src", "/dst") { src, dst in
    ///     try someOperation(from: src, to: dst)
    /// }
    ///
    /// // String arrays (for argv/envp)
    /// try Path.scope.array(["/bin/sh", "-c", "echo hello"]) { argv in
    ///     // argv is UnsafePointer<UnsafePointer<Path.Char>?> (NULL-terminated)
    /// }
    /// ```
    @inlinable
    public static var scope: String.Scope { String.Scope() }
}

// MARK: - Scope Type

extension Path.String {
    /// Namespace for scoped string-to-path operations.
    public struct Scope {
        @inlinable
        public init() {}
    }
}

// MARK: - Single Path

extension Path.String.Scope {
    /// Executes a closure with a scoped path view converted from a String.
    ///
    /// The view is valid only for the duration of the closure and cannot escape.
    ///
    /// - Parameters:
    ///   - string: The path string (UTF-8 on POSIX, UTF-16 on Windows).
    ///   - body: A closure that receives the scoped path view.
    /// - Returns: The value returned by the closure.
    /// - Throws: `String.Error.conversion` if the string contains NUL bytes,
    ///   or `String.Error.body` wrapping the error from the closure.
    @_disfavoredOverload
    @inlinable
    public func callAsFunction<S: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ string: S,
        _ body: (borrowing Path.View) throws(E) -> R
    ) throws(Path.String.Error<E>) -> R {
        var count = 0
        let buffer: UnsafeMutablePointer<Path.Char>
        do {
            try unsafe (buffer = _allocateBuffer(string, index: 0, count: &count))
        } catch {
            throw .conversion(error)
        }
        let path = unsafe Path(adopting: buffer, count: count)
        let view = path.view
        do {
            return try body(view)
        } catch {
            throw .body(error)
        }
    }

    /// Pass-through overload: when body already throws our wrapper type, rethrow directly.
    ///
    /// This prevents nested wrappers like `Error<Error<E>>` when scopes are composed.
    /// Overload resolution selects this when the body's throw type is `Path.String.Error<E>`.
    @inlinable
    public func callAsFunction<S: StringProtocol, NestedBody: Swift.Error, R: ~Copyable>(
        _ string: S,
        _ body: (borrowing Path.View) throws(Path.String.Error<NestedBody>) -> R
    ) throws(Path.String.Error<NestedBody>) -> R {
        var count = 0
        let buffer: UnsafeMutablePointer<Path.Char>
        do {
            try unsafe (buffer = _allocateBuffer(string, index: 0, count: &count))
        } catch {
            throw .conversion(error)
        }
        let path = unsafe Path(adopting: buffer, count: count)
        return try body(path.view)
    }

    /// Executes a closure with a scoped path view (non-throwing body).
    @inlinable
    public func callAsFunction<S: StringProtocol, R: ~Copyable>(
        _ string: S,
        _ body: (borrowing Path.View) -> R
    ) throws(Path.String.Conversion.Error) -> R {
        var count = 0
        let buffer = try unsafe _allocateBuffer(string, index: 0, count: &count)
        let path = unsafe Path(adopting: buffer, count: count)
        return body(path.view)
    }
}

// MARK: - Two Paths

extension Path.String.Scope {
    /// Executes a closure with two scoped path views converted from Strings.
    @inlinable
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ string1: S1,
        _ string2: S2,
        _ body: (borrowing Path.View, borrowing Path.View) throws(E) -> R
    ) throws(Path.String.Error<E>) -> R {
        var count1 = 0
        var count2 = 0
        let buffer1: UnsafeMutablePointer<Path.Char>
        let buffer2: UnsafeMutablePointer<Path.Char>
        do {
            try unsafe (buffer1 = _allocateBuffer(string1, index: 0, count: &count1))
        } catch {
            throw .conversion(error)
        }
        let path1 = unsafe Path(adopting: buffer1, count: count1)
        do {
            try unsafe (buffer2 = _allocateBuffer(string2, index: 1, count: &count2))
        } catch {
            throw .conversion(error)
        }
        let path2 = unsafe Path(adopting: buffer2, count: count2)
        let view1 = path1.view
        let view2 = path2.view
        do {
            return try body(view1, view2)
        } catch {
            throw .body(error)
        }
    }

    /// Executes a closure with two scoped path views (non-throwing body).
    @inlinable
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, R: ~Copyable>(
        _ string1: S1,
        _ string2: S2,
        _ body: (borrowing Path.View, borrowing Path.View) -> R
    ) throws(Path.String.Conversion.Error) -> R {
        var count1 = 0
        var count2 = 0
        let buffer1 = try unsafe _allocateBuffer(string1, index: 0, count: &count1)
        let path1 = unsafe Path(adopting: buffer1, count: count1)
        let buffer2 = try unsafe _allocateBuffer(string2, index: 1, count: &count2)
        let path2 = unsafe Path(adopting: buffer2, count: count2)
        return body(path1.view, path2.view)
    }
}

// MARK: - Three Paths

extension Path.String.Scope {
    /// Executes a closure with three scoped path views converted from Strings.
    @inlinable
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, S3: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ string1: S1,
        _ string2: S2,
        _ string3: S3,
        _ body: (borrowing Path.View, borrowing Path.View, borrowing Path.View) throws(E) -> R
    ) throws(Path.String.Error<E>) -> R {
        var count1 = 0
        var count2 = 0
        var count3 = 0
        let buffer1: UnsafeMutablePointer<Path.Char>
        let buffer2: UnsafeMutablePointer<Path.Char>
        let buffer3: UnsafeMutablePointer<Path.Char>
        do {
            try unsafe (buffer1 = _allocateBuffer(string1, index: 0, count: &count1))
        } catch {
            throw .conversion(error)
        }
        let path1 = unsafe Path(adopting: buffer1, count: count1)
        do {
            try unsafe (buffer2 = _allocateBuffer(string2, index: 1, count: &count2))
        } catch {
            throw .conversion(error)
        }
        let path2 = unsafe Path(adopting: buffer2, count: count2)
        do {
            try unsafe (buffer3 = _allocateBuffer(string3, index: 2, count: &count3))
        } catch {
            throw .conversion(error)
        }
        let path3 = unsafe Path(adopting: buffer3, count: count3)
        let view1 = path1.view
        let view2 = path2.view
        let view3 = path3.view
        do {
            return try body(view1, view2, view3)
        } catch {
            throw .body(error)
        }
    }

    /// Executes a closure with three scoped path views (non-throwing body).
    @inlinable
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, S3: StringProtocol, R: ~Copyable>(
        _ string1: S1,
        _ string2: S2,
        _ string3: S3,
        _ body: (borrowing Path.View, borrowing Path.View, borrowing Path.View) -> R
    ) throws(Path.String.Conversion.Error) -> R {
        var count1 = 0
        var count2 = 0
        var count3 = 0
        let buffer1 = try unsafe _allocateBuffer(string1, index: 0, count: &count1)
        let path1 = unsafe Path(adopting: buffer1, count: count1)
        let buffer2 = try unsafe _allocateBuffer(string2, index: 1, count: &count2)
        let path2 = unsafe Path(adopting: buffer2, count: count2)
        let buffer3 = try unsafe _allocateBuffer(string3, index: 2, count: &count3)
        let path3 = unsafe Path(adopting: buffer3, count: count3)
        return body(path1.view, path2.view, path3.view)
    }
}

// MARK: - Array Accessor

extension Path.String.Scope {
    /// Nested accessor for string array operations.
    ///
    /// Converts string arrays to NULL-terminated platform string arrays:
    /// - **POSIX:** UTF-8 (`CChar*`), suitable for exec* and posix_spawn
    /// - **Windows:** UTF-16 (`UInt16*`), suitable for Windows APIs
    ///
    /// The closure receives `UnsafePointer<UnsafePointer<Path.Char>?>`.
    @inlinable
    public var array: Array { Array() }
}

// MARK: - Array Type

extension Path.String.Scope {
    /// Namespace for scoped string array operations.
    public struct Array {
        @inlinable
        public init() {}
    }
}

// MARK: - Single Array

extension Path.String.Scope.Array {
    /// Executes a closure with a scoped NULL-terminated platform string array.
    ///
    /// Converts an array of Swift strings to a NULL-terminated array of platform strings:
    /// - **POSIX:** UTF-8 (`CChar*`), suitable for exec* and posix_spawn
    /// - **Windows:** UTF-16 (`UInt16*`), suitable for Windows APIs
    ///
    /// - Parameters:
    ///   - strings: The strings to convert.
    ///   - body: A closure that receives the NULL-terminated array pointer.
    /// - Returns: The value returned by the closure.
    /// - Throws: `String.Error.conversion` if any string contains NUL bytes,
    ///   or `String.Error.body` wrapping the error from the closure.
    @_disfavoredOverload
    @inlinable
    @unsafe
    public func callAsFunction<S: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ strings: [S],
        _ body: (UnsafePointer<UnsafePointer<Path.Char>?>) throws(E) -> R
    ) throws(Path.String.Error<E>) -> R {
        var buffers: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers.reserveCapacity(strings.count)
        defer { for i in unsafe (0..<buffers.count) { unsafe buffers[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers.append(buffer)
        }

        let pointerArray = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings.count + 1
        )
        defer { unsafe pointerArray.deallocate() }

        for i in unsafe (0..<buffers.count) {
            unsafe (pointerArray[i] = UnsafePointer(buffers[i]))
        }
        unsafe pointerArray[strings.count] = nil

        do {
            return try unsafe body(UnsafePointer(pointerArray))
        } catch {
            throw .body(error)
        }
    }

    /// Pass-through overload: when body already throws our wrapper type, rethrow directly.
    ///
    /// This prevents nested wrappers like `Error<Error<E>>` when scopes are composed.
    /// Overload resolution selects this when the body's throw type is `Path.String.Error<E>`.
    @inlinable
    @unsafe
    public func callAsFunction<S: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ strings: [S],
        _ body: (UnsafePointer<UnsafePointer<Path.Char>?>) throws(Path.String.Error<E>) -> R
    ) throws(Path.String.Error<E>) -> R {
        var buffers: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers.reserveCapacity(strings.count)
        defer { for i in unsafe (0..<buffers.count) { unsafe buffers[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers.append(buffer)
        }

        let pointerArray = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings.count + 1
        )
        defer { unsafe pointerArray.deallocate() }

        for i in unsafe (0..<buffers.count) {
            unsafe (pointerArray[i] = UnsafePointer(buffers[i]))
        }
        unsafe pointerArray[strings.count] = nil

        return try unsafe body(UnsafePointer(pointerArray))
    }

    /// Executes a closure with a scoped NULL-terminated platform string array (non-throwing body).
    @inlinable
    @unsafe
    public func callAsFunction<S: StringProtocol, R: ~Copyable>(
        _ strings: [S],
        _ body: (UnsafePointer<UnsafePointer<Path.Char>?>) -> R
    ) throws(Path.String.Conversion.Error) -> R {
        var buffers: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers.reserveCapacity(strings.count)
        defer { for i in unsafe (0..<buffers.count) { unsafe buffers[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings.enumerated() {
            let buffer = try unsafe _allocateBuffer(string, index: index, count: &unusedCount)
            unsafe buffers.append(buffer)
        }

        let pointerArray = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings.count + 1
        )
        defer { unsafe pointerArray.deallocate() }

        for i in unsafe (0..<buffers.count) {
            unsafe (pointerArray[i] = UnsafePointer(buffers[i]))
        }
        unsafe pointerArray[strings.count] = nil

        return unsafe body(UnsafePointer(pointerArray))
    }
}

// MARK: - Two Arrays

extension Path.String.Scope.Array {
    /// Executes a closure with two scoped NULL-terminated platform string arrays.
    ///
    /// Useful for posix_spawn which needs both argv and envp.
    @_disfavoredOverload
    @inlinable
    @unsafe
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ strings1: [S1],
        _ strings2: [S2],
        _ body: (UnsafePointer<UnsafePointer<Path.Char>?>, UnsafePointer<UnsafePointer<Path.Char>?>) throws(E) -> R
    ) throws(Path.String.Error<E>) -> R {
        var buffers1: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers1.reserveCapacity(strings1.count)
        defer { for i in unsafe (0..<buffers1.count) { unsafe buffers1[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings1.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers1.append(buffer)
        }

        var buffers2: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers2.reserveCapacity(strings2.count)
        defer { for i in unsafe (0..<buffers2.count) { unsafe buffers2[i].deallocate() } }

        for (index, string) in strings2.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: strings1.count + index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers2.append(buffer)
        }

        let pointerArray1 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings1.count + 1
        )
        defer { unsafe pointerArray1.deallocate() }

        let pointerArray2 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings2.count + 1
        )
        defer { unsafe pointerArray2.deallocate() }

        for i in unsafe (0..<buffers1.count) {
            unsafe (pointerArray1[i] = UnsafePointer(buffers1[i]))
        }
        unsafe pointerArray1[strings1.count] = nil

        for i in unsafe (0..<buffers2.count) {
            unsafe (pointerArray2[i] = UnsafePointer(buffers2[i]))
        }
        unsafe pointerArray2[strings2.count] = nil

        do {
            return try unsafe body(UnsafePointer(pointerArray1), UnsafePointer(pointerArray2))
        } catch {
            throw .body(error)
        }
    }

    /// Pass-through overload: when body already throws our wrapper type, rethrow directly.
    ///
    /// This prevents nested wrappers like `Error<Error<E>>` when scopes are composed.
    /// Overload resolution selects this when the body's throw type is `Path.String.Error<E>`.
    @inlinable
    @unsafe
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, E: Swift.Error, R: ~Copyable>(
        _ strings1: [S1],
        _ strings2: [S2],
        _ body: (
            UnsafePointer<UnsafePointer<Path.Char>?>,
            UnsafePointer<UnsafePointer<Path.Char>?>
        ) throws(Path.String.Error<E>) -> R
    ) throws(Path.String.Error<E>) -> R {
        var buffers1: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers1.reserveCapacity(strings1.count)
        defer { for i in unsafe (0..<buffers1.count) { unsafe buffers1[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings1.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers1.append(buffer)
        }

        var buffers2: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers2.reserveCapacity(strings2.count)
        defer { for i in unsafe (0..<buffers2.count) { unsafe buffers2[i].deallocate() } }

        for (index, string) in strings2.enumerated() {
            let buffer: UnsafeMutablePointer<Path.Char>
            do {
                try unsafe (buffer = _allocateBuffer(string, index: strings1.count + index, count: &unusedCount))
            } catch {
                throw .conversion(error)
            }
            unsafe buffers2.append(buffer)
        }

        let pointerArray1 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings1.count + 1
        )
        defer { unsafe pointerArray1.deallocate() }

        let pointerArray2 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings2.count + 1
        )
        defer { unsafe pointerArray2.deallocate() }

        for i in unsafe (0..<buffers1.count) {
            unsafe (pointerArray1[i] = UnsafePointer(buffers1[i]))
        }
        unsafe pointerArray1[strings1.count] = nil

        for i in unsafe (0..<buffers2.count) {
            unsafe (pointerArray2[i] = UnsafePointer(buffers2[i]))
        }
        unsafe pointerArray2[strings2.count] = nil

        return try unsafe body(UnsafePointer(pointerArray1), UnsafePointer(pointerArray2))
    }

    /// Executes a closure with two scoped NULL-terminated platform string arrays (non-throwing body).
    @inlinable
    @unsafe
    public func callAsFunction<S1: StringProtocol, S2: StringProtocol, R: ~Copyable>(
        _ strings1: [S1],
        _ strings2: [S2],
        _ body: (UnsafePointer<UnsafePointer<Path.Char>?>, UnsafePointer<UnsafePointer<Path.Char>?>) -> R
    ) throws(Path.String.Conversion.Error) -> R {
        var buffers1: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers1.reserveCapacity(strings1.count)
        defer { for i in unsafe (0..<buffers1.count) { unsafe buffers1[i].deallocate() } }

        var unusedCount = 0
        for (index, string) in strings1.enumerated() {
            let buffer = try unsafe _allocateBuffer(string, index: index, count: &unusedCount)
            unsafe buffers1.append(buffer)
        }

        var buffers2: [UnsafeMutablePointer<Path.Char>] = unsafe []
        unsafe buffers2.reserveCapacity(strings2.count)
        defer { for i in unsafe (0..<buffers2.count) { unsafe buffers2[i].deallocate() } }

        for (index, string) in strings2.enumerated() {
            let buffer = try unsafe _allocateBuffer(string, index: strings1.count + index, count: &unusedCount)
            unsafe buffers2.append(buffer)
        }

        let pointerArray1 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings1.count + 1
        )
        defer { unsafe pointerArray1.deallocate() }

        let pointerArray2 = unsafe UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
            capacity: strings2.count + 1
        )
        defer { unsafe pointerArray2.deallocate() }

        for i in unsafe (0..<buffers1.count) {
            unsafe (pointerArray1[i] = UnsafePointer(buffers1[i]))
        }
        unsafe pointerArray1[strings1.count] = nil

        for i in unsafe (0..<buffers2.count) {
            unsafe (pointerArray2[i] = UnsafePointer(buffers2[i]))
        }
        unsafe pointerArray2[strings2.count] = nil

        return unsafe body(UnsafePointer(pointerArray1), UnsafePointer(pointerArray2))
    }
}

// MARK: - Buffer Allocation Helper

/// Allocates a null-terminated platform string buffer from a Swift string.
///
/// - Parameters:
///   - string: The source string.
///   - index: Index for error reporting in multi-path operations.
///   - count: Output parameter receiving the length in code units (excluding terminator).
/// - Returns: A newly allocated buffer containing the null-terminated string.
/// - Throws: `interiorNUL` if the string contains an embedded NUL character.
///
/// ## Platform Encoding
///
/// - **POSIX:** UTF-8 (`CChar` / `Int8`)
/// - **Windows:** UTF-16LE (`UInt16`)
@usableFromInline
@unsafe
internal func _allocateBuffer<S: StringProtocol>(
    _ string: S,
    index: Int,
    count: inout Int
) throws(Path.String.Conversion.Error) -> UnsafeMutablePointer<Path.Char> {
    let s = Swift.String(string)
    #if os(Windows)
        let units = s.utf16
        for unit in units where unit == 0 {
            throw .interiorNUL(index: index)
        }
        count = units.count
        let bufferCapacity = count + 1
        let buffer = unsafe UnsafeMutablePointer<Path.Char>.allocate(capacity: bufferCapacity)
        var i = 0
        for unit in units {
            unsafe buffer[i] = unit
            i += 1
        }
        unsafe buffer[i] = 0
        return unsafe buffer
    #else
        let bytes = s.utf8
        for byte in bytes where byte == 0 {
            throw .interiorNUL(index: index)
        }
        count = bytes.count
        let bufferCapacity = count + 1
        let buffer = unsafe UnsafeMutablePointer<Path.Char>.allocate(capacity: bufferCapacity)
        var i = 0
        for byte in bytes {
            unsafe buffer[i] = byte
            i += 1
        }
        unsafe buffer[i] = 0
        return unsafe buffer
    #endif
}

#endif
