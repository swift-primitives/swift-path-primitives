#if PATH_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

    extension Path.Resolution {

        public enum Error: Swift.Error, Sendable, Equatable, Hashable {

            case notFound

            case exists

            case isDirectory

            case notDirectory

            case notEmpty

            case loop

            case crossDevice

            case nameTooLong
        }
    }

    extension Path.Resolution.Error: CustomStringConvertible {

        public var description: Swift.String {
            switch self {
            case .notFound: return "not found"
            case .exists: return "already exists"
            case .isDirectory: return "is a directory"
            case .notDirectory: return "not a directory"
            case .notEmpty: return "directory not empty"
            case .loop: return "too many symbolic links"
            case .crossDevice: return "cross-device link"
            case .nameTooLong: return "name too long"
            }
        }
    }

#endif
