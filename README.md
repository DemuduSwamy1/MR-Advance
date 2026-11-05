# ReportKit

A Flutter app for a pharmacy wholesaler (RAVITEJA MEDICALS) with two tools:

- **Convert**: turns fixed-width legacy printer reports into clean, searchable PDFs.
- **Invoice**: creates GST tax invoices in the same layout as the printed bills.

Everything runs on the device; no files or invoice data leave the phone.
Platforms: Android (main target), web browsers, macOS and Windows.

## Convert tab

- **Pick a report** with *Select Report File*. Any file can be chosen, so reports without an extension work, as do `.txt`, `.dat`, `.prn`, `.lis` and `.out`.
- **Open from other apps.** In WhatsApp, Files or Gmail, use *Open with* or *Share* and choose ReportKit; the file loads straight into this tab.
- **Binary files are refused.** APKs, ZIP/Word/Excel files, PDFs, images, videos and archives are rejected with a message naming what the file looks like.
- **Conversion** decodes UTF-8 (falling back to Latin-1), removes printer-control sequences, and keeps fixed-width spacing, totals, page breaks and column alignment. Output is an A4 landscape PDF in a monospaced font.
- **Afterwards** you can preview, save, share or print the PDF. Any warnings (for example, unusually large files) are shown above the actions.

## Invoice tab

Creates a TAX INVOICE matching the RAVITEJA MEDICALS printed bill.

| Section | What you can edit |
| --- | --- |
| Bill details | Bill No (starts with `RS `), Date (date picker), Credit / Cash |
| From | Seller address and GSTIN. The name, PAN, phone numbers, drug licences and bank details are fixed. |
| Bill to | Customer name and two address lines, GSTIN; under *More customer details*: phone, PAN, DL 20B / 21B, party code, state |
| Items | One row per medicine, added or edited in a sheet |
| Message | Optional note printed on the bill |

### Adding a medicine

Enter the name, HSN code (defaults to `300490`), MFR, pack, batch, expiry (month/year picker), MRP, GST %, Qty and, optionally, the discount amount (₹, typed in; it is not calculated) and revised MRP. Two values are filled in for you:

- **Rate** = MRP ÷ (1 + GST%) less the retailer **margin** (20% by default).
  Example: 189.83 ÷ 1.05 × 0.80 = **144.63**.
- **Free** quantity from a **scheme** such as `10+1`: buying 130 gives 13 free.

You can type over either value; a ↻ button switches back to the calculation. A new item starts with the previous item's HSN code, GST % and margin.

### Calculations

All money is handled in whole paise, rounding halves up:

- Amount = Qty × Rate; Taxable = Amount − Discount (the discount entered for the item)
- CGST = SGST = Taxable × GST% ÷ 2 per line; invoice tax is totalled per GST slab (0, 5, 12, 18, 28%)
- Net amount = Taxable + CGST + SGST, rounded to the nearest rupee, with the round-off shown
- The amount in words uses Indian numbering (thousand, lakh, crore)

The totals card updates as items change. *Generate Invoice PDF* opens a preview to print or share (for example, to WhatsApp). *New invoice* clears the customer and items and moves the bill number on (RS 3387 → RS 3388).

Invoice data is not saved between app launches yet.

## Cloud saving (Firebase)

When Firebase is connected, the app saves to the cloud in the background, with no extra steps for the user:

- **Bills:** every time *Generate Invoice PDF* is pressed, the bill (customer, items, totals) is saved to the `bills` collection. Generating the same bill number again on the same day updates the saved copy instead of adding a duplicate.
- **Users:** each phone or browser signs in anonymously and gets its own `users/{id}` record with device details (maker, model, OS or browser, app version), first and last seen, and counts of sessions, bills and converted reports. No hardware IDs such as the IMEI are collected, and converted reports are only counted, never uploaded.
- **Sessions:** one `users/{id}/sessions` record each time the app is opened, or reopened after 30 minutes in the background. Firebase Analytics also reports users, sessions and devices on its dashboard (with up to a day's delay).

Offline, saves wait on the device and are sent when the connection returns. Until Firebase is connected (see below), `lib/firebase_options.dart` is a placeholder and the app works without cloud saving.

### Connecting the Firebase project

1. In the [Firebase console](https://console.firebase.google.com), open the project and turn on **Authentication → Sign-in method → Anonymous**, and create a **Firestore Database**.
2. Sign the Firebase CLI in to the Google account that owns the project:

   ```sh
   firebase login:add
   ```

3. Register the Android and web apps and write `lib/firebase_options.dart` (replace `PROJECT_ID` and `EMAIL`):

   ```sh
   ~/.pub-cache/bin/flutterfire configure --project=PROJECT_ID --account=EMAIL --platforms=android,web --android-package-name=com.coderswamy.reportkit
   ```

4. Publish the security rules in `firestore.rules`, which let each device add only its own data:

   ```sh
   firebase deploy --only firestore:rules --project PROJECT_ID --account EMAIL
   ```

5. Commit the generated `lib/firebase_options.dart` and `android/app/google-services.json` so the Vercel build uses them. Their keys identify the project and are not secret; the security rules protect the data.

Bills and users are read in the Firebase console under *Firestore Database*; user and session numbers are under *Analytics*.

## Project structure

```
lib/
  app/                    App shell: header, bottom navigation, theme
  core/
    cloud/                Firebase: saving bills, users and sessions; device details
    utils/                Number and amount formatting, amount in words, file checks
    widgets/              PDF preview, month/year picker, shared buttons
  features/
    converter/            Report reading, decoding, printer-control parsing, PDF output
    invoice/              Invoice model, GST calculator, invoice PDF, bill record, form and item sheet
test/                     Unit and widget tests (calculations, file checks, UI)
tool/make_app_icon.py     Generates the app icon and splash artwork
```

On Android, `MainActivity.kt` receives files from *Open with* / *Share* and passes them to Flutter over the `legacy_report_converter/incoming_file` method channel.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

### Building the Android APK

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. It is currently signed with the debug key: fine for installing directly, but Google Play needs a release signing key. The application ID is `com.coderswamy.reportkit`; builds made before it changed (`com.example.legacy_report_converter`) install as a separate app, so uninstall the old one.

### Web version

The same app runs in a browser. Opening files from WhatsApp is Android-only; on the web you pick the report with *Select Report File*. *Save PDF* downloads the file, and *Share PDF* opens the share sheet on phones (desktop browsers download it instead). Reports and invoices are processed in the browser and never uploaded.

Run it in Chrome while developing:

```sh
flutter run -d chrome
```

Build the site:

```sh
flutter build web --release
```

The site is written to `build/web`. Upload that folder to any static host (GitHub Pages, Firebase Hosting, Netlify, or a plain web server). If it is served from a sub-folder, such as `https://example.com/reportkit/`, build with `--base-href /reportkit/`. To try the build locally:

```sh
python3 -m http.server 8080 --directory build/web
```

Then open http://localhost:8080.

### App icon

The icon (a report sheet with a convert badge on teal) and the splash screen are generated from one script. After editing it, run:

```sh
python3 tool/make_app_icon.py .
```

It needs [Pillow](https://pypi.org/project/pillow/) and writes the Android adaptive and legacy icons, macOS and Windows icons, the web favicon and PWA icons, and the `assets/icon/` artwork.
