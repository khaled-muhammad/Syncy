# 🎬 Syncy

### *Real-Time Cross-Platform Media Sync & Watch Party App*

<div align="center">
  <img src="landing_website/public/logo.png" alt="Syncy Logo" width="200"/>

  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-34A853?style=flat-square)
</div>

**Syncy lets you watch videos with friends in real-time, using any video file on your device.**

---

## ✨ Features

| | |
|-|-|
| **📱 Media Discovery** | Automatic device scanning, thumbnail generation, smart search |
| **⚡ Real-time Sync** | WebSocket-powered playback with sub-second latency |
| **🎨 Modern UI** | Glassmorphic design, dark theme, gesture navigation |
| **🔍 Smart Search** | Fuzzy matching handles typos, relevance scoring, multi-term ranking |

<div align="center">
  <img src="landing_website/public/hero_ui.jpg" alt="Syncy UI" width="80%"/>
</div>

---

## 🛠️ Quick Start

```bash
# Clone and run
git clone https://github.com/khaled-muhammad/Syncy.git
cd Syncy
flutter pub get
dart run realm generate
flutter run
```

### Requirements
- Flutter 3.8+
- Android SDK 21+ / iOS 12+

---

## 📂 Project Structure

```
lib/
├── controllers/     # GetX state management
├── screens/         # UI screens
├── widgets/         # Reusable components
├── models/          # Realm database models
├── services/        # WebSocket, thumbnail generation
├── utils/           # Helpers, search algorithm
└── main.dart
```

---

## 🎯 Core Architecture

| Component | Tech | Purpose |
|-----------|------|---------|
| State | GetX | Reactive controllers |
| Local DB | Realm | Fast, embedded database |
| Sync | WebSocket | Real-time coordination |
| Search | Custom | Fuzzy matching + scoring |
| Thumbnails | Isolates | Background processing |

---

## 🚦 Current Status

✅ **Working:**
- Media scanning & metadata extraction
- Thumbnail generation (isolate-based)
- Smart search with fuzzy matching
- Material You theming
- Basic WebSocket sync

⚠️ **In Progress:**
- iOS permission handling
- Large file optimization

---

## 📱 Demo

<div align="center">
  <video src="landing_website/public/example.mp4" width="80%" controls>
    Your browser does not support the video tag.
  </video>
</div>

---

## 🤝 Contribute

1. Fork it
2. Create feature branch: `git checkout -b feature/name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push: `git push origin feature/name`
5. Open a PR

---

## 📄 License

MIT © [Khaled Muhammad](https://github.com/khaled-muhammad)

---

<div align="center">
  <sub>Built by a 17-year-old developer · ⭐ if you like it!</sub>
</div>