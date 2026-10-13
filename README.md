[![GitHub Latest Release][releases_shield]][latest_release]
[![GitHub All Releases][downloads_total_shield]][releases]
<a href="https://www.buymeacoffee.com/marotoweb" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: 30px !important;width: 108px !important;" ></a>

[<img src="https://f-droid.org/badge/get-it-on.png"
    alt="Get it on F-Droid"
    height="80">](https://f-droid.org/en/packages/com.marotoweb.cajuscan_app)

[latest_release]: https://github.com/marotoweb/cajuscan/releases/latest
[releases_shield]: https://img.shields.io/github/release/marotoweb/cajuscan.svg?style=popout
[releases]: https://github.com/marotoweb/cajuscan/releases
[downloads_total_shield]: https://img.shields.io/github/downloads/marotoweb/cajuscan/total

<h1 align="center">
  <img src="assets/icon/icon.png" width="60" alt="CajuScan Icon">
  CajuScan
</h1>

**CajuScan** is a Flutter app for Android that simplifies expense tracking in Portugal. It scans the ATCUD QR code on Portuguese invoices, extracts the transaction details, and sends them to the [Cashew](https://cashewapp.web.app/) personal finance app.

> 💡 **What is Cashew?**
> [Cashew](https://github.com/jameskokoska/Cashew) is a privacy-focused personal finance app for managing budgets, accounts, and expenses locally. CajuScan helps Cashew users in Portugal by automating manual invoice entry.

The goal is to save time and reduce errors when entering everyday transactions.

---

## 📸 Screenshots

An overview of CajuScan's main features.

> **Note:** These screenshots show the previous Portuguese-language interface and have not yet been replaced with English screenshots.

<p align="center">
  <img src="screenshots/1.png" width="200" alt="Expense tracking">
  <img src="screenshots/2.png" width="200" alt="QR code scanning">
  <img src="screenshots/3.png" width="200" alt="Confirming an expense">
</p>
<p align="center">
  <img src="screenshots/4.png" width="200" alt="Destination account">
  <img src="screenshots/5.png" width="200" alt="Destination account">
  <img src="screenshots/6.png" width="200" alt="Settings">
</p>
<p align="center">
  <img src="screenshots/7.png" width="200" alt="Saved merchants">
  <img src="screenshots/8.png" width="200" alt="Managing categories">
  <img src="screenshots/9.png" width="200" alt="Editing a merchant">
</p>

---

## ✨ Funcionalidades principais

* **Invoice QR scanning:** Use your phone's camera to scan ATCUD QR codes on invoices issued in Portugal.
* **File import:** Scan QR codes directly from **PDF** files or **images** in your gallery, making it easy to record digital invoices received by email.
* **Cashew integration:** Send invoice details (amount, date, and merchant tax ID) to Cashew to prefill a transaction. Optionally include additional tax metadata in the notes.
* **Dynamic account suggestions:** An intelligent algorithm analyzes local history to suggest the most likely destination account. It first considers the account most often used for that merchant, then falls back to the most frequently used account overall.
* **Modern confirmation screen:** Review and edit invoice details using interactive cards. Tap the merchant to quickly edit its name, adjust the transaction date and time using the localized picker, and open integrated bottom sheets to select a category and account.
* **Merchant management:**
    * Automatically save each merchant's tax ID.
    * Associate a custom name (e.g. "Acme Market") and a default category/subcategory with each tax ID.
    * Suggest the saved name and category the next time an invoice from that merchant is scanned.
    * Search merchants instantly by name, tax ID, category, or subcategory.
* **Category and account management:**
    * Add, edit, or delete categories, subcategories, and destination accounts in dedicated settings pages.
    * Restore the default category list at any time.
    * Import categories and destination accounts from Cashew through the system share sheet, or manually from JSON/TXT files.
* **Flexible transaction workflow:**
    * Add transactions directly to Cashew without confirmation.
    * Open the transaction in Cashew to review it before saving.
    * Save a new merchant profile from a QR code without creating a transaction.
* **Backup and restore:** Export and import all app data (merchant profiles, categories, accounts, and account suggestion history) in a single `.json` file. Backups use timestamped filenames (`cajuscan-YYYY-MM-DD-HH-mm-ss.json`) to make device migration easier.
* **Intuitive interface:**
    * A camera scanner with a clear overlay to help align the QR code.
    * A clean design focused on ease of use.
* **Privacy and security:** Fully open-source (FOSS), with local offline processing and no telemetry or external servers. The app is digitally signed and prepared for reproducible builds.

---

## 🛠️ Tecnologias utilizadas

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** [Dart](https://dart.dev/)
*   **QR code scanning:** [flutter_zxing](https://pub.dev/packages/flutter_zxing)
*   **PDF processing:** [pdfx](https://pub.dev/packages/pdfx)
*   **Local storage:** [shared_preferences](https://pub.dev/packages/shared_preferences)
*   **App integration:** [url_launcher](https://pub.dev/packages/url_launcher)
*   **File selection:** [file_picker](https://pub.dev/packages/file_picker)
*   **App information:** [package_info_plus](https://pub.dev/packages/package_info_plus)
*   **Share intents:** [receive_sharing_intent](https://pub.dev/packages/receive_sharing_intent)
*   **Localization:** [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)

---

## ⚙️ GitHub Actions

GitHub Actions runs `flutter analyze`, `flutter test`, and a release APK build on every branch push and on pull requests targeting `main`. The APK is uploaded as a 14-day workflow artifact for testing.

Pushing a version tag such as `v1.0.10` also publishes a signed APK to a GitHub Release. Configure these repository Actions secrets before creating a release:

* `ANDROID_KEYSTORE_BASE64`
* `ANDROID_STORE_PASSWORD`
* `ANDROID_KEY_PASSWORD`
* `ANDROID_KEY_ALIAS`

The APK artifact produced by regular CI runs uses the debug signing key and is for testing only. Tagged releases require all four secrets and use the configured release keystore.

---

## 🚀 Build and install

To build the project, install and configure the [Flutter SDK](https://docs.flutter.dev/get-started/install).

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/marotoweb/cajuscan.git
    cd cajuscan
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

    3.  **Run in debug mode:**
    Connect an Android device or start an emulator, then run:
    ```sh
    flutter run
    ```

    4.  **Build a release APK:**
    Generate an optimized `.apk` ready to install:
    ```sh
    flutter build apk --release
    ```
    The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
    *Note: To produce a signed build identical to the official release, configure the Android keystore secrets used by GitHub Actions.*

---

## 📄 License and disclaimer

This project is distributed under the **MIT** license.

**CajuScan** is provided "AS IS", without warranties of any kind. The author is not responsible for malfunctions, data loss, or recording errors resulting from use of the app. Users are solely responsible for verifying that their data is accurate.

---
