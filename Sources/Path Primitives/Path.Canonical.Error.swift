#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    public import Error_Primitives

    extension Path.Canonical {

        public enum Error: Swift.Error, Sendable {

            case path(Path.Resolution.Error)

            case platform(Error_Primitives.Error)
        }
    }

    extension Path.Canonical.Error: Equatable {

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.path(let l), .path(let r)): return l == r
            case (.platform(let l), .platform(let r)): return l == r
            default: return false
            }
        }
    }

    extension Path.Canonical.Error: CustomStringConvertible {

        public var description: Swift.String {
            switch self {
            case .path(let e): return "path canonicalization: \(e)"
            case .platform(let e): return "path canonicalization: \(e)"
            }
        }
    }

#endif
