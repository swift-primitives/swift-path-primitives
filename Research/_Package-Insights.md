# swift-path-primitives Insights

<!--
---
title: swift-path-primitives Insights
version: 1.0.0
last_updated: 2026-04-01
applies_to: [swift-path-primitives]
normative: false
---
-->

Design decisions, implementation patterns, and lessons learned specific to this package.

## Overview

This document captures insights that emerged during development of swift-path-primitives.
These are not API requirements — they are recorded decisions and patterns that inform
future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[package: swift-path-primitives]`.

---

## Phase 4a: Decomposition Primitives (2026-03-31)

**Date**: 2026-03-31

**Context**: Path type compliance audit found 58 findings (10 HIGH) where `Swift.String` is used for paths because L1 lacks decomposition primitives (`parent`, `lastComponent`, `appending`). This forces higher layers to convert to String for path manipulation.

Implementation plan: add `parentBytes` (returns `Span<Char>?`, zero-alloc), `lastComponentBytes` (returns sub-view, shares null terminator), and `appending` to `Path.View`. Use the two validated experiments as reference implementations. Handle Windows edge cases using `Paths.Path.Navigation.swift` as oracle.

Critical design constraint: `parentBytes` MUST return `Span<Char>` (not `Path.View`) because the parent prefix is NOT null-terminated — the separator byte at the boundary is data, not `\0`. `lastComponent` IS safe as a `Path.View` because it shares the original null terminator.

**Applies to**: Path.View, all higher-layer path consumers (Paths.Path, Kernel.File.Write)
