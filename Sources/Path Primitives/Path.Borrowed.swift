#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    internal import String_Primitives
    public import Ownership_Primitives

    extension Path: Ownership.Borrow.`Protocol` {}

    extension Path {

        @safe
        public struct Borrowed: ~Copyable, ~Escapable {

            public let pointer: UnsafePointer<Char>

            public let count: Int

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

    #if DEBUG
        extension Path.Borrowed {

            @usableFromInline
            internal static let maxDebugScanLength = 16 * 1024 * 1024

            @unsafe
            @usableFromInline
            internal static func debugValidateTermination(_ pointer: UnsafePointer<Path.Char>) {
                var current = unsafe pointer
                var scanned = 0
                while scanned < maxDebugScanLength {
                    if unsafe current.pointee == 0 {
                        return
                    }
                    unsafe (current = current.successor())
                    scanned += 1
                }
                assertionFailure(
                    "Path.Borrowed: pointer does not appear to be null-terminated within \(maxDebugScanLength) code units"
                )
            }
        }
    #endif

    extension Path.Borrowed {

        @unsafe
        @inlinable
        public borrowing func withUnsafePointer<R: ~Copyable, E: Swift.Error>(
            _ body: (UnsafePointer<Path.Char>) throws(E) -> R
        ) throws(E) -> R {
            try unsafe body(pointer)
        }

        @inlinable
        public var span: Swift.Span<Path.Char> {
            @_lifetime(copy self) borrowing get {
                let span = unsafe Span(_unsafeStart: pointer, count: count)
                return unsafe _overrideLifetime(span, copying: self)
            }
        }
    }

    extension Path {

        @inlinable
        public var view: Borrowed {
            @_lifetime(borrow self) borrowing get {
                let view = unsafe Borrowed(_base, count: count)
                return unsafe _overrideLifetime(view, borrowing: self)
            }
        }
    }

#endif
