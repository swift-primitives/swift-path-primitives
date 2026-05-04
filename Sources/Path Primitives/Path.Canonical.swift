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

    extension Path {
        /// Path canonicalization operations.
        ///
        /// Provides the ability to resolve a path to its canonical form
        /// (resolving symlinks, removing `.` and `..` components).
        ///
        /// ## Platform Implementation
        ///
        /// Syscall implementations are in platform-specific packages:
        /// - POSIX: `swift-iso-9945` (`ISO_9945.Kernel.Path.Canonical`)
        /// - Windows: `swift-windows-primitives` (`Windows.Kernel.Path.Canonical`)
        public enum Canonical {}
    }

#endif
