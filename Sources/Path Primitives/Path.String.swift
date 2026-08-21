#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    extension Path {

        public enum String {}
    }

    extension Path.String {

        public enum Conversion {}
    }

    extension Path.String {

        public enum Error<Body: Swift.Error>: Swift.Error {

            case conversion(Conversion.Error)

            case body(Body)
        }
    }

    extension Path.String.Conversion {

        public enum Error: Swift.Error, Sendable, Equatable {

            case interiorNUL(index: Int)
        }
    }

    extension Path.String.Error: Sendable where Body: Sendable {}

    extension Path.String.Error: Equatable where Body: Equatable {}

    extension Path.String.Error {

        @inlinable
        public var body: Body? {
            if case .body(let e) = self { return e }
            return nil
        }

        @inlinable
        public var conversion: Path.String.Conversion.Error? {
            if case .conversion(let e) = self { return e }
            return nil
        }

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

    extension Path {

        @inlinable
        public static var scope: String.Scope { String.Scope() }
    }

    extension Path.String {

        public struct Scope {

            @inlinable
            public init() {}
        }
    }

    extension Path.String.Scope {

        @_disfavoredOverload
        @inlinable
        public func callAsFunction<S: StringProtocol, E: Swift.Error, R: ~Copyable>(
            _ string: S,
            _ body: (borrowing Path.Borrowed) throws(E) -> R
        ) throws(Path.String.Error<E>) -> R {
            var count = 0
            let buffer: UnsafeMutablePointer<Path.Char>
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer = _allocateBuffer(string, index: 0, count: &count))
            } catch {
                throw .conversion(error)
            }
            let path = unsafe Path(adopting: buffer, count: count)
            let view = path.view
            do throws(E) {
                return try body(view)
            } catch {
                throw .body(error)
            }
        }

        @inlinable
        public func callAsFunction<S: StringProtocol, NestedBody: Swift.Error, R: ~Copyable>(
            _ string: S,
            _ body: (borrowing Path.Borrowed) throws(Path.String.Error<NestedBody>) -> R
        ) throws(Path.String.Error<NestedBody>) -> R {
            var count = 0
            let buffer: UnsafeMutablePointer<Path.Char>
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer = _allocateBuffer(string, index: 0, count: &count))
            } catch {
                throw .conversion(error)
            }
            let path = unsafe Path(adopting: buffer, count: count)
            return try body(path.view)
        }

        @inlinable
        public func callAsFunction<S: StringProtocol, R: ~Copyable>(
            _ string: S,
            _ body: (borrowing Path.Borrowed) -> R
        ) throws(Path.String.Conversion.Error) -> R {
            var count = 0
            let buffer = try unsafe _allocateBuffer(string, index: 0, count: &count)
            let path = unsafe Path(adopting: buffer, count: count)
            return body(path.view)
        }
    }

    extension Path.String.Scope {

        @_disfavoredOverload
        @inlinable
        public func callAsFunction<
            S1: StringProtocol,
            S2: StringProtocol,
            E: Swift.Error,
            R: ~Copyable
        >(
            _ string1: S1,
            _ string2: S2,
            _ body: (borrowing Path.Borrowed, borrowing Path.Borrowed) throws(E) -> R
        ) throws(Path.String.Error<E>) -> R {
            var count1 = 0
            var count2 = 0
            let buffer1: UnsafeMutablePointer<Path.Char>
            let buffer2: UnsafeMutablePointer<Path.Char>
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer1 = _allocateBuffer(string1, index: 0, count: &count1))
            } catch {
                throw .conversion(error)
            }
            let path1 = unsafe Path(adopting: buffer1, count: count1)
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer2 = _allocateBuffer(string2, index: 1, count: &count2))
            } catch {
                throw .conversion(error)
            }
            let path2 = unsafe Path(adopting: buffer2, count: count2)
            let view1 = path1.view
            let view2 = path2.view
            do throws(E) {
                return try body(view1, view2)
            } catch {
                throw .body(error)
            }
        }

        @inlinable
        public func callAsFunction<S1: StringProtocol, S2: StringProtocol, R: ~Copyable>(
            _ string1: S1,
            _ string2: S2,
            _ body: (borrowing Path.Borrowed, borrowing Path.Borrowed) -> R
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

    extension Path.String.Scope {

        @_disfavoredOverload
        @inlinable
        public func callAsFunction<
            S1: StringProtocol,
            S2: StringProtocol,
            S3: StringProtocol,
            E: Swift.Error,
            R: ~Copyable
        >(
            _ string1: S1,
            _ string2: S2,
            _ string3: S3,
            _ body: (borrowing Path.Borrowed, borrowing Path.Borrowed, borrowing Path.Borrowed)
                throws(E) -> R
        ) throws(Path.String.Error<E>) -> R {
            var count1 = 0
            var count2 = 0
            var count3 = 0
            let buffer1: UnsafeMutablePointer<Path.Char>
            let buffer2: UnsafeMutablePointer<Path.Char>
            let buffer3: UnsafeMutablePointer<Path.Char>
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer1 = _allocateBuffer(string1, index: 0, count: &count1))
            } catch {
                throw .conversion(error)
            }
            let path1 = unsafe Path(adopting: buffer1, count: count1)
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer2 = _allocateBuffer(string2, index: 1, count: &count2))
            } catch {
                throw .conversion(error)
            }
            let path2 = unsafe Path(adopting: buffer2, count: count2)
            do throws(Path.String.Conversion.Error) {
                try unsafe (buffer3 = _allocateBuffer(string3, index: 2, count: &count3))
            } catch {
                throw .conversion(error)
            }
            let path3 = unsafe Path(adopting: buffer3, count: count3)
            let view1 = path1.view
            let view2 = path2.view
            let view3 = path3.view
            do throws(E) {
                return try body(view1, view2, view3)
            } catch {
                throw .body(error)
            }
        }

        @inlinable
        public func callAsFunction<
            S1: StringProtocol,
            S2: StringProtocol,
            S3: StringProtocol,
            R: ~Copyable
        >(
            _ string1: S1,
            _ string2: S2,
            _ string3: S3,
            _ body: (borrowing Path.Borrowed, borrowing Path.Borrowed, borrowing Path.Borrowed) -> R
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

    extension Path.String.Scope {

        @inlinable
        public var array: Array { Array() }
    }

    extension Path.String.Scope {

        public struct Array {

            @inlinable
            public init() {}
        }
    }

    extension Path.String.Scope.Array {

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
                do throws(Path.String.Conversion.Error) {
                    try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
                } catch {
                    throw .conversion(error)
                }
                unsafe buffers.append(buffer)
            }

            let pointerArray = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
                capacity: strings.count + 1
            )
            defer { unsafe pointerArray.deallocate() }

            for i in unsafe (0..<buffers.count) {
                unsafe (pointerArray[i] = UnsafePointer(buffers[i]))
            }
            unsafe pointerArray[strings.count] = nil

            do throws(E) {
                return try unsafe body(UnsafePointer(pointerArray))
            } catch {
                throw .body(error)
            }
        }

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
                do throws(Path.String.Conversion.Error) {
                    try unsafe (buffer = _allocateBuffer(string, index: index, count: &unusedCount))
                } catch {
                    throw .conversion(error)
                }
                unsafe buffers.append(buffer)
            }

            let pointerArray = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
                capacity: strings.count + 1
            )
            defer { unsafe pointerArray.deallocate() }

            for i in unsafe (0..<buffers.count) {
                unsafe (pointerArray[i] = UnsafePointer(buffers[i]))
            }
            unsafe pointerArray[strings.count] = nil

            return try unsafe body(UnsafePointer(pointerArray))
        }

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

            let pointerArray = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
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

    extension Path.String.Scope.Array {

        @_disfavoredOverload
        @inlinable
        @unsafe
        public func callAsFunction<
            S1: StringProtocol,
            S2: StringProtocol,
            E: Swift.Error,
            R: ~Copyable
        >(
            _ strings1: [S1],
            _ strings2: [S2],
            _ body: (
                UnsafePointer<UnsafePointer<Path.Char>?>, UnsafePointer<UnsafePointer<Path.Char>?>
            ) throws(E) -> R
        ) throws(Path.String.Error<E>) -> R {
            var buffers1: [UnsafeMutablePointer<Path.Char>] = unsafe []
            unsafe buffers1.reserveCapacity(strings1.count)
            defer { for i in unsafe (0..<buffers1.count) { unsafe buffers1[i].deallocate() } }

            var unusedCount = 0
            for (index, string) in strings1.enumerated() {
                let buffer: UnsafeMutablePointer<Path.Char>
                do throws(Path.String.Conversion.Error) {
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
                do throws(Path.String.Conversion.Error) {
                    try
                        unsafe (buffer = _allocateBuffer(
                            string,
                            index: strings1.count + index,
                            count: &unusedCount
                        ))
                } catch {
                    throw .conversion(error)
                }
                unsafe buffers2.append(buffer)
            }

            let pointerArray1 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
                capacity: strings1.count + 1
            )
            defer { unsafe pointerArray1.deallocate() }

            let pointerArray2 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
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

            do throws(E) {
                return try unsafe body(UnsafePointer(pointerArray1), UnsafePointer(pointerArray2))
            } catch {
                throw .body(error)
            }
        }

        @inlinable
        @unsafe
        public func callAsFunction<
            S1: StringProtocol,
            S2: StringProtocol,
            E: Swift.Error,
            R: ~Copyable
        >(
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
                do throws(Path.String.Conversion.Error) {
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
                do throws(Path.String.Conversion.Error) {
                    try
                        unsafe (buffer = _allocateBuffer(
                            string,
                            index: strings1.count + index,
                            count: &unusedCount
                        ))
                } catch {
                    throw .conversion(error)
                }
                unsafe buffers2.append(buffer)
            }

            let pointerArray1 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
                capacity: strings1.count + 1
            )
            defer { unsafe pointerArray1.deallocate() }

            let pointerArray2 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
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

        @inlinable
        @unsafe
        public func callAsFunction<S1: StringProtocol, S2: StringProtocol, R: ~Copyable>(
            _ strings1: [S1],
            _ strings2: [S2],
            _ body: (
                UnsafePointer<UnsafePointer<Path.Char>?>, UnsafePointer<UnsafePointer<Path.Char>?>
            ) -> R
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
                let buffer = try unsafe _allocateBuffer(
                    string,
                    index: strings1.count + index,
                    count: &unusedCount
                )
                unsafe buffers2.append(buffer)
            }

            let pointerArray1 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
                capacity: strings1.count + 1
            )
            defer { unsafe pointerArray1.deallocate() }

            let pointerArray2 = UnsafeMutablePointer<UnsafePointer<Path.Char>?>.allocate(
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

    @usableFromInline
    @unsafe
    internal func _allocateBuffer<S: StringProtocol>(
        _ string: S,
        index: Int,
        count: inout Int
    ) throws(Path.String.Conversion.Error) -> UnsafeMutablePointer<Path.Char> {
        let s = Swift.String(string)

        var measured = 0
        for scalar in s.unicodeScalars {
            guard let units = Path.Codec.encode(scalar) else { continue }
            for unit in units {
                if unit == 0 {
                    throw .interiorNUL(index: index)
                }
                measured += 1
            }
        }

        count = measured
        let bufferCapacity = measured + 1
        let buffer = UnsafeMutablePointer<Path.Char>.allocate(capacity: bufferCapacity)
        var i = 0
        for scalar in s.unicodeScalars {
            guard let units = Path.Codec.encode(scalar) else { continue }
            for unit in units {
                unsafe buffer[i] = unit
                i += 1
            }
        }
        unsafe buffer[i] = 0
        return unsafe buffer
    }

#endif
