# ប្រព័ន្ធដឹកជញ្ជូនកសិកម្ម — Flutter App

A Khmer-language agricultural logistics Android app converted from a Figma AI design.

---

## 📁 Project Structure

```
agri_logistics/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── theme/
│   │   └── app_theme.dart             # Colors, text styles, ThemeData
│   ├── models/
│   │   ├── scheduled_job.dart         # ScheduledJob model + JobStatus enum
│   │   └── backhaul_load.dart         # BackhaulLoad model
│   ├── providers/
│   │   └── app_provider.dart          # ChangeNotifier (state management)
│   ├── screens/
│   │   ├── home_screen.dart           # Main dashboard
│   │   ├── job_detail_screen.dart     # Scheduled job detail
│   │   ├── load_detail_screen.dart    # Backhaul load detail + accept
│   │   ├── all_jobs_screen.dart       # All backhaul jobs + search
│   │   ├── notifications_screen.dart  # Notification list
│   │   └── drawer_menu.dart           # Side navigation drawer
│   └── widgets/
│       ├── android_status_bar.dart    # Simulated Android status bar
│       ├── android_nav_bar.dart       # Simulated Android 3-button nav bar
│       ├── job_card.dart              # Scheduled job card
│       ├── backhaul_card.dart         # Backhaul load card
│       └── section_header.dart        # Reusable section header
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 🛠️ Prerequisites (Windows + VS Code)

1. **Flutter SDK** — Download from https://flutter.dev/docs/get-started/install/windows  
   Add `C:\flutter\bin` to your `PATH`.

2. **Android Studio** (for Android emulator + SDK):  
   https://developer.android.com/studio  
   During install, select "Android SDK", "Android Virtual Device".

3. **VS Code Extensions**:
   - Flutter (by Dart Code)
   - Dart (by Dart Code)

4. **Verify setup** — run in a terminal:
   ```
   flutter doctor
   ```
   All items should show ✓ (green checkmarks).

---

## 🚀 Running the App

### Step 1 — Create the Flutter project shell

Open a terminal in VS Code (`Ctrl+\``) and run:

```powershell
flutter create agri_logistics
cd agri_logistics
```

### Step 2 — Replace generated files with the project files

Copy the entire `lib/` folder and `pubspec.yaml` from this bundle into `agri_logistics/`.

### Step 3 — Install dependencies

```powershell
flutter pub get
```

### Step 4 — Start an emulator

In Android Studio: **Tools → Device Manager → Create Device → Pixel 6 / API 34**.  
Or connect a real Android device with USB debugging enabled.

Check connected devices:
```powershell
flutter devices
```

### Step 5 — Run

```powershell
flutter run
```

For a specific device:
```powershell
flutter run -d emulator-5554
```

### Step 6 — Hot reload during development

While the app is running, press **`r`** in the terminal for hot reload, **`R`** for full restart.

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `provider ^6.1.2` | State management (ChangeNotifier) |
| `google_fonts ^6.2.1` | Noto Sans Khmer font (auto-downloads) |
| `flutter_svg ^2.0.10+1` | SVG asset rendering |
| `intl ^0.19.0` | Date/number formatting |

---

## 🎨 Design Notes / Assumptions

1. **Font** — `Noto Sans Khmer` loaded via `google_fonts` (requires internet on first run). For offline use, download the font files, add to `assets/fonts/`, and configure in `pubspec.yaml` (commented template provided).

2. **Khmer numerals** — All numbers in the design use Khmer digits (០–៩). These are hardcoded in the sample data; a real app would format them dynamically.

3. **Android chrome** — A simulated Android status bar (black, 08:20, battery/signal icons) and 3-button nav bar are included as Flutter widgets, matching the Figma design exactly. In a production app you'd use `SystemChrome` + `EdgeInsets` to handle real system insets.

4. **Screens not in design** — The following screens were inferred and created to make all buttons functional:
   - Job Detail screen (tap a schedule card)
   - Load Detail screen (tap "ពិនិត្យមើល")
   - All Jobs screen (tap "មើលការងារទាំងអស់") — includes search
   - Notifications screen (tap bell icon)
   - Side Drawer (tap hamburger menu)

5. **State management** — `Provider` / `ChangeNotifier` is used. Data is currently in-memory; connect to a REST API by replacing the mock data in `AppProvider`.

6. **Pull-to-refresh** — The home screen supports pull-to-refresh (simulates 800ms network call).

7. **Responsiveness** — Layouts use `Expanded`, `Flexible`, and relative sizing. Tested on Pixel 4 (5.7"), Pixel 6 (6.4"), and Pixel Tablet.

---

## 🏗️ Building APK

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`
"# Mobile_App" 
