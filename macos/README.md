# TypeMagic macOS Port — Technical Exploration & Plan

This document captures a deep analysis of the existing Chrome extension and outlines how we can port the experience to macOS. It also records the initial project skeleton (`macos/`), including shared assets copied from the extension (`macos/assets/icons/`).

The goal of the port is to deliver the same "select text → press Cmd+Option+T → AI-corrected text appears" workflow at the OS level, while preserving support for every AI provider already present in the browser version.

---

## 1. Current Chrome Extension: How It Works

| Layer | File(s) | Responsibilities | Key Details to Preserve |
| --- | --- | --- | --- |
| **Popup UI** | `popup.html`, `popup.js`, `styles.css` | Lets the user trigger corrections, pick tone, bulletize, summarize, or run Google Docs copy/paste workflow. | Calls `chrome.runtime.sendMessage` → `background.js` and mirrors status from `chrome.storage.sync`. |
| **Options UI** | `options.html`, `options.js` | Stores provider choice, API keys, models, markdown toggle, custom system prompt. | Uses `chrome.storage.sync` as the single config source.
| **Content Script** | `content.js` | Injects UX affordances, collects focused/selected text, runs notifications, handles keyboard shortcut, performs Google Docs-specific clipboard hacks. | Talks to background via `chrome.runtime.sendMessage` and writes text back into DOM nodes.
| **Background Service Worker** | `background.js` | Builds the prompt, picks an AI provider, executes HTTP request, returns corrected text. | Hosts all provider integrations (OpenAI, Gemini, Claude, FastAPI, Ollama) and prompt-building rules for tone/bullets/summaries.

**Data flow today:**

1. `content.js` (or `popup.js`) sends `{ action: 'correctText', text, tone, bulletize?, summarize? }` via `chrome.runtime.sendMessage`.
2. `background.js` loads settings from `chrome.storage.sync`, builds `prompt = { system, user }`, calls the selected provider with `fetch`, and returns `correctedText`.
3. `content.js` injects the corrected string back into the focused DOM node (or copies to clipboard for Google Docs) and shows notifications.

**Non-negotiable behaviors to reproduce on macOS:**

- Global shortcut (`Cmd+Option+T`) that either corrects selected text or falls back to the entire field.
- Tone modes (preserve voice, professional, casual) and quick actions (bulletize, summarize).
- Provider abstraction with pluggable credentials, Markdown toggle, and custom system prompt field.
- Privacy expectations: API keys stay local, no telemetry.

---

## 2. macOS Port Feasibility

| Capability | Feasibility Notes |
| --- | --- |
| **Global shortcut** | macOS offers `Event Monitor` / `MASShortcut` style global hotkeys. Works outside the sandbox but requires Accessibility permission to intercept keys while backgrounded. |
| **Read/replace text in any app** | Requires the Accessibility API (`AXUIElement`) to grab the focused UI element, read its value, and set a new string. Works for most `NSTextView`/`UITextInput`-backed fields; secure fields (password) and some Electron apps may block this. |
| **Clipboard round‑trip fallback** | We can emulate the Google Docs workflow system-wide by copying selection → call AI → replace clipboard → paste. This works everywhere, even when direct AX editing fails. |
| **Networking** | `URLSession` (Swift) or `fetch` (Electron/Tauri) can call the same HTTP endpoints already implemented. |
| **Config persistence** | Use `UserDefaults` (non-sensitive) + Keychain (API keys). Mirrors `chrome.storage.sync` schema. |
| **UI** | Native SwiftUI menu bar or floating window is practical; Tauri/Electron is also possible but brings larger footprint. |

Conclusion: The port is **very possible**. The main engineering surface is Accessibility-based text extraction/replacement and replicating the provider abstraction outside of the Chrome background worker.

---

## 3. Architecture Decision — Option A Locked In

We are moving forward with **Option A (Native SwiftUI menu bar app)**. The new Swift Package (see `macos/Package.swift`) already boots a native status-item application (backed by `NSStatusItem` so it always appears in the menu bar, even on macOS 15+) with the following components:

| Layer | Swift Types | Notes |
| --- | --- | --- |
| Menu bar UI | `TypeMagicMacApp`, `ControlPanelView`, `SettingsView`, `AppViewModel` | Recreates popup UX, exposes tone picker, markdown toggle, manual textarea, and quick actions. Settings sheet edits provider + credentials. |
| Core engine | `TypeMagicEngine`, `PromptBuilder`, `ProviderRouter` | Mirrors `background.js` logic, builds prompts, and calls OpenAI, Gemini, Claude, FastAPI, or Ollama through `URLSession`. |
| Settings & secrets | `SettingsStore`, `KeychainHelper` | Stores general prefs in `UserDefaults` and secrets in Keychain. |
| Accessibility & clipboard | `AccessibilityTextService`, `ClipboardManager` | Reads/writes focused text through AX APIs with clipboard fallback. |
| Input plumbing | `GlobalShortcutMonitor` | Registers Cmd+Option+T via `CGEventTap` and triggers corrections even when the menu is closed. |

### Why this option?

