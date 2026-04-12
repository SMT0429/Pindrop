---
name: Pindrop Architecture Overview
description: Key architectural facts about Pindrop's module structure, DI patterns, and testability constraints
type: project
---

Pindrop has no existing test target or test files (as of 2026-04-12). Test target was created via project.yml (xcodegen).

**Why:** First test infrastructure setup for the project.

**How to apply:**
- LocalParser, MapsService are pure functions -- easy to test directly.
- GroqService, PlacesService, OGMetadataService use URLSession.shared directly with no DI -- parsing logic must be replicated in test helpers or refactored to use protocol injection.
- Config.swift calls fatalError() for missing API keys, must be excluded from test compilation.
- ShareViewModel depends on SwiftData ModelContainer and UserDefaults with app group, hard to unit test without mocking.
- ParsedRestaurant struct is defined in GroqService.swift, not in a separate model file.
- project.yml uses xcodegen to generate Pindrop.xcodeproj.
- No Xcode.app installed on this machine (only CommandLineTools), so xcodebuild won't run.
