#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    public import Tagged_Primitives
    public import String_Primitives

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {

        public typealias ConversionError = Path.ConversionError

        public typealias String = Path.String

        public typealias Resolution = Path.Resolution

        public typealias Canonical = Path.Canonical
    }

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {

        @inlinable
        public static var scope: Path.String.Scope { Path.String.Scope() }
    }

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {

        @inlinable
        public init(adopting pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
            unsafe self.init(_unchecked: Path(adopting: pointer, count: count))
        }

        @inlinable
        public init(copying view: borrowing String_Primitives.String.Borrowed) {
            self.init(_unchecked: Path(copying: view))
        }

        @inlinable
        public init(_ span: Swift.Span<Path.Char>) {
            self.init(_unchecked: Path(span))
        }
    }

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {

        @inlinable
        public var count: Int { underlying.count }

    }

    extension Tagged where Underlying == Path, Tag: ~Copyable & ~Escapable {

        @unsafe
        @inlinable
        public consuming func take() -> (pointer: UnsafeMutablePointer<Path.Char>, count: Int) {
            unsafe self.map { (p: consuming Path) in unsafe p.take() }.underlying
        }
    }

#endif
