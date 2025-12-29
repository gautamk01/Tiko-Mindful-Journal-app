# 🧘 Tiko: Mindful Journal

**Tiko** is a beautiful, intelligent Flutter application designed to help you track your mental well-being, record daily thoughts, and visualize your emotional trends over time.

---

## ✨ Features

### 📊 Advanced Mood Tracking
- **Interactive Mood Timeline**: A horizontally scrollable, granular chart visualizing your mood changes throughout the day.
  - **Focused View**: Timeline restricts focus to active hours (6:00 AM - 10:00 PM) for better usability.
- **Daily Insights**: Automatic calculation of your "Overall Mood" for the day with emoji indicators (e.g., Happy 😊, Okay 😐).
- **Quick Logging**: Easy-to-use mood selector with 5 distinct emotional states.

### 🔔 Smart Native Notifications
- **Custom Android Experience**: Integrated native Android notifications that allow you to interact directly with the app.
- **Hourly Checks**: Gentle reminders to log your mood, helping you build a consistent tracking habit.
- **Actionable Alerts**: Tap notifications to jump straight into the mood logging flow.

### 📔 Rich Journaling
- **Staggered Animations**: Beautiful, smooth entrance animations for journal entries.
- **Time-Aware Prompts**: Smart greetings ("Good Morning", "Good Evening") with relevant reflection questions.
- **Multimedia Support**: Attach photos from your camera or gallery to your entries.
- **History View**: Browse through your past journal entries to reflect on your journey.

### 🎨 Modern UI/UX
- **Material Design**: Clean, minimalistic interface using Google Fonts (Poppins, Playfair Display).
- **Custom Branding**: Bespoke app icon and splash screen with breathing animations.
- **Responsive**: Adapts gracefully to different screen sizes.

---

## 🏗️ Architecture

Tiko follows a modular, service-oriented architecture to ensure scalability and maintainability.

### 1. Data Layer (Hive)
We use [Hive](https://docs.hivedb.dev/), a lightweight and fast key-value database, for local storage.
- **Boxes**: Data is organized into specific "boxes" (tables):
  - `hourly_moods`: Stores individual mood entries with precise timestamps.
  - `journal_entries`: Stores text and image paths for journal logs.
  - `user_data`: Stores preferences, profile images, and oneness state.
- **Adapters**: Custom TypeAdapters serialize complex Dart objects (`HourlyMood`, `JournalEntry`) for storage.

### 2. Service Layer
Business logic is encapsulated in singleton services:
- **`DatabaseService`**: Handles all Hive operations (CRUD), ensuring data consistency.
- **`NotificationService`**:
  - Bridges Flutter and Android Native code.
  - Manages scheduling of local notifications.
  - Handles notification tap callbacks.

### 3. Native Integration (Platform Channels)
To bypass Flutter's limitations with certain notification features, Tiko uses **Platform Channels** (`MethodChannel`) to communicate with native Android (Kotlin) code.
- **Flutter Side**: Sends requests to show custom notifications.
- **Android Side**:
  - `MainActivity.kt`: Intercepts channel calls.
  - `MoodNotificationReceiver.kt`: BroadcastReceiver that handles button clicks within notifications.
  - `CustomMoodNotification.kt`: Builds the custom `RemoteViews` for the notification UI.

### 4. Presentation Layer (UI)
- **Pages**: Distinct screens (`MoodChartPage`, `JournalPage`) that consume data from Services.
- **State Management**: Uses `setState` for local UI state and `ValueListenableBuilder` (from `hive_flutter`) for reactive data updates. When the database changes, the UI automatically rebuilds.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Database**: `hive` & `hive_flutter` (NoSQL, fast, offline-first).
- **Charting**: `fl_chart` for rendering high-performance interactive graphs.
- **Notifications**: `flutter_local_notifications` + Custom Kotlin Code.
- **Fonts**: `google_fonts` (Poppins, Playfair Display).
- **Icons**: `flutter_launcher_icons` for generating platform-specific assets.
- **Animations**: `TweenAnimationBuilder`, `FadeTransition`, `ScaleTransition`.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (SDK >= 3.10.4).
- Android Studio or VS Code configured for Flutter development.
- An Android Emulator or physical device.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/tiko-journal.git
    cd tiko-journal
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Adapters (if modifying models):**
    ```bash
    dart run build_runner build
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```
lib/
├── models/         # Data models (HourlyMood, JournalEntry, etc.)
├── pages/          # UI Screens (MoodChartPage, JournalPage, SplashScreen, etc.)
├── services/       # Business logic (DatabaseService, NotificationService)
├── widgets/        # Reusable UI components (MoodSelectorDialog, etc.)
└── main.dart       # Entry point and app configuration
android/            # Native Android code (Kotlin/XML) for notifications
```

---

## 🤝 Contributing

Contributions are welcome! If you have suggestions or find a bug, please create an issue or send a pull request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
