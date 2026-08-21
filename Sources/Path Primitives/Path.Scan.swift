#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    extension Path {

        public enum Scan {}
    }

    extension Path.Scan {

        @inlinable
        public static func lastSeparatorIndex(
            in bytes: Swift.Span<Path.Char>,
            primary: Path.Char,
            alt: Path.Char? = nil
        ) -> Int? {
            var i = bytes.count
            while i > 0 {
                i -= 1
                let b = bytes[i]
                if b == primary {
                    return i
                }
                if let alt, b == alt {
                    return i
                }
            }
            return nil
        }
    }

#endif
