# swift-path-primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Lifetime-safe owned and borrowed path types backed by null-terminated, platform-encoded storage, for converting Swift strings into buffers ready to hand to filesystem syscalls.

---

## Quick Start

```swift
import Path_Primitives

// Convert a Swift String into a scoped, null-terminated path view.
// `Path.Borrowed` is ~Escapable, so the pointer it wraps cannot outlive the
// closure — a use-after-free the compiler rejects rather than a runtime bug.
let owned: Path = try Path.scope("/tmp/report.txt") { view in
    // `view` is borrowed and cannot escape; copy its bytes to keep them.
    Path(view.span)
}

// `Path` is ~Copyable: a single owner that frees its heap buffer on
// destruction and can be moved across isolation boundaries.
print(owned.count)  // 15

// Reduce an arbitrary string to a filesystem-safe single path component.
let safe = Path.sanitized(from: "Q3 report (final).txt")
// "Q3_report__final_.txt"
```

---

## Key Features

- **Owned, lifetime-safe storage** — `Path` is `~Copyable` and owns a null-terminated `Memory.Heap` region that it frees on destruction; single-owner semantics rule out implicit duplication of a buffer destined for a syscall.
- **Non-escapable borrowed views** — `Path.Borrowed` is `~Escapable`, so a path pointer handed to a syscall cannot outlive the scope that produced it.
- **Scoped `String` conversion** — `Path.scope("/etc/hosts") { … }` converts a Swift `String` into a null-terminated platform buffer and rejects interior NUL bytes through typed throws (`Path.String.Conversion.Error`).
- **Platform-native encoding** — `Path.Char` is `UInt8` (UTF-8) on POSIX and `UInt16` (UTF-16) on Windows, keeping call sites correct across both string vocabularies.
- **argv / envp marshalling** — `Path.scope.array(["/bin/sh", "-c", "echo hi"]) { argv in … }` builds NULL-terminated platform string arrays for `exec*` and `posix_spawn`.
- **Deterministic sanitization** — `Path.sanitized(from:)` reduces an arbitrary string to a safe single path component, retaining only alphanumerics, `_`, `-`, and `.`.
- **Phantom-typed paths** — `Tagged<Tag, Path>` distinguishes path roles at compile time with no runtime cost, reusing the same owned storage.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-path-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Path Primitives", package: "swift-path-primitives")
    ]
)
```

Requires Swift 6.3.1.

---

## Architecture

Two library products.

| Product | When to import |
|---------|----------------|
| `Path Primitives` | The `Path` API — owned paths, borrowed views, scoped `String` conversion, and the `Path.Decomposition` / `Path.Modification` view protocols (conformed with separator logic by platform packages). |
| `Path Primitives Test Support` | Test targets that exercise `Path` values; re-exports the main target alongside the tagged-path test helpers. |

---

## Platform Support

`Path` types are available on the platforms covered by the package's availability guard: macOS, iOS, tvOS, watchOS, visionOS, Linux, Windows, Android, and OpenBSD. Windows uses wide (`UInt16` / UTF-16) path characters; the other platforms use narrow (`UInt8` / UTF-8) characters.

Apple-platform minimums are macOS 26, iOS 26, tvOS 26, watchOS 26, and visionOS 26.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
