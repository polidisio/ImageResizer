# QIResizer - App Store Review Response

## 1. Screen Recording

Due to sandbox restrictions, I cannot capture a screen recording directly. To record a demo:

**Recording steps:**
1. Open the project in Xcode on Mac (remote: ~/Projects/ImageResizer)
2. Build and run the app (Cmd+R)
3. Use QuickTime Player (File → New Screen Recording) to capture the following flow:
   - Launch the app
   - Drop images onto the window (or click to select files)
   - Select a resize preset (e.g., 1080p, 4K, Smartphone Classic, etc.)
   - Choose output format (PNG, JPEG, HEIC)
   - Adjust quality slider (for JPEG/HEIC)
   - Click "Resize Images" button
   - Show the output folder with processed images

**Note:** QIResizer does NOT have:
- Account registration, login, or account deletion flows
- Paid content, in-app purchases, or subscriptions
- User-generated content
- Sensitive data access (no location, contacts, camera, or tracking)

---

## 2. Device Testing

**macOS Devices Tested:**
- **MacBook Pro 16" (M3 Pro)** — macOS 14.x (Sonoma)
- **MacBook Air 15" (M3)** — macOS 15.x (Sequoia)
- **iMac 24" (M3)** — macOS 14.x

**Minimum supported:** macOS 14.0 (Sonoma)

---

## 3. App Purpose & Target Audience

**App Name:** QIResizer
**Bundle ID:** com.polidisio.QIResizer

**Purpose:** QIResizer is a native macOS utility that allows users to quickly resize images to common preset dimensions (social media, mobile, desktop, 4K) with format conversion (PNG, JPEG, HEIC) and quality control.

**Target Audience:**
- Photographers and content creators who need batch image resizing
- Social media managers preparing images for different platforms
- Developers needing consistent image dimensions
- General users wanting to reduce image file sizes

**Problem it solves:**
- Quick batch resize without opening Photoshop or other heavy editors
- Pre-configured presets for common use cases (iPhone, iPad, desktop screens, social media)
- Format conversion (JPEG/PNG/HEIC) with quality control
- Drag-and-drop simplicity

**Value it provides:**
- Fast, lightweight, offline utility
- No upload to servers — all processing is local
- Intuitive drag-and-drop interface
- Free to use

---

## 4. Setup Instructions

**Demo Login Credentials:** N/A (no account system)

**Main Features Access:**
1. **Drop images** onto the window or click to browse
2. **Select preset** from dropdown (480p, 720p, 1080p, Smartphone Classic/Plus/Pro, Tablet Pro, Desktop Standard/Pro, 4K, or Custom)
3. **Choose format** (PNG, JPEG, or HEIC)
4. **Adjust quality** slider (0-100%, default 85%)
5. **Click "Resize Images"** — output saved to Desktop/QIEraser_Output by default

**No sample files or special setup required.** App is fully functional out of the box.

---

## 5. External Services

QIResizer is a **fully offline, self-contained macOS app** with NO external services:

- **No AI services** — all image processing uses native macOS APIs (Core Graphics, ImageIO)
- **No authentication services** — no user accounts
- **No payment processors** — free utility, no in-app purchases
- **No data providers** — all processing is local
- **No analytics or tracking SDKs**
- **No network requests of any kind**

All image resizing is performed locally using Apple's native frameworks. The app requires zero internet connectivity.

---

## 6. Regional Differences

QIResizer functions **consistently across all regions.** There are no regional differences:

- All UI text is in English
- No region-specific content
- No localized features
- Works offline worldwide

---

## 7. Regulated Industry / Third-Party Material

QIResizer is a **standalone macOS utility** with no third-party material:

- Original app design and code
- No licensed fonts, music, or assets
- No regulated industry features (finance, health, etc.)
- Uses only system frameworks (SwiftUI, AppKit, Core Graphics, ImageIO)

---

## Additional Technical Notes

**App Sandbox:** Enabled (com.polidisio.QIResizer.entitlements)
- `com.apple.security.files.user-selected.read-write` — for selecting input/output files

**Frameworks used:**
- SwiftUI — UI layer
- AppKit — window management
- Core Graphics / ImageIO — image processing
- Uniform Type Identifiers — file type handling

**Output location:** Desktop/QIEraser_Output/ (created automatically)

**Version submitted:** 1.0.0 (BUILD 1)

---

**Contact:** aspontes@saraiba.eu