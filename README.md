# 📚 EPUB Reader App

A cross-platform mobile app built with Flutter that lets users read EPUB books and sync their reading progress across devices using Firebase.

## ✨ Features

- 📖 Read EPUB files with a clean, swipeable interface
- 🔁 Sync reading location (EPUB CFI) using Firebase Firestore
- 🔐 Anonymous Firebase Auth for cross-device sync
- ⚙️ Compatible with Android and iOS

## 🚀 Tech Stack

- **Flutter** (Dart)
- **Firebase** (Auth + Firestore)
- **epub_view** for rendering EPUB content

## 📦 Setup

### Prerequisites

- Flutter SDK
- Firebase project (see instructions below)
- Android Studio or Xcode for emulators/devices

### 1. Clone the repo

```bash
git clone https://github.com/wikim00/epub-reader-app.git
cd epub-reader-app
flutter pub get
