#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    extension Path {

        public protocol Modification: ~Copyable, ~Escapable {

            static func appending(_ view: borrowing Self, _ other: borrowing Self) -> Path
        }
    }

    extension Path.Modification where Self: ~Copyable, Self: ~Escapable {

        @inlinable
        public borrowing func appending(_ other: borrowing Self) -> Path {
            Self.appending(self, other)
        }
    }

#endif
