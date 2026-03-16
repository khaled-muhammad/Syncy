# 🎬 Syncy

### *Real-Time Cross-Platform Media Sync & Watch Party App*

<div align="center">
  <img src="landing_website/public/logo.png" alt="Syncy Logo" width="120"/>
  
  [![Website](https://img.shields.io/badge/website-synncy.netlify.app-blue?style=flat-square)](https://synncy.netlify.app/)
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
  ![Platform](https://img.shields.io/badge/Android%20%7C%20iOS-34A853?style=flat-square)
</div>

**Watch videos with friends in real-time using any video file on your device.**

---

<div align="center">
  <img src="landing_website/public/hero_ui.jpg" alt="Syncy UI" width="600"/>
</div>

---

## ✨ Features

| | |
|-|-|
| **📱 Media Discovery** | Automatic device scanning, thumbnail generation, smart search |
| **⚡ Real-time Sync** | WebSocket-powered playback with sub-second latency |
| **🎨 Modern UI** | Glassmorphic design, dark theme, gesture navigation |
| **🔍 Smart Search** | Fuzzy matching handles typos, relevance scoring |

---

## 🎥 Demo

<div align="center">
  <video src="landing_website/public/example.mp4" width="600" controls>
    Your browser does not support the video tag.
  </video>
</div>

---

## 🛠️ Quick Start

```bash
git clone https://github.com/khaled-muhammad/Syncy.git
cd Syncy
flutter pub get
dart run realm generate
flutter run
```

**Requirements:** Flutter 3.8+ | Android SDK 21+ | iOS 12+

---

## 📁 Structure

```
lib/
├── controllers/    # GetX state
├── screens/        # UI
├── widgets/        # Components
├── models/         # Realm DB
├── services/       # WebSocket, thumbnails
└── utils/          # Search, helpers
```

---

## 📊 Status

✅ Media scanning • Thumbnails • Smart search • WebSocket sync  
⚠️ iOS permissions • Large file optimization

---

## 🤝 Contribute

```bash
git checkout -b feature/name
git commit -m 'Add feature'
git push origin feature/name
# Open PR
```

---

<div align="center">
  <sub>
    <a href="https://synncy.netlify.app/">Website</a> • 
    <a href="https://github.com/khaled-muhammad/Syncy/issues">Issues</a> • 
    <a href="https://github.com/khaled-muhammad/Syncy/discussions">Discussions</a>
  </sub>
  <br/>
  <sub>Built by a 17-year-old dev · MIT © Khaled Muhammad</sub>
</div>