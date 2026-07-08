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
    public import Memory_Heap_Primitives

    /// An owned, lifetime-safe path wrapper for syscall use.
    ///
    /// Owns a null-terminated contiguous memory region and
    /// deallocates it on destruction. Storage is backed by
    /// `Memory.Heap` (raw bytes + a Path-owned typed `Char` view) for
    /// O(1) count/span access.
    ///
    /// - All raw pointer access is through scoped closures that prevent escape
    /// - The type is `~Copyable` to prevent implicit duplication
    ///
    /// ## Platform Notes
    ///
    /// - On POSIX: Uses narrow strings (`UInt8`/UTF-8)
    /// - On Windows: Uses wide strings (`UInt16`/UTF-16)
    ///
    /// ## Safety Invariant
    ///
    /// `Path` is `~Copyable` and owns an immutable `Memory.Heap` byte region.
    /// The buffer is uniquely owned and immutable after initialization.
    /// Cross-thread transfer via move relinquishes the sender's access.
    ///
    /// ## Intended Use
    ///
    /// - Moving a file path across isolation boundaries.
    ///
    /// ## Non-Goals
    ///
    /// - Not shareable; single-owner semantics.
    @safe
    public struct Path: ~Copyable, @unsafe @unchecked Sendable {
        /// Internal storage for the null-terminated contiguous memory region.
        ///
        /// `Memory.Heap` owns the raw allocation; its byte `capacity` is the tracked content length
        /// (`count * stride(Char)`), so `count = capacity / stride(Char)`. `Char` is `BitwiseCopyable`,
        /// so `Path` reinterprets the raw base as `Char` itself (`_base`). The null terminator sits one
        /// `Char` past the tracked capacity in the real allocation, exactly as before.
        @usableFromInline
        internal let _storage: Memory.Heap
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
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(pointer),
                capacity: Memory.Address.Count(UInt(count) * UInt(MemoryLayout<Char>.stride))
            )
        }

        /// Creates an owned path by copying from a borrowed string view.
        ///
        /// Allocates new storage and copies the content.
        ///
        /// - Parameter view: A borrowed view into a null-terminated string to copy from.
        @inlinable
        public init(copying view: borrowing String_Primitives.String.Borrowed) {
            let length = view.length
            let buffer = UnsafeMutablePointer<Char>.allocate(capacity: length + 1)
            unsafe buffer.initialize(from: view.pointer, count: length)
            (unsafe buffer)[length] = String_Primitives.String.terminator
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(buffer),
                capacity: Memory.Address.Count(UInt(length) * UInt(MemoryLayout<Char>.stride))
            )
        }

        /// Creates an owned path by copying from a span of path bytes.
        ///
        /// Allocates new storage, copies the span's content, and appends a
        /// null terminator. The span is typically obtained from
        /// ``Path/Protocol/parent`` or ``Path/Protocol/component`` —
        /// sub-views of an existing path that need to become owned for
        /// syscall use.
        ///
        /// - Parameter span: The path bytes to copy.
        @inlinable
        public init(_ span: Swift.Span<Char>) {
            let length = span.count
            let buffer = UnsafeMutablePointer<Char>.allocate(capacity: length + 1)
            for i in 0..<length {
                (unsafe buffer)[i] = span[i]
            }
            (unsafe buffer)[length] = String_Primitives.String.terminator
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(buffer),
                capacity: Memory.Address.Count(UInt(length) * UInt(MemoryLayout<Char>.stride))
            )
        }
    }

    // MARK: - Properties

    extension Path {
        /// The typed `Char` base of the owned region — the REAL origin pointer reinterpreted.
        ///
        /// Reads `_storage.unsafeBaseAddress` (the real, provenance-carrying origin pointer of the
        /// `Memory.Heap` region — never a pointer reconstituted from `Memory.Address`,
        /// [MEM-OWN-015]/[MEM-SAFE-029]) and reinterprets it as `Char`. Sound: `Char` is
        /// `BitwiseCopyable` and the region is `Char`-sized / `Char`-aligned by construction.
        @unsafe
        @inlinable
        package var _base: UnsafePointer<Char> {
            // SAFETY: reinterprets the REAL origin pointer (intact provenance) as `Char`; the region
            // SAFETY: was allocated `Char`-sized/aligned, so the bound is valid. No `Memory.Address`
            // SAFETY: round-trip ([MEM-OWN-015]/[MEM-SAFE-029]). Lifetime tied to `self` via `_storage`.
            unsafe UnsafePointer(_storage.unsafeBaseAddress.assumingMemoryBound(to: Char.self))
        }

        /// The length of the path in code units, excluding the null terminator.
        ///
        /// O(1) complexity.
        @inlinable
        public var count: Int {
            let byteCapacity = Int(bitPattern: _storage.capacity)
            return byteCapacity / MemoryLayout<Char>.stride
        }

        /// Returns a `Span` view of the path content, excluding the null terminator.
        ///
        /// Matches the SE-0456 convention for "semantic content" — the meaningful
        /// bytes that are not storage framing. For the raw-storage view including
        /// the NUL terminator (used by `char*`-style syscall hand-off), see the
        /// L3 `Paths.Path.bytes` property.
        ///
        /// O(1) complexity. The span's lifetime is tied to this path.
        @inlinable
        public var content: Swift.Span<Char> {
            @_lifetime(borrow self) borrowing get {
                let s = unsafe Swift.Span(_unsafeStart: _base, count: count)
                return unsafe _overrideLifetime(s, borrowing: self)
            }
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
            // `Memory.Heap.take()` hands back the REAL origin pointer + byte capacity and suppresses
            // its free; reinterpret the raw base as `Char` (provenance intact — no `Memory.Address`
            // round-trip, [MEM-OWN-015]/[MEM-SAFE-029]) and recover the length from the byte capacity.
            let (raw, byteCapacity) = unsafe _storage.take()
            let count = Int(bitPattern: byteCapacity)
            return unsafe (
                raw.assumingMemoryBound(to: Char.self),
                count / MemoryLayout<Char>.stride
            )
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
