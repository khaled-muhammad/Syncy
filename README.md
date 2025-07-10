# 🎬 Syncy

### *The Ultimate Cross-Platform Media Sync & Watch Party App*

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Realm](https://img.shields.io/badge/Realm-39477F?style=for-the-badge&logo=realm&logoColor=white)
![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge&logo=socket.io&logoColor=white)

**Built with 💜 by a 17-year-old dev**

*Sync. Watch. Connect.*

</div>

---

## 🌟 What is Syncy?

Syncy is a **revolutionary media synchronization app** that lets you watch videos with friends in real-time, no matter where you are! Think Netflix Party but for **any video file** on your device. Built with Flutter for that buttery-smooth cross-platform experience.

### ✨ Key Features

🔥 **Smart Media Discovery**

- Automatically scans your device for videos
- Lightning-fast AI-powered search with fuzzy matching
- Beautiful thumbnail generation for all your content

🚀 **Real-Time Sync Technology**

- WebSocket-powered synchronization
- Perfect audio/video sync across devices
- Sub-second latency for the ultimate watch party experience

🎨 **Modern Glassmorphic UI**

- Stunning blur effects and modern animations
- Dark theme optimized for binge-watching
- Intuitive gesture-based navigation

🧠 **Intelligent Search Algorithm**

- Fuzzy matching handles typos like a pro
- Relevance scoring for perfect results
- Multi-term search with smart ranking

---

## 🛠️ Tech Stack

### Frontend Magic ✨

- **Flutter 3.8** - Cross-platform perfection
- **GetX** - State management that just works
- **Realm Database** - Local-first data persistence
- **Custom Animations** - Smooth as butter UI transitions

### Backend Power ⚡

- **WebSocket Connections** - Real-time magic
- **Dio HTTP Client** - Fast API communication
- **Video Processing** - Smart thumbnail generation
- **File System Integration** - Seamless media discovery

### Advanced Features 🔬

- **Isolate-based Processing** - Non-blocking thumbnail generation
- **Debounced Search** - Performance optimized
- **Smart Caching** - Lightning-fast media loading
- **Permission Management** - Secure file access

---

## 🚀 Getting Started

### Prerequisites

```bash
flutter doctor -v  # Ensure Flutter 3.8+ is installed
```

### Installation

```bash
# Clone this epic project
git clone https://github.com/khaled-muhammad/Syncy.git
cd Syncy

# Get those dependencies
flutter pub get

# Run code generation for Realm models
dart run realm generate

# Launch the app! 🚀
flutter run
```

### Platform Setup

#### Android 📱

- Min SDK: 21
- Target SDK: 34
- Permissions: Storage, Network

#### iOS 🍎

- iOS 12.0+
- Permissions: Photo Library, Network

---

## 🎯 Core Features Deep Dive

### 🔍 Smart Search Engine

Our custom-built search algorithm is **insanely powerful**:

```dart
// Fuzzy matching with Levenshtein distance
// Handles typos like "Spiderman" → "Spider-Man"
bool _fuzzyMatch(String text, String pattern) {
  // Magic happens here ✨
}

// Multi-factor relevance scoring
// Exact matches get 100 points, partial matches get weighted scores
double _calculateRelevanceScore(Media media, List<String> searchTerms) {
  // Smart ranking algorithm
}
```

### 🎬 Media Management

- **Automatic Discovery**: Scans your entire device intelligently
- **Smart Thumbnails**: Generated in background isolates
- **Format Support**: MP4, MOV, WebM, MKV, AVI
- **Metadata Extraction**: Duration, resolution, file info

### 🌐 Real-Time Synchronization

```dart
// WebSocket magic for perfect sync
wsService.setReceiveMsgFunction((msg) {
  if (msg.type == MessageType.pause) {
    videoController?.pause();
    videoController?.seekTo(Duration(seconds: msg.data['position']));
  }
});
```

---

## 📱 Screenshots

*Coming Soon - The UI is too beautiful to spoil the surprise!* 😉

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── 🎯 controllers/     # GetX controllers for state management
├── 📱 screens/         # All the beautiful UI screens  
├── 🧩 widgets/         # Reusable UI components
├── 🗄️ models/          # Realm database models
├── 🔧 services/        # Background services & APIs
├── 🛠️ utils/           # Helper functions & utilities
├── 🎨 theme/           # App theming & styles
└── 🚀 main.dart        # App entry point
```

### Key Components

- **HomeController**: Media discovery & management
- **RoomController**: Real-time sync coordination
- **ThumbnailService**: Background image processing
- **SearchScreen**: AI-powered media search
- **MediaCard**: Beautiful media display widgets

---

## 🤝 Contributing

We'd love your contributions! This project is built by young developers, for young developers.

### How to Contribute

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Add comments for complex algorithms
- Test on both Android and iOS
- Keep the UI beautiful and intuitive

---

## 📋 Roadmap

### 🔥 Coming Soon

- [ ]  iOS support completion
- [ ]  Group chat during watch parties
- [ ]  Screen sharing capabilities
- [ ]  Smart video recommendations
- [ ]  Cross-device media casting
- [ ]  Custom playlist creation

### 🌟 Future Dreams

- [ ]  AI-powered content discovery
- [ ]  Social media integration
- [ ]  Custom video filters
- [ ]  VR watch party support (because why not? 🤯)

---

## 🐛 Known Issues

- [X]  ~~Search performance with large libraries~~ ✅ *Fixed with debouncing*
- [X]  ~~Thumbnail generation blocking UI~~ ✅ *Fixed with isolates*
- [ ]  iOS permission handling needs refinement
- [ ]  Large video file support optimization

---

## 📚 Documentation

### API Reference

- [WebSocket Messages](docs/websocket-api.md)
- [Database Schema](docs/database-schema.md)
- [Search Algorithm](docs/search-algorithm.md)

### Tutorials

- [Setting up Development Environment](docs/setup.md)
- [Adding Custom Widgets](docs/widgets.md)
- [Implementing New Features](docs/features.md)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **GetX Community** - For the powerful state management
- **Realm** - For the seamless database solution
- **Open Source Community** - For all the amazing packages

---

## 📞 Contact & Support

### Got Questions? We've Got Answers!

- 📧 Email: [khaledmuhmmed99@gmail.com]
- 🐙 GitHub Issues: [Create an Issue](https://github.com/khaled-muhammad/Syncy/issues)
- 💬 Discussions: [Join the Conversation](https://github.com/khaled-muhammad/Syncy/discussions)

### Show Some Love ❤️

If you found this project awesome, don't forget to:

- ⭐ Star this repository
- 🍴 Fork it for your own experiments
- 🐛 Report bugs and suggest features
- 📢 Share it with your developer friends

---

<div align="center">

**Made with 💜 and lots of ☕ by a passionate 17-year-old developer**

*"Code is poetry, and every app tells a story"*

[![Built with Love](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com)
[![Made with Flutter](https://forthebadge.com/images/badges/made-with-flutter.svg)](https://forthebadge.com)

</div>
