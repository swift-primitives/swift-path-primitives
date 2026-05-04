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

    extension Path.Resolution {
        /// Path resolution errors.
        public enum Error: Swift.Error, Sendable, Equatable, Hashable {
            /// The specified path does not exist.
            /// - POSIX: `ENOENT`
            /// - Windows: `ERROR_FILE_NOT_FOUND`, `ERROR_PATH_NOT_FOUND`
            case notFound

            /// A file or directory already exists at the path.
            /// - POSIX: `EEXIST`
            /// - Windows: `ERROR_FILE_EXISTS`, `ERROR_ALREADY_EXISTS`
            case exists

            /// The path refers to a directory when a file was expected.
            /// - POSIX: `EISDIR`
            /// - Windows: `ERROR_DIRECTORY`
            case isDirectory

            /// A path component is not a directory.
            /// - POSIX: `ENOTDIR`
            /// - Windows: `ERROR_DIRECTORY_NOT_SUPPORTED`
            case notDirectory

            /// The directory is not empty.
            /// - POSIX: `ENOTEMPTY`
            /// - Windows: `ERROR_DIR_NOT_EMPTY`
            case notEmpty

            /// Too many symbolic links encountered.
            /// - POSIX: `ELOOP`
            case loop

            /// Cross-device link attempted.
            /// - POSIX: `EXDEV`
            /// - Windows: `ERROR_NOT_SAME_DEVICE`
            case crossDevice

            /// Path name too long.
            /// - POSIX: `ENAMETOOLONG`
            case nameTooLong
        }
    }

    // MARK: - CustomStringConvertible

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
