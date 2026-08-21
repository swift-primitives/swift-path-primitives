#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    extension Path {

        public protocol Decomposition: ~Copyable, ~Escapable {

            associatedtype Char

            @_lifetime(copy view)
            static func parent(of view: borrowing Self) -> Swift.Span<Char>?

            @_lifetime(copy view)
            static func component(of view: borrowing Self) -> Swift.Span<Char>
        }
    }

    extension Path.Decomposition where Self: ~Copyable, Self: ~Escapable {

        @inlinable
        public var parent: Swift.Span<Char>? {
            @_lifetime(copy self)
            borrowing get { Self.parent(of: self) }
        }

        @inlinable
        public var component: Swift.Span<Char> {
            @_lifetime(copy self)
            borrowing get { Self.component(of: self) }
        }
    }

#endif
