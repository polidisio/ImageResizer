# Code Review Report: ImageResizer (QIResizer)

**Date:** 2026-05-22  
**Review Method:** Automated Claude Code analysis  
**Repository:** polidisio/ImageResizer  
**Branch:** code-review/ImageResizer-20260522

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH | 2 |
| MEDIUM | 3 |
| MINOR | 3 |

---

## CRITICAL Issues

### 1. File Overwriting in Batch Processing
- **File:** `Sources/Models/ImageResizer.swift:207-212`
- **Description:** When `customFileName` is provided, the same filename is used for ALL images in a batch, causing each subsequent image to overwrite the previous one. This causes permanent data loss.
- **Fix:** Append a unique identifier (index or UUID) when `customFileName` is set in batch mode:

```swift
if let custom = customFileName, !custom.isEmpty {
    let index = urls.firstIndex(of: url) ?? 0
    baseName = "\(custom)_\(index)"
}
```

---

## HIGH Issues

### 2. Deprecated lockFocus/unlockFocus API
- **File:** `Sources/Models/ImageResizer.swift:121-123`
- **Description:** `NSImage.lockFocus()` and `unlockFocus()` are deprecated. They don't properly support HiDPI (Retina) displays and can cause rendering issues on modern Apple hardware.
- **Fix:** Use `NSImage.draw(where:byScalingWholeScreen:)` or Core Graphics-based resizing instead.

### 3. No Input Validation for Custom Width
- **File:** `Sources/Views/ContentView.swift:420`
- **Description:** `Double(customWidth) ?? 1080` silently defaults to 1080 for any invalid input (letters, negative numbers, extremely large values). User receives no feedback.
- **Fix:** Validate input and show user feedback:

```swift
guard let w = Double(customWidth), w > 0, w <= 10000 else {
    // Show error message to user
    return
}
```

---

## MEDIUM Issues

### 4. No Cancellation Support
- **File:** `Sources/Models/ImageResizer.swift`
- **Description:** Once processing starts, it cannot be cancelled. Closing the window mid-processing leaves work running.
- **Fix:** Add a `@Published var shouldCancel: Bool` and check it between image processing iterations.

### 5. HEIC Encoding Quality Not Applied (PNG)
- **File:** `Sources/Models/ImageResizer.swift:130-132`
- **Description:** `compressionFactor` is passed for PNG/JPEG but not applied to PNG (lossless format ignores this parameter).
- **Fix:** Remove `.compressionFactor` for PNG since it's ignored for lossless formats.

### 6. Memory Pressure with Large Batches
- **File:** `Sources/Models/ImageResizer.swift:73-91`
- **Description:** All images processed sequentially in a tight loop without memory management. Very large batches could cause memory pressure.
- **Fix:** Consider wrapping in `autoreleasepool` or processing in smaller batches.

---

## MINOR Suggestions

### 7. Deprecated DispatchQueue API
- **File:** `Sources/Views/ContentView.swift:206`
- **Description:** `DispatchQueue.main.asyncAfter` is deprecated in favor of Swift's `Task.sleep`.
- **Fix:** Use `Task { try? await Task.sleep(nanoseconds: 3_000_000_000) }` within async context.

### 8. Duplicate URLs Allowed in Browse Dialog
- **File:** `Sources/Views/ContentView.swift:395-398`
- **Description:** The browse dialog adds URLs without checking for duplicates (drag-drop correctly checks via `contains`).
- **Fix:** Add duplicate check in `selectFiles()` similar to drag-drop handling.

### 9. Missing Accessibility Labels
- **File:** `Sources/Views/ContentView.swift`
- **Description:** Several interactive elements lack accessibility labels for screen reader users.
- **Fix:** Add `.accessibilityLabel()` to buttons and controls.

---

## Positive Observations

- **QIResizerApp.swift:** Clean app entry point.
- **FileSize+Ext.swift:** Well-structured extension.
- **Entitlements:** Appropriate sandbox configuration.
- **ImageDropDelegate:** Properly handles drag-drop with animation states.
- No security vulnerabilities (XSS, injection, auth issues) found.
- External links use `rel="noopener noreferrer"` correctly.

---

## Priority Action

**Fix Issue #1 immediately** — the file overwriting bug causes permanent data loss in batch operations with custom filenames.