- **UX parity**: Menu bar popover maps directly to the Chrome popup and supports quick actions plus manual workflows.
- **Performance**: Native SwiftUI keeps memory footprint low and gives us first-class system integrations (Keychain, Accessibility, notifications).
- **Extensibility**: The Swift Package structure lets us share code across future targets (e.g., a helper service or a Catalyst build) without duplicating provider logic.

---

## 4. Functional Parity Mapping

| Chrome Feature | macOS Equivalent | Notes |
| --- | --- | --- |
| Popup quick actions | Menu bar popover with tone buttons + bulletize/summarize toggles | Reuse CSS/layout as reference or embed via WebView. |
| Keyboard shortcut | Global hotkey (Cmd+Option+T) | Provide Settings UI to customize + instructions for permissions. |
| Text replacement inside web editors | Accessibility API to pull `AXSelectedText` or entire `AXValue`, then `AXValue` set or clipboard fallback. |
| Google Docs workaround | System-wide clipboard workflow | Let the user copy text, then TypeMagic transforms clipboard and notifies them to paste. |
| Provider settings | Native Preferences window (SwiftUI `Form`) storing data in Keychain/UserDefaults | Keep schema identical to `chrome.storage.sync` for easier migration/export. |
| Notifications | `NSUserNotificationCenter` replacement: `UserNotifications` toast or in-app HUD | Ensure no blocking modals. |

---

## 5. Shared Code & Asset Strategy

- **Prompt + provider logic**: Extract the `buildPrompt` function and provider clients from `background.js` into a shared JS module (or port to Swift). Doing so will allow both the extension and macOS app to stay in sync. (Next step: create `shared/promptBuilder.js` and load it from both environments.)
- **Assets**: `macos/assets/icons/` now contains copies of the extension icons so the macOS app can reuse branding.
- **Settings schema**: Keep keys identical (`provider`, `openaiModel`, etc.) to simplify migrations.

---

## 6. Delivery Roadmap (Active)

1. ✅ **Bootstrap Swift core** — Swift Package (`TypeMagicKit`) created with a SwiftUI popover hosted inside an `NSStatusItem`, PromptBuilder parity, ProviderRouter, Accessibility services, Keychain-backed settings, and global shortcut monitor.
2. ⏳ **Deep integration testing** — exercise the Accessibility pipeline across popular apps (Mail, Notes, Pages, Slack, Chrome, Notion) to validate selection reads/writes and clipboard fallback messaging.
3. ⏳ **UI polish & notifications** — align the SwiftUI design with the Chrome popup styles (gradients, icons) and add native notifications for success/error states.
4. ⏳ **Feature parity gap list** — port Google Docs-specific instructions, tone quick actions, Markdown preview, and provider test button.
5. ⏳ **Packaging** — wrap the Swift Package in an Xcode workspace so it can be notarized and distributed via DMG/TestFlight, and wire up Sparkle or auto-update once build targets exist.
6. ⏳ **Automation & QA** — expand unit coverage (PromptBuilder already has an initial test) and add integration harnesses for provider stubs.

---

## 7. Xcode Project Integration (Current State)

- **Project location**: `typemagic/typemagic.xcodeproj`
- **Dependency graph**: the project consumes the local Swift package `../macos` as `TypeMagicKit`. All core logic, UI, and provider networking live in that package. The app target is now a thin SwiftUI `App` that delegates to `TypeMagicAppCoordinator`, which creates a native `NSStatusItem` (always visible wand icon) hosting the SwiftUI popover.
- **Toolchain requirement**: both the Swift package and the Xcode target are set to **Swift 5.8 / Xcode 14.3+**. Earlier toolchains cannot resolve the manifest. If you open the project in a newer Xcode (15.x/16.x) it will still compile because Swift is backwards compatible.
- **Resolving the package**: after opening the project, choose **File ▸ Packages ▸ Reset Package Caches** (or “Resolve Package Versions”) if Xcode shows “Package resolution errors”. Because the dependency is local (`../macos`), it resolves instantly once caches are cleared.
- **Resolving the package**: after opening the project, choose **File ▸ Packages ▸ Reset Package Caches** (or “Resolve Package Versions”) if Xcode shows “Package resolution errors”. Because the dependency is local (`../macos`), it resolves instantly once caches are cleared. Xcode generates its own `Package.resolved` file inside the workspace; we intentionally do **not** commit one so the local filesystem path can vary per developer.
- **Entitlements**: the project now ships with App Sandbox enabled (`com.apple.security.app-sandbox=true`) plus outbound network access (`com.apple.security.network.client=true`). If you maintain a separate unsigned/dev build without sandboxing, create a secondary entitlements file and switch the build setting per configuration.
- **Info.plist values**: added `LSUIElement=YES` to hide the dock icon and `NSAppleEventsUsageDescription` to explain why the app controls other apps.
- **Signing**: the project file keeps the provided Development Team ID; update it if you use a different account before archiving.

---

## 7. Next Steps in This Repo

1. Confirm whether we want Option A (native SwiftUI) or Option C (Tauri/Electron). The copied assets + this plan work for both.
2. Begin extracting shared logic from `background.js` so that we can compile it into whichever runtime we choose.
3. Stand up the Swift project (or Tauri app) under `macos/` and start wiring the provider HTTP clients using the prompt spec above.

---

*Prepared for the TypeMagic macOS initiative – this document should evolve as soon as the selected architecture is locked in.*
