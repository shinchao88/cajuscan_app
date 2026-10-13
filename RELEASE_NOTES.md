## 1.0.9

### ✨ What's new
- **Tax metadata:** Optionally include additional tax details in transaction notes sent to Cashew.
- **Transaction time editing:** Set the invoice time manually with a locale-aware time picker.
- **Timestamped exports:** Backup filenames now include a timestamp (`cajuscan-YYYY-MM-DD-HH-mm-ss.json`) to prevent overwriting older backups.
- **Support the project:** Added a Buy Me a Coffee button to the README.

### 🛠️ Fixes and improvements
- **Merchant matching:** Saving a merchant now validates by tax ID instead of merchant name.
- **Interface:** Adjusted bottom spacing on the confirmation page to align with the system navigation bar.
- **Refactoring:** Cleaned up invoice model properties and unified backup flows.

## 1.0.8

### ✨ What's new
- **Smart account suggestions:** Suggest a destination account using local history for each tax ID and overall account usage.
- **Redesigned confirmation screen:** Review and edit merchants, categories, and accounts using interactive cards.
- **Merchant search:** Search by merchant name, tax ID, or category.
- **Dedicated account management:** Manage destination accounts separately in Settings.
- **Cashew sharing:** Import account and category structures directly through Cashew's share sheet.

### 🛠️ Improvements
- Optimized merchant list filtering.
- Added `context.mounted` checks to asynchronous flows.
- Updated Settings icons and menus.

> **Release note:** Version 1.0.8 was a pre-release used for F-Droid integration testing. Its improvements and subsequent fixes were consolidated into version 1.0.9.

## 1.0.7

### ✨ What's new
- **Import categories from Cashew:** CajuScan appears in Cashew's share sheet, allowing categories to be imported directly.
- **Manual import:** Load a category export from a JSON or TXT file in Settings.
- **Import confirmation:** Review the number of categories found before replacing existing data.

## 1.0.6

### ✨ What's new
- **File import:** Scan invoice QR codes from PDF files or gallery images.
- **Scan flow setting:** Choose between continuous scanning and returning to the home screen after each scan.
- **Ergonomic home screen:** Moved action buttons to the lower half of the screen for easier one-handed use.

### 🛠️ Improvements
- Updated scanner navigation to respect the selected scan preference.
- Added asynchronous delays and validation to prevent duplicate scans and improve reliability in low light.

### 🔒 Security and privacy
- Removed diagnostic output and debug logs from production builds.
- Enabled "Confirm in Cashew" by default so users can review data before submitting it.

## 1.0.5

### Fixed
- **URL encoding:** Fixed encoded characters (such as `%20` and `%0A`) appearing in Cashew transaction notes and titles on Cashew 6.4.4 and later. #5 #6

## 1.0.4

This release completes the transition to a fully free and open-source architecture and removes remnants of proprietary libraries found in earlier builds.

### 🛡️ Open-source transition
- Replaced the proprietary `mobile_scanner` package with **`flutter_zxing`**, an open-source barcode and QR code scanner.
- Removed cached Play Core SDK components from the binary to meet FOSS requirements.

### ✨ Technical improvements
- Integrated `ReaderWidget` with custom painters to preserve the CajuScan scanner overlay.
- Enabled R8 code shrinking to remove unused code and reduce APK size.
- Updated the build engine to block non-free dependencies.
- Ensured the app includes no telemetry or Google Play services.
- Signed the official binary and improved CI for reproducible builds.

## 1.0.3

This release improves the project's autonomy and transparency, aligns it with free and open-source software (FOSS) principles, and prepares it for F-Droid.

### 🛡️ Open-source transition
- Removed `mobile_scanner`, which relied on proprietary Google ML Kit components.
- Added `flutter_zxing` (`^2.2.1`) for open-source barcode and QR code scanning.

### ✨ Technical improvements
- Integrated `ReaderWidget` with an optimized `onScan` callback.
- Preserved the custom scanner overlay with custom painters.
- Updated the build configuration to support independent reproducible-build verification.
- Configured R8/ProGuard without obfuscation so the binary can be matched to the source code.

## 1.0.2

- Replaced `mobile_scanner` (which depended on Google ML Kit) with `flutter_zxing`.
- Removed proprietary dependencies to make the project fully FOSS and compatible with F-Droid.
- Updated the UI with an inset-corner scanner frame and cutout.
- Improved performance with `RepaintBoundary`.
- Fixed flickering in the scan-line animation.
- Prepared the project for F-Droid.

## 1.0.1

### 🚀 What's new (2026-01-02)
- **Android 11+ compatibility:** Added package visibility (`<queries>`) so Cashew can be detected and opened on modern Android versions. https://github.com/marotoweb/cajuscan_app/issues/1

**Full changelog:** https://github.com/marotoweb/cajuscan_app/compare/v1.0.0...v1.0.1

## 1.0.0

### 🎉 Initial release

CajuScan is an Android app that simplifies and automates expense tracking in Portugal. Scan an invoice QR code and send the expense details to your preferred finance app, [Cashew](https://cashewapp.web.app/).

### ✨ Features
- **Fast QR scanning:** Instantly scan QR codes from Portuguese invoices.
- **Cashew integration:** Send invoice amount, date, and tax ID to Cashew using either direct entry (`/addTransaction`) or confirmation (`/addTransactionRoute`), configurable in Settings.
- **Merchant profiles:** Save merchant names and default categories/subcategories by tax ID.
- **Category management:** Create, edit, delete, and restore expense categories and subcategories.
- **Flexible workflow:** Save merchants from a QR code without creating a transaction, add merchants manually, or edit invoice details before sending them to Cashew.
- **Backup and restore:** Export and import merchant profiles and categories as a JSON file.

This is just the beginning! The future of CajuScan will be shaped by community feedback. If you find a problem or have a suggestion, please open an [issue](https://github.com/marotoweb/cajuscan_app/issues).

Thanks for trying CajuScan!
